#!/bin/bash

# fixed_find_duplicates.sh - Simple and reliable duplicate file finder
# Usage: ./fixed_find_duplicates.sh [directory] [pattern] [output_file]

set -euo pipefail

# Default parameters
DIR="${1:-.}"                                    # Default to current directory
PATTERN="${2:-*}"                                # Default to all files
OUTPUT_FILE="${3:-duplicates_$(date +%Y%m%d_%H%M%S).txt}"  # Default output filename

# Check if directory exists
if [[ ! -d "$DIR" ]]; then
    echo "Error: Directory '$DIR' does not exist"
    exit 1
fi

echo "=== Finding Duplicates ==="
echo "Directory: $DIR"
[[ "$PATTERN" != "*" ]] && echo "Pattern: $PATTERN"
echo "Output file: $OUTPUT_FILE"
echo "" | tee "$OUTPUT_FILE"

# Create temp file for hash storage
TEMP_FILE=$(mktemp)
PROCESSED_FILE=$(mktemp)

# Generate hashes (using md5 -r for macOS compatibility)
echo "Generating file hashes..."
if command -v md5sum &> /dev/null; then
    # Linux system
    find "$DIR" -type f -name "$PATTERN" -exec md5sum {} \; | sort > "$TEMP_FILE"
else
    # macOS system
    find "$DIR" -type f -name "$PATTERN" -exec md5 -r {} \; | sort > "$TEMP_FILE"
fi

echo "Finding duplicates..." | tee -a "$OUTPUT_FILE"

# First pass: count occurrences of each hash
awk '{print $1}' "$TEMP_FILE" | sort | uniq -c | awk '$1 > 1 {print $2}' > "$PROCESSED_FILE"

# Second pass: output only the files with duplicate hashes
echo "" | tee -a "$OUTPUT_FILE"
while read -r hash; do
    echo "🔄 Duplicates (hash: $hash):" | tee -a "$OUTPUT_FILE"
    grep "^$hash " "$TEMP_FILE" | while read -r line; do
        # Extract the filename (everything after the hash and a space)
        file=$(echo "$line" | cut -d' ' -f2-)
        echo "   $file" | tee -a "$OUTPUT_FILE"
    done
    echo "" | tee -a "$OUTPUT_FILE"
done < "$PROCESSED_FILE"

# Clean up
rm -f "$TEMP_FILE" "$PROCESSED_FILE"

echo -e "=== Complete ===" | tee -a "$OUTPUT_FILE"
echo "Results saved to: $OUTPUT_FILE"
