#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

echo "[getto flac/cue extractor]"

restore_mode=false
for arg in "$@"; do
    if [ "$arg" = "--restore" ]; then
        restore_mode=true
        echo "==============================="
        echo "- RESTORE MODE: This script will restore the original FLAC files stored in the /orig folder"
        echo "==============================="
    fi
done

process_directory() {
    local dir="$1"
    local base
    base=$(basename "$dir")

    # Skip directories with these names.
    if [[ "$base" =~ ^(Cover|Covers|Scans|scans)$ ]]; then
        return
    fi

    # If this directory is named "orig", restore its FLAC files if in restore mode.
    if [ "$base" = "orig" ]; then
        if [ "$restore_mode" = true ]; then
            shopt -s nocaseglob
            for file in "$dir"/*.flac; do
                # Only process if the file exists.
                [ -e "$file" ] || continue
                echo "- RESTORE MODE: Restoring $file..."
                mv -f "$file" "$dir/../"
            done
            shopt -u nocaseglob
            rmdir "$dir" 2>/dev/null || echo "- WARNING: '$dir' is not empty or could not be removed."
        fi
        return
    fi

    echo "- Scanning: $dir"

    # Read all cue files in the current directory.
    local cue_files=()
    mapfile -t -d '' cue_files < <(find "$dir" -maxdepth 1 -type f -iname "*.cue" -print0 2>/dev/null)

    for current_cue in "${cue_files[@]}"; do
        echo "==============================="

        # Get the base name (without .cue) and create an escaped version for literal matching.
        local cue_filename_base
        cue_filename_base=$(basename -- "$current_cue" | sed 's/\.cue$//I')
        local escaped_base
        escaped_base=$(printf '%s' "$cue_filename_base" | sed 's/[][!.*?^$(){}+| ]/\\&/g')

        # Find the matching FLAC file (using the escaped base name).
        local flac_files=()
        mapfile -t -d '' flac_files < <(find "$dir" -maxdepth 1 -type f -iname "${escaped_base}.flac" -print0 2>/dev/null)
        local current_flac="${flac_files[0]:-}"

        if [ -z "$current_flac" ]; then
            echo "- WRN: No matching FLAC for ($current_cue)" >&2
            echo "==============================="
            continue
        fi

        # Check if the extraction directory exists.
        if [ -d "$dir/$cue_filename_base" ]; then
            if [ "$restore_mode" = false ]; then
                echo "- WRN: Album already extracted: $cue_filename_base"
                echo "==============================="
                continue
            fi
        else
            # Create the extraction directory if it doesn't exist.
            if ! mkdir -p "$dir/$cue_filename_base"; then
                echo "- ERR: Failed to create sub-dir for extracted files." >&2
                continue
            fi
        fi

        echo "- Extracting: $cue_filename_base"
        if shnsplit -O always -f "$current_cue" -d "$dir/$cue_filename_base" \
            -t "%n - %a - %t" -o "flac flac -s -o %f -" "$current_flac"; then
            echo "- Tagging split files..."
            cuetag "$current_cue" "$dir/$cue_filename_base"/*.flac
            echo "- Done!"
        else
            echo "- ERR: shnsplit failed! Skipping..." >&2
            rmdir "$dir/$cue_filename_base" 2>/dev/null || echo "- WARNING: '$dir/$cue_filename_base' is not empty or could not be removed."
        fi

        echo "==============================="
    done
}

# Iterate over all directories, processing each one.
find . -type d -print0 | while IFS= read -r -d '' dir; do
    process_directory "$dir"
done

echo "- Exiting!"
