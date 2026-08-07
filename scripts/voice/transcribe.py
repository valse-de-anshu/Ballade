#!/usr/bin/env python3
import sys
import time
import math
import wave
import io
import threading
import signal
import gc
import numpy as np
import sounddevice as sd
import speech_recognition as sr

SAMPLE_RATE = 16000
CHANNELS = 1
SILENCE_TIMEOUT = 4.0  # 4 seconds of silence post-speech auto stop
SILENCE_RMS_THRESHOLD = 0.005 # Ultra-sensitive threshold so soft speech phonemes are NEVER missed!

class VoiceTranscriber:
    def __init__(self):
        self.recognizer = sr.Recognizer()
        self.recognizer.dynamic_energy_threshold = True
        self.recognizer.energy_threshold = 150
        self.recognizer.pause_threshold = 0.8
        
        self.audio_frames = []
        self.is_recording = True
        self.speech_started = False
        self.last_speech_time = time.time()
        self.start_time = time.time()
        self.lock = threading.Lock()

    def audio_callback(self, indata, frames, time_info, status):
        if not self.is_recording:
            return
        
        # Calculate RMS volume for visualizer
        rms = float(np.sqrt(np.mean(indata**2)))
        vol = min(1.0, max(0.0, rms * 15.0))
        print(f"VOLUME:{vol:.2f}", flush=True)

        with self.lock:
            self.audio_frames.append(indata.copy())

        if rms > SILENCE_RMS_THRESHOLD:
            self.speech_started = True
            self.last_speech_time = time.time()

    def monitor_silence(self):
        while self.is_recording:
            time.sleep(0.2)
            current_time = time.time()

            # Auto-stop after 4 seconds of silence post-speech
            if self.speech_started and (current_time - self.last_speech_time > SILENCE_TIMEOUT):
                print("STATUS:SILENCE_TIMEOUT", flush=True)
                self.is_recording = False
                break

            # Safety cap: 60s max recording
            if (current_time - self.start_time > 60.0):
                self.is_recording = False
                break

    def run(self):
        print("STATUS:LISTENING", flush=True)
        monitor_thread = threading.Thread(target=self.monitor_silence)
        monitor_thread.start()

        try:
            # device=None captures system default microphone (PipeWire/PulseAudio default)
            with sd.InputStream(device=None, samplerate=SAMPLE_RATE, channels=CHANNELS, dtype='float32', callback=self.audio_callback):
                while self.is_recording:
                    time.sleep(0.1)
        except Exception as e:
            print(f"ERROR:{str(e)}", flush=True)
            self.is_recording = False

        monitor_thread.join()
        self.process_final_audio()

    def process_final_audio(self):
        try:
            with self.lock:
                if not self.audio_frames:
                    print("STATUS:NO_SPEECH_RECOGNIZED", flush=True)
                    return
                full_audio_np = np.concatenate(self.audio_frames, axis=0)
                self.audio_frames.clear()

            # Convert float32 [-1, 1] to 16-bit PCM WAV
            audio_int16 = (np.clip(full_audio_np, -1.0, 1.0) * 32767).astype(np.int16)
            
            wav_io = io.BytesIO()
            with wave.open(wav_io, 'wb') as wf:
                wf.setnchannels(CHANNELS)
                wf.setsampwidth(2) # 16-bit PCM
                wf.setframerate(SAMPLE_RATE)
                wf.writeframes(audio_int16.tobytes())
            
            wav_io.seek(0)
            
            with sr.AudioFile(wav_io) as source:
                self.recognizer.adjust_for_ambient_noise(source, duration=0.2)
                audio_data = self.recognizer.record(source)
                
                try:
                    text = self.recognizer.recognize_google(audio_data, language="en-US")
                    if text and text.strip():
                        print(f"FINAL:{text.strip()}", flush=True)
                    else:
                        print("STATUS:NO_SPEECH_RECOGNIZED", flush=True)
                except sr.UnknownValueError:
                    print("STATUS:NO_SPEECH_RECOGNIZED", flush=True)
                except Exception as e:
                    print(f"ERROR:{str(e)}", flush=True)
                    
            del full_audio_np, audio_int16, wav_io
        finally:
            self.cleanup()

    def cleanup(self):
        with self.lock:
            self.audio_frames.clear()
        gc.collect()

if __name__ == "__main__":
    transcriber = VoiceTranscriber()

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
