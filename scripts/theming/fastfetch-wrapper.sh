#!/usr/bin/env bash
# ==============================================================================
# Ballade Fastfetch Deck Shuffler (Zero-Duplicate Queue)
# Guaranteed 100% unique cycle across all images with cross-cycle anti-repeat
# ==============================================================================

ASSET_DIR="$HOME/.config/fastfetch/asset"
FASTFETCH_BIN="/usr/bin/fastfetch"
CACHE_DIR="$HOME/.cache/fastfetch"
QUEUE_FILE="$CACHE_DIR/queue.txt"
LAST_FILE="$CACHE_DIR/last_image"

mkdir -p "$CACHE_DIR"

if [ -d "$ASSET_DIR" ]; then
    # Purge any deleted files from the existing queue
    if [ -f "$QUEUE_FILE" ]; then
        temp_queue=$(mktemp)
        while IFS= read -r line; do
            [ -n "$line" ] && [ -f "$line" ] && echo "$line" >> "$temp_queue"
        done < "$QUEUE_FILE"
        mv "$temp_queue" "$QUEUE_FILE"
    fi

    # Generate fresh shuffled queue if empty
    if [ ! -s "$QUEUE_FILE" ]; then
        last_img=""
        [ -f "$LAST_FILE" ] && last_img=$(cat "$LAST_FILE" 2>/dev/null)

        mapfile -t new_deck < <(find "$ASSET_DIR" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) 2>/dev/null | shuf)
        
        # If the first card in the new deck matches the last card of previous deck, swap it with the last card
        if [ ${#new_deck[@]} -gt 1 ] && [ "${new_deck[0]}" = "$last_img" ]; then
            first="${new_deck[0]}"
            new_deck[0]="${new_deck[-1]}"
            new_deck[-1]="$first"
        fi

        printf "%s\n" "${new_deck[@]}" > "$QUEUE_FILE"
    fi

    while [ -s "$QUEUE_FILE" ]; do
        selected_img=$(head -n 1 "$QUEUE_FILE")
        sed -i '1d' "$QUEUE_FILE"

        if [ -n "$selected_img" ] && [ -f "$selected_img" ]; then
            echo "$selected_img" > "$LAST_FILE"
            ln -sf "$selected_img" "$HOME/.config/fastfetch/current_logo.png" 2>/dev/null || true

            # Invalidate fastfetch's internal cached terminal graphics if source image is newer than cache
            cached_img_dir="$CACHE_DIR/images${selected_img}"
            if [ -d "$cached_img_dir" ]; then
                if [ "$selected_img" -nt "$cached_img_dir" ]; then
                    rm -rf "$cached_img_dir" 2>/dev/null || true
                fi
            fi

            has_logo=false
            for arg in "$@"; do
                if [[ "$arg" == "--logo" || "$arg" =~ ^--logo= ]]; then
                    has_logo=true
                    break
                fi
            done

            if [ "$has_logo" = false ]; then
                exec "$FASTFETCH_BIN" --logo "$selected_img" "$@"
            fi
            break
        fi
    done
fi

exec "$FASTFETCH_BIN" "$@"
