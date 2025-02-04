#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

echo "[flac extractor v0.2]"

show_help() {
    echo "Usage: $0 [--force] [--cat <category>] [--importFolder <path>] <folder>"
    echo ""
    echo "Options:"
    echo "  --force                Force extraction even if the album already exists."
    echo "  --cat <category>       Specify the category (currently supports 'lidarr')."
    echo "  --importFolder <path>  Specify the path to move completed downloads into."
    echo ""
    echo "Description:"
    echo "This script processes FLAC files using cue sheets. It extracts tracks from FLAC files, tags them, and moves them into a new directory based on the cue sheet name."
    echo "If the category is 'lidarr' and an import folder is specified, the processed directory will be moved into the import folder."
    echo ""
    echo "More info: https://github.com/3dasm/flac-extractor"
}

for arg in "$@"; do
    if [ "$arg" = "--help" ]; then
        show_help
        exit 0
    fi
done

for arg in "$@"; do
    if [ "$arg" = "--help" ]; then
        help
        exit 0
    fi
done

help() {
    echo "Usage: $0 [--force] [--cat <category>] [--importFolder <path>] <folder>"
    echo ""
    echo "Options:"
    echo "  --force                Force extraction even if the album already exists."
    echo "  --cat <category>       Specify the category (currently supports 'lidarr')."
    echo "  --importFolder <path>  Specify the path to move completed downloads into."
    echo ""
    echo "Description:"
    echo "This script processes FLAC files using cue sheets. It extracts tracks from FLAC files, tags them, and moves them into a new directory based on the cue sheet name."
    echo "If the category is 'lidarr' and an import folder is specified, the processed directory will be moved into the import folder."
}

force_mode=false
folder="."
category=""
importFolder=""

for arg in "$@"; do
    if [ "$arg" = "--force" ]; then
        force_mode=true
        echo "==============================="
        echo "- FORCE MODE"
        echo "==============================="
    elif [ "$arg" = "--cat" ]; then
        category="$2"
        shift 2
    elif [ "$arg" = "--importFolder" ]; then
        importFolder="$2"
        shift 2
    else
        folder="$arg"
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
        escaped_base=$(printf '%s' "$cue_filename_base" | sed 's/[][!.*?^$(){}+| /]/\\&/g')

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
            if [ "$force_mode" = false ]; then
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
            echo "- Removing original flac"
            rm "$current_flac"
            echo "- Done!"
        else
            echo "- ERR: shnsplit failed! Skipping..." >&2
            rmdir "$dir/$cue_filename_base" 2>/dev/null || echo "- WARNING: '$dir/$cue_filename_base' is not empty or could not be removed."
        fi

        echo "==============================="
    done
}

# Iterate over all directories, processing each one.
find "$folder" -type d -print0 | while IFS= read -r -d '' dir; do
    process_directory "$dir"
done

if [ "$category" = "lidarr" ]; then
    if [ -n "$importFolder" ] && [ -d "$importFolder" ]; then
        echo "- Moving lidarr completed download into $importFolder..."
        mv "$folder" "$importFolder"
        echo "- Moved successfully!"
    else
        echo "- ERR: Import folder not specified or does not exist." >&2
    fi
fi

echo "- Exiting!"
