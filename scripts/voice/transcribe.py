#!/usr/bin/env python3
import sys
import time
import wave
import io
import os
import subprocess
import threading
import signal
import gc
import numpy as np
import sounddevice as sd

SAMPLE_RATE = 16000
CHANNELS = 1
SILENCE_TIMEOUT = 3.5  # 3.5 seconds silence auto stop

WHISPER_CLI = "/home/valse-de-anshu/.config/quickshell/ballade/scripts/voice/whisper.cpp/build/bin/whisper-cli"
WHISPER_MODEL = "/home/valse-de-anshu/.config/quickshell/ballade/scripts/voice/whisper.cpp/models/ggml-base.en.bin"
TEMP_WAV = "/tmp/qs_whisper_input.wav"

class WhisperTranscriber:
    def __init__(self):
        self.audio_frames = []
        self.is_recording = True
        self.speech_started = False
        self.last_speech_time = time.time()
        self.start_time = time.time()
        self.lock = threading.Lock()

        self.frame_count = 0
        self.calibrating_frames = 5
        self.ambient_sum = 0.0
        self.ambient_rms = 0.01
        self.speech_threshold = 0.025

    def audio_callback(self, indata, frames, time_info, status):
        if not self.is_recording:
            return
        
        rms = float(np.sqrt(np.mean(indata**2)))

        if self.frame_count < self.calibrating_frames:
            self.frame_count += 1
            self.ambient_sum += rms
            if self.frame_count == self.calibrating_frames:
                avg_rms = self.ambient_sum / self.calibrating_frames
                self.ambient_rms = max(0.004, avg_rms)
                self.speech_threshold = max(0.015, self.ambient_rms * 1.8)
            return

        norm_vol = max(0.0, (rms - self.ambient_rms) * 18.0)
        vol = min(1.0, norm_vol)
        print(f"VOLUME:{vol:.2f}", flush=True)

        with self.lock:
            self.audio_frames.append(indata.copy())

        if rms > self.speech_threshold:
            self.speech_started = True
            self.last_speech_time = time.time()

    def monitor_silence(self):
        while self.is_recording:
            time.sleep(0.2)
            current_time = time.time()

            if self.speech_started and (current_time - self.last_speech_time > SILENCE_TIMEOUT):
                print("STATUS:SILENCE_TIMEOUT", flush=True)
                self.is_recording = False
                break

            if (current_time - self.start_time > 45.0):
                self.is_recording = False
                break

    def run(self):
        print("STATUS:LISTENING", flush=True)
        monitor_thread = threading.Thread(target=self.monitor_silence)
        monitor_thread.start()

        device_id = 'pulse'
        try:
            sd.check_input_settings(device='pulse', samplerate=SAMPLE_RATE, channels=CHANNELS)
        except Exception:
            device_id = None

        try:
            with sd.InputStream(device=device_id, samplerate=SAMPLE_RATE, channels=CHANNELS, dtype='float32', callback=self.audio_callback):
                while self.is_recording:
                    time.sleep(0.1)
        except Exception as e:
            print(f"ERROR:{str(e)}", flush=True)
            self.is_recording = False

        monitor_thread.join()
        self.process_with_whisper()

    def process_with_whisper(self):
        try:
            with self.lock:
                if not self.audio_frames:
                    print("STATUS:NO_SPEECH_RECOGNIZED", flush=True)
                    return
                full_audio_np = np.concatenate(self.audio_frames, axis=0)
                self.audio_frames.clear()

            # Normalize audio gain
            max_val = np.max(np.abs(full_audio_np))
            if max_val > 0.0005:
                boosted_audio = (full_audio_np / max_val) * 0.85
            else:
                boosted_audio = full_audio_np

            audio_int16 = (np.clip(boosted_audio, -1.0, 1.0) * 32767).astype(np.int16)

            # Save to temporary WAV file
            with wave.open(TEMP_WAV, 'wb') as wf:
                wf.setnchannels(CHANNELS)
                wf.setsampwidth(2)
                wf.setframerate(SAMPLE_RATE)
                wf.writeframes(audio_int16.tobytes())

            # Execute whisper-cli binary
            cmd = [
                WHISPER_CLI,
                "-m", WHISPER_MODEL,
                "-f", TEMP_WAV,
                "-nt",
                "--no-timestamps",
                "-l", "en"
            ]

            res = subprocess.run(cmd, capture_output=True, text=True)
            text = res.stdout.strip()
            
            if text:
                clean_lines = [line.strip() for line in text.split('\n') if line.strip() and not line.strip().startswith('[')]
                final_text = ' '.join(clean_lines).strip()
                if final_text:
                    print(f"FINAL:{final_text}", flush=True)
                else:
                    print("STATUS:NO_SPEECH_RECOGNIZED", flush=True)
            else:
                print("STATUS:NO_SPEECH_RECOGNIZED", flush=True)

            del full_audio_np, boosted_audio, audio_int16
        except Exception as e:
            print(f"ERROR:{str(e)}", flush=True)
        finally:
            if os.path.exists(TEMP_WAV):
                try:
                    os.remove(TEMP_WAV)
                except Exception:
                    pass
            self.cleanup()

    def cleanup(self):
        with self.lock:
            self.audio_frames.clear()
        gc.collect()

if __name__ == "__main__":
    transcriber = WhisperTranscriber()

    def signal_handler(sig, frame):
        transcriber.is_recording = False
        transcriber.cleanup()
        sys.exit(0)

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    try:
        transcriber.run()
    except Exception:
        transcriber.cleanup()
        sys.exit(0)
