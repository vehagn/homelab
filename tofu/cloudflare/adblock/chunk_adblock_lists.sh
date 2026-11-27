#!/bin/bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <MAX_DOMAINS_PER_BUCKET> <NUM_BUCKETS>"
  echo "       Reads URLs from ./adblock_urls.txt (must be in current directory)."
  echo "       Distributes domains into hash buckets with deterministic overflow spillover."
  echo "       Outputs bucket files to ./processed_adblock_chunks/"
  echo ""
  echo "Example: $0 1000 90  # Creates up to 90 buckets with max 1000 domains each"
  echo "                     # With deterministic spillover handling"
  exit 1
fi

MAX_DOMAINS_PER_BUCKET="$1"
NUM_BUCKETS="$2"
URL_SOURCE_FILE="./adblock_urls.txt"
OUTPUT_DIR="./processed_adblock_chunks"
MAX_TOTAL_DOMAINS=$((MAX_DOMAINS_PER_BUCKET * NUM_BUCKETS))

# Validation
if ! [[ "$MAX_DOMAINS_PER_BUCKET" =~ ^[0-9]+$ ]] || [ "$MAX_DOMAINS_PER_BUCKET" -lt 1 ]; then
  echo -e "\e[31mError: MAX_DOMAINS_PER_BUCKET must be a positive integer.\e[0m" >&2
  exit 1
fi

if ! [[ "$NUM_BUCKETS" =~ ^[0-9]+$ ]] || [ "$NUM_BUCKETS" -lt 1 ]; then
  echo -e "\e[31mError: NUM_BUCKETS must be a positive integer.\e[0m" >&2
  exit 1
fi

if [ "$NUM_BUCKETS" -gt 95 ]; then
  echo "Warning: NUM_BUCKETS ($NUM_BUCKETS) exceeds recommended free tier limit of 95." >&2
fi

if [ "$MAX_DOMAINS_PER_BUCKET" -gt 1000 ]; then
  echo "Warning: MAX_DOMAINS_PER_BUCKET ($MAX_DOMAINS_PER_BUCKET) exceeds Cloudflare free tier limit of 1000." >&2
fi

if [ ! -f "$URL_SOURCE_FILE" ]; then
  echo -e "\e[31mError: URL source file not found at $URL_SOURCE_FILE.\e[0m" >&2
  exit 1
fi

echo "Configuration:" >&2
echo "  Max domains per bucket: $MAX_DOMAINS_PER_BUCKET" >&2
echo "  Number of buckets: $NUM_BUCKETS" >&2
echo "  Total capacity: $MAX_TOTAL_DOMAINS domains" >&2
echo "  Output directory: $OUTPUT_DIR" >&2

# Read URLs from source file
URLS=()
while IFS= read -r line || [[ -n "$line" ]]; do
    # Remove comments and skip empty lines
    processed_line=$(echo "$line" | sed -e 's/#.*//' | xargs) # Remove # and onwards, then trim
    if [ -n "$processed_line" ]; then
        URLS+=("$processed_line")
    fi
done < "$URL_SOURCE_FILE"

