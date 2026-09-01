#!/usr/bin/env python3
"""
QuickShell Ballade - Streaming AI Query Engine
Streams tokens in real time for Google Gemini, OpenAI, Mistral, Grok, and Ollama.
Outputs JSON lines to stdout with immediate flushing.
"""

import sys
import json
import urllib.request
import urllib.error
import ssl

def emit(data):
    try:
        print(json.dumps(data), flush=True)
    except Exception:
        pass

def main():
    if len(sys.argv) < 2:
        emit({"type": "error", "error": "No payload file provided"})
        sys.exit(1)

    payload_file = sys.argv[1]
    try:
        with open(payload_file, "r", encoding="utf-8") as f:
            config = json.load(f)
    except Exception as e:
        emit({"type": "error", "error": f"Failed to read payload file: {e}"})
        sys.exit(1)

    api_format = config.get("api_format", "gemini")
    endpoint = config.get("endpoint", "")
    api_key = config.get("api_key", "")
    model_name = config.get("model", "")
    system_prompt = config.get("system_prompt", "")
    temperature = config.get("temperature", 0.5)
    messages = config.get("messages", [])

    ctx = ssl.create_default_context()

    try:
        if api_format == "gemini":
            contents = []
            for msg in messages:
                text_content = msg.get("content", "").strip()
                if not text_content:
                    continue
                role = "model" if msg.get("role") == "assistant" else "user"
                # Ensure multiturn adheres to alternating role constraint
                if contents and contents[-1]["role"] == role:
                    contents[-1]["parts"][0]["text"] += "\n\n" + text_content
                else:
                    contents.append({
                        "role": role,
                        "parts": [{"text": text_content}]
                    })

            if not contents:
                emit({"type": "error", "error": "Message content is empty"})
                sys.exit(0)

            req_body = {
                "contents": contents,
                "generationConfig": {
                    "temperature": temperature
                }
            }
            if system_prompt:
                req_body["system_instruction"] = {
                    "parts": [{"text": system_prompt}]
                }

            # Prepare SSE stream URL
            sep = "&" if "?" in endpoint else "?"
            base_endpoint = endpoint
            if ":generateContent" in base_endpoint:
                base_endpoint = base_endpoint.replace(":generateContent", ":streamGenerateContent")
            elif ":streamGenerateContent" not in base_endpoint:
                base_endpoint = base_endpoint + ":streamGenerateContent"

            full_url = f"{base_endpoint}{sep}alt=sse&key={api_key}"

            data = json.dumps(req_body).encode("utf-8")
            req = urllib.request.Request(
                full_url,
                data=data,
                headers={"Content-Type": "application/json"},
                method="POST"
            )

            total_tokens = {"input": -1, "output": -1, "total": -1}
            with urllib.request.urlopen(req, context=ctx, timeout=60) as resp:
                for line in resp:
                    line_str = line.decode("utf-8", errors="ignore").strip()
                    if not line_str or not line_str.startswith("data:"):
                        continue
                    clean_json = line_str[5:].strip()
                    if not clean_json or clean_json == "[DONE]":
                        continue
                    try:
                        chunk_obj = json.loads(clean_json)
                        if "candidates" in chunk_obj and len(chunk_obj["candidates"]) > 0:
                            parts = chunk_obj["candidates"][0].get("content", {}).get("parts", [])
                            for part in parts:
                                text_piece = part.get("text", "")
                                if text_piece:
                                    emit({"type": "token", "text": text_piece})
                        if "usageMetadata" in chunk_obj:
                            usage = chunk_obj["usageMetadata"]
                            total_tokens = {
                                "input": usage.get("promptTokenCount", -1),
                                "output": usage.get("candidatesTokenCount", -1),
                                "total": usage.get("totalTokenCount", -1)
                            }
                    except Exception:
                        pass

            emit({"type": "done", "tokens": total_tokens})

        else:
            # OpenAI / Grok / Mistral / Ollama streaming format
            formatted_messages = []
            if system_prompt:
                formatted_messages.append({"role": "system", "content": system_prompt})
            for msg in messages:
                text_content = msg.get("content", "").strip()
                if not text_content:
                    continue
                formatted_messages.append({
                    "role": msg.get("role", "user"),
                    "content": text_content
                })

            if not formatted_messages:
                emit({"type": "error", "error": "Message content is empty"})
                sys.exit(0)

            req_body = {
                "model": model_name,
                "messages": formatted_messages,
                "temperature": temperature,
                "stream": True
            }

            headers = {"Content-Type": "application/json"}
            if api_key:
                headers["Authorization"] = f"Bearer {api_key}"

            data = json.dumps(req_body).encode("utf-8")
            req = urllib.request.Request(
                endpoint,
                data=data,
                headers=headers,
                method="POST"
            )

            total_tokens = {"input": -1, "output": -1, "total": -1}
            with urllib.request.urlopen(req, context=ctx, timeout=60) as resp:
                for line in resp:
                    line_str = line.decode("utf-8", errors="ignore").strip()
                    if not line_str or not line_str.startswith("data:"):
                        continue
                    clean_json = line_str[5:].strip()
                    if clean_json == "[DONE]":
                        break
                    try:
                        chunk_obj = json.loads(clean_json)
                        if "choices" in chunk_obj and len(chunk_obj["choices"]) > 0:
                            delta = chunk_obj["choices"][0].get("delta", {})
                            text_piece = delta.get("content", "")
                            if text_piece:
                                emit({"type": "token", "text": text_piece})
                        if "usage" in chunk_obj and chunk_obj["usage"]:
                            usage = chunk_obj["usage"]
                            total_tokens = {
                                "input": usage.get("prompt_tokens", -1),
                                "output": usage.get("completion_tokens", -1),
                                "total": usage.get("total_tokens", -1)
                            }
                    except Exception:
                        pass

            emit({"type": "done", "tokens": total_tokens})

    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8", errors="ignore")
        try:
            err_json = json.loads(err_body)
            err_msg = err_json.get("error", {}).get("message", err_body)
        except Exception:
            err_msg = err_body
        emit({"type": "error", "error": f"HTTP {e.code}: {err_msg}"})
    except Exception as e:
        emit({"type": "error", "error": str(e)})

if __name__ == "__main__":
    main()
