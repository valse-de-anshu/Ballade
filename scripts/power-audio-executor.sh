#!/bin/bash
# Power command wrapper with audio deduplication & dynamic settings support
# Version 3.0 - Fully Portable & Config-driven

set -euo pipefail

readonly CONFIG_FILE="$HOME/.config/illogical-impulse/config.json"
readonly DEFAULT_AUDIO="$HOME/.local/share/shutdown_sound.flac"
readonly LOG_FILE="/tmp/power-audio-wrapper.log"
readonly LOCK_FILE="/tmp/power-audio-lock"
readonly DEDUP_SECONDS=10

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

get_real_binary() {
    local cmd="$1"
    which -a "$cmd" | grep -v "$HOME/.local/bin" | head -n1
}

play_audio_once() {
    local action="$1"
    
    # Check deduplication
    if [[ -f "$LOCK_FILE" ]]; then
        local last_played current_time diff
        last_played=$(cat "$LOCK_FILE" 2>/dev/null || echo 0)
        current_time=$(date +%s)
        diff=$((current_time - last_played))
        
        if [[ $diff -lt $DEDUP_SECONDS ]]; then
            log_msg "SKIP: Audio played ${diff}s ago"
            return 0
        fi
    fi
    
    date +%s > "$LOCK_FILE"

    # Read config if jq is available
    local enabled="true"
    local audio_file=""
    local volume=70

    if command -v jq &>/dev/null && [[ -f "$CONFIG_FILE" ]]; then
        enabled=$(jq -r '.sounds.enableSystemSounds // true' "$CONFIG_FILE" 2>/dev/null || echo "true")
        volume=$(jq -r '.sounds.systemSoundVolume // 70' "$CONFIG_FILE" 2>/dev/null || echo "70")

        if [[ "$enabled" == "false" ]]; then
            log_msg "SKIP: System sounds disabled in config"
            return 0
        fi

        case "$action" in
            poweroff|reboot)
                audio_file=$(jq -r '.sounds.shutdownSoundPath // ""' "$CONFIG_FILE" 2>/dev/null || echo "")
                ;;
            lock-session)
                audio_file=$(jq -r '.sounds.lockSoundPath // ""' "$CONFIG_FILE" 2>/dev/null || echo "")
                ;;
            suspend|hibernate)
                audio_file=$(jq -r '.sounds.sleepSoundPath // ""' "$CONFIG_FILE" 2>/dev/null || echo "")
                ;;
            logout)
                audio_file=$(jq -r '.sounds.logoutSoundPath // ""' "$CONFIG_FILE" 2>/dev/null || echo "")
                ;;
        esac
    fi

    # Fallback to default audio file if action-specific sound is not set
    if [[ -z "$audio_file" || ! -f "$audio_file" ]]; then
        if [[ -f "$CONFIG_FILE" ]] && command -v jq &>/dev/null; then
            audio_file=$(jq -r '.sounds.shutdownSoundPath // ""' "$CONFIG_FILE" 2>/dev/null || echo "")
        fi
    fi

    if [[ -z "$audio_file" || ! -f "$audio_file" ]]; then
        audio_file="$DEFAULT_AUDIO"
    fi

    # Play audio with configured volume
    if [[ -f "$audio_file" ]]; then
        log_msg "PLAY: $audio_file (Volume: ${volume}%)"
        local vol_norm=$(awk "BEGIN {print $volume/100}")
        local pa_vol=$((65536 * volume / 100))

        if command -v pw-play &>/dev/null; then
            pw-play --volume "$vol_norm" "$audio_file" 2>/dev/null || true
        elif command -v paplay &>/dev/null; then
            paplay --volume="$pa_vol" "$audio_file" 2>/dev/null || true
        elif command -v mpv &>/dev/null; then
            mpv --no-video --volume="$volume" "$audio_file" 2>/dev/null || true
        elif command -v ffplay &>/dev/null; then
            ffplay -nodisp -autoexit -volume "$volume" "$audio_file" 2>/dev/null || true
        else
            log_msg "ERROR: No audio player"
        fi
    else
        log_msg "ERROR: Audio file missing: $audio_file"
    fi
}

main() {
    local binary="$1"
    local command="$2"
    shift 2
    
    log_msg "CMD: $binary $command $*"
    
    case "$command" in
        poweroff|reboot|suspend|hibernate|lock-session)
            play_audio_once "$command"
            local real_bin
            real_bin=$(get_real_binary "$binary")
            log_msg "EXEC: $real_bin $command $*"
            exec "$real_bin" "$command" "$@"
            ;;
        *)
            local real_bin
            real_bin=$(get_real_binary "$binary")
            log_msg "PASS: $real_bin $command $*"
            exec "$real_bin" "$command" "$@"
            ;;
    esac
}

main "$@"