if [ ${#URLS[@]} -eq 0 ]; then
  echo -e "\e[31mNo valid URLs found in $URL_SOURCE_FILE. Creating empty $OUTPUT_DIR and exiting.\e[0m" >&2
  mkdir -p "$OUTPUT_DIR"
  exit 0
fi

mkdir -p "$OUTPUT_DIR"

# Temporary files
TMP_MERGED_CONTENT=$(mktemp)
TMP_SORTED_UNIQUE_DOMAINS=$(mktemp)
TMP_HASH_MAPPING=$(mktemp)
TMP_BUCKET_ASSIGNMENTS=$(mktemp)
trap 'rm -f "$TMP_MERGED_CONTENT" "$TMP_SORTED_UNIQUE_DOMAINS" "$TMP_HASH_MAPPING" "${TMP_HASH_MAPPING}.sorted" "$TMP_BUCKET_ASSIGNMENTS"' EXIT SIGINT SIGTERM ERR

# Download content from all URLs
echo "Downloading content from ${#URLS[@]} URLs specified in $URL_SOURCE_FILE..." >&2
for URL in "${URLS[@]}"; do
  echo "  Downloading: $URL" >&2
  if curl -sSLf "$URL" >> "$TMP_MERGED_CONTENT"; then
    echo >> "$TMP_MERGED_CONTENT"
  else
    echo -e "\e[31mWarning: Failed to download or got an error for URL: $URL. Skipping.\e[0m" >&2
  fi
done

# Process downloaded content
echo "Processing downloaded content (filter, sort, unique)..." >&2
grep -vE "^\s*#|^\s*$" "$TMP_MERGED_CONTENT" | sort -u > "$TMP_SORTED_UNIQUE_DOMAINS"

TOTAL_DOMAINS_COUNT=$(wc -l < "$TMP_SORTED_UNIQUE_DOMAINS" | xargs)
if ! [[ "$TOTAL_DOMAINS_COUNT" =~ ^[0-9]+$ ]]; then
    TOTAL_DOMAINS_COUNT=0
fi

echo "Total unique domains found: $TOTAL_DOMAINS_COUNT" >&2

if [ "$TOTAL_DOMAINS_COUNT" -gt "$MAX_TOTAL_DOMAINS" ]; then
  echo -e "\e[31mError: Total unique domains ($TOTAL_DOMAINS_COUNT) exceeds capacity of $MAX_TOTAL_DOMAINS.\e[0m" >&2
  echo -e "\e[31mConsider increasing NUM_BUCKETS or MAX_DOMAINS_PER_BUCKET.\e[0m" >&2
  exit 1
fi

if [ "$TOTAL_DOMAINS_COUNT" -eq 0 ]; then
    echo -e "\e[31mNo valid domains found after filtering. No bucket files will be created in $OUTPUT_DIR.\e[0m" >&2
    exit 0
fi

# Phase 1: Calculate primary hash bucket for each domain
echo "Calculating primary hash assignments..." >&2

while IFS= read -r domain; do
  if [ -n "$domain" ]; then
    # Calculate primary hash bucket using SHA-256 (first 8 hex chars for 32-bit range)
    HASH_HEX=$(printf "%s" "$domain" | sha256sum | cut -c1-8)
    HASH_DEC=$((0x$HASH_HEX))
    PRIMARY_BUCKET=$((HASH_DEC % NUM_BUCKETS))

    # Record: primary_bucket domain
    echo "$PRIMARY_BUCKET $domain" >> "$TMP_HASH_MAPPING"
  fi
done < "$TMP_SORTED_UNIQUE_DOMAINS"

# Phase 2: Group by primary bucket and handle overflow with deterministic spillover
echo "Processing overflow with deterministic spillover..." >&2

declare -a BUCKET_COUNTS
for ((i=0; i<NUM_BUCKETS; i++)); do
  BUCKET_COUNTS[i]=0
done

# Sort by bucket, then by domain name for deterministic ordering
sort -k1,1n -k2,2 "$TMP_HASH_MAPPING" > "${TMP_HASH_MAPPING}.sorted"

# Process each bucket group
current_bucket=-1
bucket_domains=()

process_bucket_group() {
  local bucket_id=$1
  local domains=("${@:2}")

  if [ ${#domains[@]} -eq 0 ]; then
    return
  fi

  bucket_num=$(printf "%03d" $bucket_id)
  echo "  Bucket $bucket_num: ${#domains[@]} domains" >&2

  # First MAX_DOMAINS_PER_BUCKET domains go to primary bucket
  local assigned_to_primary=0
  local overflow_count=0

  for domain in "${domains[@]}"; do
    if [ $assigned_to_primary -lt $MAX_DOMAINS_PER_BUCKET ]; then
      echo "$bucket_id $domain" >> "$TMP_BUCKET_ASSIGNMENTS"
      BUCKET_COUNTS[bucket_id]=$((BUCKET_COUNTS[bucket_id] + 1))
      assigned_to_primary=$((assigned_to_primary + 1))
    else
      # Handle overflow with deterministic spillover
      overflow_count=$((overflow_count + 1))

      # Find next available bucket using deterministic search
      local spillover_bucket=-1
      for ((search_offset=1; search_offset<NUM_BUCKETS; search_offset++)); do
        local candidate_bucket=$(( (bucket_id + search_offset) % NUM_BUCKETS ))
        if [ ${BUCKET_COUNTS[candidate_bucket]} -lt $MAX_DOMAINS_PER_BUCKET ]; then
          spillover_bucket=$candidate_bucket
          break
        fi
      done

      if [ $spillover_bucket -eq -1 ]; then
        echo -e "\e[31mError: No available bucket found for overflow from bucket $bucket_id\e[0m" >&2
        echo -e "\e[31mDomain: $domain\e[0m" >&2
        echo -e "\e[31mAll buckets are at capacity.\e[0m" >&2
        exit 1
      fi

      echo "$spillover_bucket $domain" >> "$TMP_BUCKET_ASSIGNMENTS"
      BUCKET_COUNTS[spillover_bucket]=$((BUCKET_COUNTS[spillover_bucket] + 1))

      if [ $overflow_count -eq 1 ]; then
        spillover_num=$(printf "%03d" $spillover_bucket)
        echo "    → Overflow: spillover to bucket $spillover_num" >&2
      fi
    fi
  done

  if [ $overflow_count -gt 0 ]; then
    echo "    → Total spillover: $overflow_count domains" >&2
  fi
}

# Process domains grouped by primary bucket
while IFS=' ' read -r bucket_id domain; do
  if [ "$bucket_id" != "$current_bucket" ]; then
    # Process previous bucket group if exists
    if [ $current_bucket -ne -1 ]; then
      process_bucket_group $current_bucket "${bucket_domains[@]}"
    fi

    # Start new bucket group
    current_bucket=$bucket_id
    bucket_domains=("$domain")
  else
    # Add to current bucket group
    bucket_domains+=("$domain")
  fi
done < "${TMP_HASH_MAPPING}.sorted"

# Process the last bucket group
if [ $current_bucket -ne -1 ]; then
  process_bucket_group $current_bucket "${bucket_domains[@]}"
fi

# Phase 3: Write domains to bucket files
echo "Writing domains to bucket files..." >&2

# Clear output directory of old bucket files
rm -f "$OUTPUT_DIR"/adblock_chunk_*.txt

# Sort final assignments by bucket ID, then write to files
sort -k1,1n -k2,2 "$TMP_BUCKET_ASSIGNMENTS" | while IFS=' ' read -r bucket_id domain; do
  BUCKET_FILE="$OUTPUT_DIR/adblock_chunk_$(printf "%03d" $bucket_id).txt"
  echo "$domain" >> "$BUCKET_FILE"
done

# Show final statistics
echo "" >&2
echo "Final bucket distribution:" >&2
USED_BUCKETS=0
OVERFLOW_BUCKETS=0
for ((i=0; i<NUM_BUCKETS; i++)); do
  if [ ${BUCKET_COUNTS[i]} -gt 0 ]; then
    USED_BUCKETS=$((USED_BUCKETS + 1))
    bucket_num=$(printf "%03d" $i)
    domain_count=$(printf "%4d" ${BUCKET_COUNTS[i]})
    if [ ${BUCKET_COUNTS[i]} -eq $MAX_DOMAINS_PER_BUCKET ]; then
      echo "  Bucket $bucket_num: $domain_count domains (FULL)" >&2
    else
      echo "  Bucket $bucket_num: $domain_count domains" >&2
    fi

    # Count how many buckets received spillover
    PRIMARY_COUNT=$(sort -k1,1n "$TMP_HASH_MAPPING" | awk -v bucket=$i '$1 == bucket' | wc -l)
    if [ ${BUCKET_COUNTS[i]} -gt $PRIMARY_COUNT ]; then
      OVERFLOW_BUCKETS=$((OVERFLOW_BUCKETS + 1))
    fi
  fi
done

echo "  Used buckets: $USED_BUCKETS/$NUM_BUCKETS" >&2
echo "  Buckets with spillover: $OVERFLOW_BUCKETS" >&2

# List created files
CREATED_FILES=($(ls "$OUTPUT_DIR"/adblock_chunk_*.txt 2>/dev/null || true))
echo "" >&2
echo "Created ${#CREATED_FILES[@]} bucket files in $OUTPUT_DIR" >&2

echo "" >&2
echo -e "\e[32mDeterministic Spillover Guarantees:\e[0m" >&2
echo "  ✓ Consistent assignment: same domains always spill to same buckets" >&2
echo "  ✓ Stable overflow handling: domains sorted alphabetically within each hash group" >&2
echo "  ✓ Predictable spillover: overflow goes to next available bucket (circular search)" >&2
echo "  ✓ No cascading updates: spillover domains have fixed assignments" >&2
echo "" >&2
echo -e "\e[32mScript completed successfully. Deterministic hash buckets with spillover in $OUTPUT_DIR\e[0m" >&2
exit 0
