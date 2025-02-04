# FLAC Extractor Script

**FLAC Extractor** is a bash script designed to process FLAC audio files using cue sheets. It extracts tracks from FLAC files, tags them with metadata, and organizes the extracted files into new directories based on the cue sheet names.

## Features

- **Track Extraction:** Automatically extract tracks from FLAC files using `shnsplit`.
- **Metadata Tagging:** Tag each split file with metadata from the associated `.cue` file.
- **Force Mode:** Force extraction even if an album directory already exists.
- **Lidarr Support:** Optionally move processed directories into a specified library folder when running with the "lidarr" category.

## Dependencies

Before using this script, ensure you have the following dependencies installed:

1. **shnsplit:** A tool to split FLAC files based on cue sheets. You can install it using your package manager or build from source.

   ```sh
   sudo apt-get install shntool # Debian/Ubuntu
   brew install shntool         # macOS
   ```

2. **cuetag:** A tool for tagging audio files with metadata from `.cue` files. You can install it similarly:
   ```sh
   sudo apt-get install cuetools flac-utils  # Debian/Ubuntu
   brew install cuetools                   # macOS
   ```

## Installation

1. Clone this repository to your local machine.

   ```sh
   git clone https://github.com/3dasm/flac-extractor.git
   cd flac-extractor
   ```

2. Make the script executable.
   ```sh
   chmod +x flac-extractor.sh
   ```

## Usage

Run the script by specifying the folder containing FLAC files and optionally adding options:

```sh
./flac-extractor.sh [options] <folder>
```

### Options

- `--force`: Force extraction even if an album directory already exists.
- `--cat <category>`: Specify the category (currently supports "lidarr").
- `--importFolder <path>`: Specify the path to move completed downloads into.

### Examples

1. **Basic Extraction:**

   ```sh
   ./flac-extractor.sh /path/to/flac/files
   ```

2. **Force Extraction:**

   ```sh
   ./flac-extractor.sh --force /path/to/flac/files
   ```

3. **Extract and Move for Lidarr:**
   ```sh
   ./flac-extractor.sh --cat lidarr --importFolder /path/to/lidarr/library /path/to/flac/files
   ```

## Sample Output

Here is an example of how the script output might look during execution:

```sh
[flac extractor]
- Scanning: /path/to/flac/files/ExampleAlbum
===============================
- Extracting: ExampleAlbum
- Tagging split files...
- Removing original flac
- Done!
===============================
- Exiting!
```

## Example using qbittorrent

![image](https://github.com/user-attachments/assets/4bc4d1d6-7be0-4cb6-9645-e2750bc3a81f)


## Contributing

Contributions are welcome! Feel free to open an issue or submit a pull request.

## License

This script is licensed under the MIT License.
