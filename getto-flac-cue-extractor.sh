#!/bin/bash

echo "[getto flac/cue extractor]"

restore_mode=false
for arg in "$@"; do
    if [ "$arg" = "--restore" ]; then
        restore_mode=true
        echo "==============================="
        echo "- RESTORE MODE: This script will restore the original flac file stored in the /orig folder"
        echo "==============================="
    fi
done

find . -type d -print0 | while IFS= read -r -d '' dir; do

    if [ "$(basename "$dir")" = "orig" ]; then
        if [ "$restore_mode" = true ]; then
            shopt -s nocaseglob
            for file in "$dir"/*.flac; do
                echo "- RESTORE MODE: Restoring..."
                mv "$file" "$dir/../"
            done
            shopt -u nocaseglob
            rmdir "$dir" 2>/dev/null || echo "- WARNING: '$dir' is not empty or could not be removed."
        fi
    fi

    echo "- Scanning: $dir"

    mapfile -t -d '' cue_files < <(find "$dir" -maxdepth 1 -type f -iname "*.cue" -print0 2>/dev/null)

    for current_cue in "${cue_files[@]}"; do
        echo "==============================="

        cue_filename_base=$(basename -- "$current_cue" | sed 's/\.cue$//I')
        escaped_base=$(printf '%s' "$cue_filename_base" | sed 's/[][?*]/\\&/g')
    
        mapfile -t -d '' flac_files < <(find "$dir" -maxdepth 1 -type f -iname "$escaped_base".flac -print0 2>/dev/null)
        current_flac="${flac_files[0]}"

        if [ -z "$current_flac" ]; then
            echo " - WRN: No matching FLAC for ($current_cue)" >&2
            echo "==============================="
            continue
        fi

        if [ -d "$dir/$cue_filename_base" ]; then
            if [ "$restore_mode" = false ]; then
                echo " - WRN: Album already extracted: $cue_filename_base"
                echo "==============================="
                continue
            fi
        else
            mkdir -p "$dir/$cue_filename_base" || { echo " - ERR: Failed to create sub-dir for extracted files." >&2; continue; }
        fi

        echo " - Extracting: $cue_filename_base"
        shnsplit -q -O always -f "$current_cue" -d "$dir/$cue_filename_base" -t "%n - %a - %t" -o "flac flac -s -o %f -" "$current_flac" #1>/dev/null

        if [ $? -eq 0 ]; then
            echo " - Tagging split files..."
            cuetag "$current_cue" "$dir/$cue_filename_base"/*.flac
            echo " - Done!"
        else
            echo " - ERR: shnsplit failed! Skipping..." >&2
        fi
        
        echo "==============================="

    done

done

echo "- Exiting!"
