#!/bin/bash

echo "[getto flac/cue extractor]"

restore_mode=false
for arg in "$@"; do
    if [ "$arg" = "--restore" ]; then
        restore_mode=true
    fi
done

find . -type d -print0 | while IFS= read -r -d '' dir; do
    echo "- Scanning: $dir"

    if ! cd "$dir"; then
        echo "ERR: Failed to enter directory '$dir'. Skipping..." >&2
        continue
    fi

    # In restore mode, if an 'orig' folder exists and contains FLAC files,
    # move them back to the parent folder.
    if [ "$restore_mode" = true ] && [ -d "orig" ]; then
        shopt -s nullglob
        for file in orig/*.flac; do
            echo "Moving restored file: $file"
            mv "$file" .
        done
        shopt -u nullglob
    fi

    mapfile -t -d '' cue_files < <(find . -maxdepth 1 -type f -iname "*.cue" -print0 2>/dev/null)

    for current_cue in "${cue_files[@]}"; do
        cue_filename_base=$(basename -- "$current_cue" | sed 's/\.cue$//')

        mapfile -t -d '' flac_files < <(find . -maxdepth 1 -type f -iname "$cue_filename_base.flac" -print0 2>/dev/null)
        current_flac="${flac_files[0]}"

        if [ -z "$current_flac" ]; then
            echo "ERR: No matching FLAC for '$cue_filename_base.cue'" >&2
            continue
        fi

        echo "[$cue_filename_base] Processing..."

        # If restore mode is enabled, add "-O always" to force overwriting.
        if [ "$restore_mode" = true ]; then
            overwrite_opt="-O always"
        else
            overwrite_opt=""
        fi

        shnsplit -f "$current_cue" $overwrite_opt -t "$cue_filename_base - %t" -o "flac flac -s -o %f -" "$current_flac"

        if [ $? -eq 0 ]; then
            echo "[$cue_filename_base] Storing away original FLAC..."
            mkdir orig
            mv "$current_flac" orig

            echo "[$cue_filename_base] Tagging split files..."
            find . -maxdepth 1 -type f -iname "*.flac" -print0 | xargs -0 cuetag "$current_cue" "$cue_filename_base*.flac"

            echo "[$cue_filename_base] Done."
        else
            echo "[$cue_filename_base] ERR: shnsplit failed! Skipping..." >&2
        fi
    done

    cd - >/dev/null || exit
done

echo "- All processing completed!"