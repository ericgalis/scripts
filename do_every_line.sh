#!/bin/bash

# Check if the file is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <file>"
  exit 1
fi

FILE="$1"

# Check if the file exists
if [ ! -f "$FILE" ]; then
  echo "Error: File $FILE does not exist."
  exit 1
fi

# Read and execute each line in the file
while IFS= read -r line; do
  # Skip empty lines
  if [ -z "$line" ]; then
    continue
  fi

  # Execute the line
  echo "Executing: $line"
  eval "$line"
done < "$FILE"

