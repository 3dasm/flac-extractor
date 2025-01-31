# **Getto FLAC/CUE Extractor 🎵**

I create this script after realizing I was downloading tons of FLAC albumns that were not splitted, some are, most, but a huge percentage out there are in the bundled format with the respective CUE file.

A **Bash script** for extracting and splitting **FLAC** audio files using **CUE sheets**.  
It automates the process of **splitting**, **tagging**, and **storing** the original FLAC files.

## **Features**

✅ **Scans directories** for matching `.cue` and `.flac` files  
✅ **Handles case-insensitive filenames** (`.CUE` / `.FLAC`)  
✅ **Splits FLAC files** into individual tracks using `shnsplit`  
✅ **Tags the split tracks** with metadata from the `.cue` file  
✅ **Moves original FLAC files** to an `orig/` folder for backup  
✅ **Handles filenames with spaces & special characters** safely

## **Requirements**

Make sure the following dependencies are installed:

- `shntool`
- `cuetools`
- `flac`
- `awk`, `sed`, and `find` (default in most Unix systems)

## **Usage**

```bash
chmod +x getto-flac-cue-extractor.sh
./getto-flac-cue-extractor.sh
```

The script will scan **all directories** recursively and process `.cue` files.  
**Extracted tracks** will be saved in the same directory as the original FLAC.

## **Example Output**

```
[getto flac/cue extractor]
- Scanning: /music/album/
[Album] Processing...
[Album] Storing away original FLAC...
[Album] Tagging split files...
[Album] Done.
- All processing completed!
```

## **License**

📜 MIT License – Feel free to modify and share!

---
