#!/bin/bash

# Directory containing the markdown files
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONTENT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/content"

# Flag to track validation failures
validation_failed=0

# Use process substitution instead of a pipe to avoid the subshell issue
while read -r file; do
    # Read the first line of the file
    first_line=$(head -n 1 "$file")
    
    # Trim whitespace and check if the first line is exactly "+++"
    trimmed_line=$(echo "$first_line" | tr -d '[:space:]')
    if [[ "$trimmed_line" != "+++" ]]; then
        echo -e "Validation failed: $file does not start with +++"
        echo -e "First line content: '$trimmed_line'"
        validation_failed=1
    fi
done < <(find "$CONTENT_DIR" -type f -name "*.md")

# Return error code if validation failed, otherwise return "ok"
if [ $validation_failed -eq 1 ]; then
    echo "error"
    exit 1
else
    echo "content is ok"
    exit 0
fi