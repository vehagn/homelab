#!/bin/bash

set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <CHUNK_SIZE>"
  echo "       Reads URLs from ./adblock_urls.txt (must be in current directory)." >&2
  echo "       Outputs chunk files to ./processed_adblock_chunks/" >&2
  exit 1
fi

CHUNK_SIZE="$1"
URL_SOURCE_FILE="./adblock_urls.txt"
OUTPUT_DIR="./processed_adblock_chunks"
MAX_TOTAL_DOMAINS=100000

if ! [[ "$CHUNK_SIZE" =~ ^[0-9]+$ ]] || [ "$CHUNK_SIZE" -lt 1 ]; then
  echo "Error: Chunk size must be a positive integer." >&2
  exit 1
fi

if [ ! -f "$URL_SOURCE_FILE" ]; then
  echo "Error: URL source file not found at $URL_SOURCE_FILE." >&2
  exit 1
fi

URLS=()
while IFS= read -r line || [[ -n "$line" ]]; do
    # Remove comments and skip empty lines
    processed_line=$(echo "$line" | sed -e 's/#.*//' | xargs) # Remove # and onwards, then trim
    if [ -n "$processed_line" ]; then
        URLS+=("$processed_line")
    fi
done < "$URL_SOURCE_FILE"

if [ ${#URLS[@]} -eq 0 ]; then
  echo "No valid URLs found in $URL_SOURCE_FILE. Creating empty $OUTPUT_DIR and exiting." >&2
  mkdir -p "$OUTPUT_DIR"
  exit 0
fi

mkdir -p "$OUTPUT_DIR"
echo "Output directory: $OUTPUT_DIR (relative to current directory)" >&2

TMP_MERGED_CONTENT=$(mktemp)
TMP_SORTED_UNIQUE_DOMAINS=$(mktemp)
trap 'rm -f "$TMP_MERGED_CONTENT" "$TMP_SORTED_UNIQUE_DOMAINS"' EXIT SIGINT SIGTERM ERR

echo "Downloading content from ${#URLS[@]} URLs specified in $URL_SOURCE_FILE..." >&2
for URL in "${URLS[@]}"; do
  # URL should be clean from the while loop processing
  echo "  Downloading: $URL" >&2
  if curl -sSLf "$URL" >> "$TMP_MERGED_CONTENT"; then
    echo >> "$TMP_MERGED_CONTENT"
  else
    echo "  Warning: Failed to download or got an error for URL: $URL. Skipping." >&2
  fi
done

echo "Processing downloaded content (filter, sort, unique)..." >&2
grep -vE "^\s*#|^\s*$" "$TMP_MERGED_CONTENT" | sort -u > "$TMP_SORTED_UNIQUE_DOMAINS"

TOTAL_DOMAINS_COUNT=$(wc -l < "$TMP_SORTED_UNIQUE_DOMAINS" | xargs)
if ! [[ "$TOTAL_DOMAINS_COUNT" =~ ^[0-9]+$ ]]; then
    TOTAL_DOMAINS_COUNT=0
fi
echo "Total unique domains found: $TOTAL_DOMAINS_COUNT" >&2

if [ "$TOTAL_DOMAINS_COUNT" -gt "$MAX_TOTAL_DOMAINS" ]; then
  echo "Error: Total unique domains ($TOTAL_DOMAINS_COUNT) exceeds limit of $MAX_TOTAL_DOMAINS." >&2
  exit 1
fi

if [ "$TOTAL_DOMAINS_COUNT" -eq 0 ]; then
    echo "No valid domains found after filtering. No chunk files will be created in $OUTPUT_DIR." >&2
    exit 0
fi

echo "Splitting into chunks of $CHUNK_SIZE into $OUTPUT_DIR directory..." >&2
FILE_PREFIX="adblock_chunk_"
ORIGINAL_DIR=$(pwd)
cd "$OUTPUT_DIR"
# Split the file. Output files will be in the current directory (which is now OUTPUT_DIR)
# Note: TMP_SORTED_UNIQUE_DOMAINS is an absolute path, so cd doesn't affect finding it.
# Use --additional-suffix to add .txt directly.
split -l "$CHUNK_SIZE" -a 3 -d --additional-suffix=.txt "$TMP_SORTED_UNIQUE_DOMAINS" "$FILE_PREFIX"

cd "$ORIGINAL_DIR" # Now cd back

echo "Chunk files (e.g., ${FILE_PREFIX}000.txt) created in $OUTPUT_DIR:" >&2
# Optional: List the created files if desired for logging
# for f in "$OUTPUT_DIR/${FILE_PREFIX}"*.txt; do
#   if [ -f "$f" ]; then # Check if any files were actually created
#     echo "  $f" >&2
#   fi
# done

echo "Script completed successfully. Chunks are in $OUTPUT_DIR" >&2
exit 0
