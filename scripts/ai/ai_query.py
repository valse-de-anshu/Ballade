#!/usr/bin/env python3
"""
QuickShell Ballade - Streaming AI Query Engine
Streams tokens in real time for Google Gemini, OpenAI, Mistral, Grok, and OpenRouter.
Supports multimodal image and document attachments, tools/function calling, and search grounding.
Outputs JSON lines to stdout with immediate flushing.
"""

import sys
import json
import urllib.request
import urllib.error
import ssl
import os
import base64
import mimetypes

def emit(data):
    try:
        print(json.dumps(data), flush=True)
    except Exception:
        pass

def prepare_attachment(file_path):
    if not file_path or not os.path.isfile(file_path):
        return None
    ext = os.path.splitext(file_path)[1].lower()
    is_image = ext in [".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp"]
    mime, _ = mimetypes.guess_type(file_path)
    if not mime:
        mime = "image/png" if is_image else "text/plain"
    try:
        if is_image:
            with open(file_path, "rb") as f:
                data = base64.b64encode(f.read()).decode("utf-8")
            return {"type": "image", "mime": mime, "data": data, "path": file_path}
        else:
            with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                text = f.read(50000)
            return {"type": "text", "filename": os.path.basename(file_path), "text": text, "path": file_path}
    except Exception:
        return None

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
    tool_mode = config.get("tool", "functions")
    tools_cfg = config.get("tools", {})

    ctx = ssl.create_default_context()

    try:
        if api_format == "gemini":
            contents = []
            for msg in messages:
                text_content = msg.get("content", "").strip()
                file_path = msg.get("localFilePath", "")
                attached = prepare_attachment(file_path) if file_path else None

                parts = []
                if attached:
                    if attached["type"] == "image":
                        parts.append({
                            "inline_data": {
                                "mime_type": attached["mime"],
                                "data": attached["data"]
                            }
                        })
                    elif attached["type"] == "text":
                        text_content = f"[Attached File: {attached['filename']}]\n```\n{attached['text']}\n```\n\n{text_content}".strip()

                if text_content:
                    parts.append({"text": text_content})
                elif not parts:
                    continue

                role = "model" if msg.get("role") == "assistant" else "user"
                if contents and contents[-1]["role"] == role:
                    contents[-1]["parts"].extend(parts)
                else:
                    contents.append({
                        "role": role,
                        "parts": parts
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

            # Configure tools for Gemini
            if tool_mode == "search":
                req_body["tools"] = [{"googleSearch": {}}]
            elif tool_mode == "functions":
                gemini_funcs = tools_cfg.get("functions", [])
                if gemini_funcs:
                    req_body["tools"] = gemini_funcs

            # Build list of real candidate models
            primary_model = model_name or "gemini-2.5-flash"
            candidate_models = [primary_model]
            for fallback in ["gemini-2.5-flash", "gemini-2.5-flash-lite", "gemini-3-flash-preview", "gemini-2.5-pro"]:
                if fallback not in candidate_models:
                    candidate_models.append(fallback)

            data = json.dumps(req_body).encode("utf-8")
            last_err = None
            success = False

            for cand in candidate_models:
                cand_endpoint = f"https://generativelanguage.googleapis.com/v1beta/models/{cand}:streamGenerateContent?alt=sse&key={api_key}"
                req = urllib.request.Request(
                    cand_endpoint,
                    data=data,
                    headers={"Content-Type": "application/json"},
                    method="POST"
                )

                total_tokens = {"input": -1, "output": -1, "total": -1}
                tokens_emitted = False
                try:
                    with urllib.request.urlopen(req, context=ctx, timeout=35) as resp:
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
                                    cand_data = chunk_obj["candidates"][0]
                                    parts = cand_data.get("content", {}).get("parts", [])
                                    for part in parts:
                                        text_piece = part.get("text", "")
                                        if text_piece:
                                            emit({"type": "token", "text": text_piece})
                                            tokens_emitted = True
                                        fn_call = part.get("functionCall")
                                        if fn_call:
                                            emit({
                                                "type": "function_call",
                                                "name": fn_call.get("name", ""),
                                                "args": fn_call.get("args", {})
                                            })
                                            tokens_emitted = True

                                    grounding = cand_data.get("groundingMetadata")
                                    if grounding:
                                        queries = grounding.get("webSearchQueries", [])
                                        chunks = grounding.get("groundingChunks", [])
                                        sources = []
                                        for c in chunks:
                                            web = c.get("web", {})
                                            if web and web.get("uri"):
                                                sources.append({
                                                    "title": web.get("title", ""),
                                                    "url": web.get("uri")
                                                })
                                        emit({"type": "grounding", "queries": queries, "sources": sources})

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
                    success = True
                    break
                except urllib.error.HTTPError as e:
                    err_body = e.read().decode("utf-8", errors="ignore")
                    try:
                        err_json = json.loads(err_body)
                        err_msg = err_json.get("error", {}).get("message", err_body)
                    except Exception:
                        err_msg = err_body
                    last_err = f"HTTP {e.code}: {err_msg}"
                    if tokens_emitted or e.code not in (404, 429, 503, 500):
                        break
                    continue
                except Exception as e:
                    last_err = str(e)
                    if tokens_emitted:
                        break
                    continue

            if not success and last_err:
                emit({"type": "error", "error": last_err})

        else:
            # OpenAI / Mistral / OpenRouter streaming format
            formatted_messages = []
            if system_prompt:
                formatted_messages.append({"role": "system", "content": system_prompt})

            for msg in messages:
                text_content = msg.get("content", "").strip()
                file_path = msg.get("localFilePath", "")
                attached = prepare_attachment(file_path) if file_path else None
                role = msg.get("role", "user")

                if attached and attached["type"] == "image":
                    content_items = []
                    if text_content:
                        content_items.append({"type": "text", "text": text_content})
                    content_items.append({
                        "type": "image_url",
                        "image_url": {"url": f"data:{attached['mime']};base64,{attached['data']}"}
                    })
                    formatted_messages.append({"role": role, "content": content_items})
                else:
                    if attached and attached["type"] == "text":
                        text_content = f"[Attached File: {attached['filename']}]\n```\n{attached['text']}\n```\n\n{text_content}".strip()
                    if text_content:
                        formatted_messages.append({"role": role, "content": text_content})

            if not formatted_messages:
                emit({"type": "error", "error": "Message content is empty"})
                sys.exit(0)

            # Auto-replace obsolete or content-safety models
            req_model = model_name
            if req_model == "openrouter/free":
                req_model = "openrouter/auto"

            req_body = {
                "model": req_model,
                "messages": formatted_messages,
                "temperature": temperature,
                "stream": True
            }

            # Configure tools for OpenAI / Mistral
            if tool_mode == "functions":
                openai_funcs = tools_cfg.get("functions", [])
                if openai_funcs:
                    req_body["tools"] = openai_funcs

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
            with urllib.request.urlopen(req, context=ctx, timeout=120) as resp:
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
                            tool_calls = delta.get("tool_calls", [])
                            for tc in tool_calls:
                                fn = tc.get("function", {})
                                fn_name = fn.get("name", "")
                                fn_args_str = fn.get("arguments", "")
                                try:
                                    fn_args = json.loads(fn_args_str) if fn_args_str else {}
                                except Exception:
                                    fn_args = {"command": fn_args_str}
                                if fn_name:
                                    emit({"type": "function_call", "name": fn_name, "args": fn_args})

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
        err_str = str(e)
        if "timed out" in err_str.lower():
            emit({"type": "error", "error": "The upstream AI server connection timed out. Please try again."})
        else:
            emit({"type": "error", "error": err_str})

if __name__ == "__main__":
    main()
