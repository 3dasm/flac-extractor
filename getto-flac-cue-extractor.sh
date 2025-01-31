#!/bin/bash

echo "[getto flac/cue extractor]"

find . -type d -print0 | while IFS= read -r -d '' dir; do
    echo "- Scanning: $dir"

    if ! cd "$dir"; then
        echo "ERR: Failed to enter directory '$dir'. Skipping..." >&2
        continue
    fi

    # Find all CUE files safely
    mapfile -t -d '' cue_files < <(find . -maxdepth 1 -type f -iname "*.cue" -print0 2>/dev/null)

    for current_cue in "${cue_files[@]}"; do
        cue_filename_base=$(basename -- "$current_cue" | awk '{print tolower($0)}' | sed 's/\.cue$//')

        # Find the matching FLAC file safely
        mapfile -t -d '' flac_files < <(find . -maxdepth 1 -type f -iname "$cue_filename_base.flac" -print0 2>/dev/null)
        current_flac="${flac_files[0]}"

        if [ -z "$current_flac" ]; then
            echo "ERR: No matching FLAC for '$cue_filename_base.cue'" >&2
            continue
        fi

        flac_filename_base=$(basename -- "$current_flac" | awk '{print tolower($0)}' | sed 's/\.flac$//')

        echo "[$flac_filename_base] Processing..."
        shnsplit -f "$current_cue" -O always -t "%n - %p - %t" -o "flac flac -s -o %f -" "$current_flac"

        if [ $? -eq 0 ]; then
            echo "[$flac_filename_base] Storing away original FLAC..."
            mkdir orig
            mv "$current_flac" orig

            echo "[$flac_filename_base] Tagging split files..."
            find . -maxdepth 1 -type f -iname "*.flac" -print0 | xargs -0 cuetag "$current_cue"

            echo "[$flac_filename_base] Done."
        else
            echo "[$flac_filename_base] ERR: shnsplit failed! Skipping..." >&2
        fi
    done

    cd - >/dev/null || exit
done

echo "- All processing completed!"