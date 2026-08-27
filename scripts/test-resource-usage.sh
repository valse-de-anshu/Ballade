#!/usr/bin/env bash
# ==============================================================================
# Ballade Widget Resource Usage Profiling & Diagnostics Suite
# Analyzes CPU, Memory (RSS), Process Spawns & High-Cost Animations
# ==============================================================================

set -eo pipefail

echo "======================================================================"
echo " 🔬 QUICKSCALE / BALLADE WIDGET RESOURCE PROFILER"
echo "======================================================================"
echo ""

QS_PIDS=$(pgrep -f "qs -c ballade" || true)

if [ -z "$QS_PIDS" ]; then
    echo "⚠️  No active 'qs -c ballade' process found."
    exit 1
fi

echo "🟢 Found Active QuickShell Process(es): $QS_PIDS"
echo ""

# 1. Measure Live CPU & RSS Memory
echo "📊 [Phase 1] Sampling CPU & RAM over 5 seconds..."
python3 - << 'PYEOF'
import subprocess, time

def sample():
    out = subprocess.check_output(["ps", "-C", "qs", "-o", "%cpu,rss,pmem", "--no-headers"], text=True).strip()
    cpu, rss, pmem = 0.0, 0.0, 0.0
    for line in out.splitlines():
        p = line.split()
        if len(p) >= 3:
            cpu += float(p[0])
            rss += float(p[1]) / 1024.0 # MB
            pmem += float(p[2])
    return cpu, rss, pmem

samples = []
for _ in range(10):
    samples.append(sample())
    time.sleep(0.5)

avg_cpu = sum(s[0] for s in samples) / len(samples)
max_cpu = max(s[0] for s in samples)
avg_rss = sum(s[1] for s in samples) / len(samples)
avg_pmem = sum(s[2] for s in samples) / len(samples)

print(f"   ▶ Average CPU: {avg_cpu:.1f}%  |  Peak CPU: {max_cpu:.1f}%")
print(f"   ▶ Memory RSS:  {avg_rss:.1f} MB ({avg_pmem:.1f}% of System RAM)")
PYEOF

echo ""
echo "🔍 [Phase 2] High-Cost Widget & Animation Audit:"
python3 - << 'PYEOF'
import json, os, subprocess

config_file = os.path.expanduser("~/.config/illogical-impulse/config.json")
if os.path.exists(config_file):
    with open(config_file) as f:
        cfg = json.load(f)
    bg = cfg.get("background", {})
    w = bg.get("widgets", {})
    
    table = [
        ("Visualizer (Audio Waveform)", w.get("visualizer", {}).get("enable", False), "60 FPS dynamic geometry recalculations across full screen width"),
        ("Cookie Clock Rotation", w.get("clock", {}).get("cookie", {}).get("constantlyRotate", False), "Continuous drop-shadow shader re-render"),
        ("Animated Mascot GIFs", w.get("images", {}).get("enable", False) or w.get("customImage", {}).get("enable", False), "Continuous frame-by-frame CPU decode & FBO shader blit"),
        ("Live Weather Poller", w.get("weather", {}).get("enable", False), "Periodic HTTP network polling to wttr.in"),
        ("Hardware Resources Monitor", w.get("resources", {}).get("enable", False), "Periodic /proc and system metrics polling")
    ]
    
    print(f"   {'Widget / Feature':<30} | {'Status':<10} | {'Impact / Notes'}")
    print("   " + "-" * 75)
    for name, enabled, note in table:
        status_str = "ENABLED ⚠️" if enabled else "OFF ✅"
        print(f"   {name:<30} | {status_str:<10} | {note}")
PYEOF

echo ""
echo "💡 [Phase 3] Resource-Efficiency Best Practices:"
echo "   1. Audio Visualizer: Automatically sleeps when music is paused or audio is silent."
echo "   2. Cookie Clock: Inner shape rotation without heavy drop shadow shader re-blurring."
echo "   3. Floating Mascot GIFs: Pauses AnimatedImage playback when screen is locked."
echo "======================================================================"
