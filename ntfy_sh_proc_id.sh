#!/bin/bash

# 1. Source the environment file
ENV_FILE="$HOME/scripts/default.env"

if [ -f "$ENV_FILE" ]; then
    # Source the file, ignoring lines that are comments
    export $(grep -v '^#' "$ENV_FILE" | xargs)
else
    echo "Warning: $ENV_FILE not found. Using script defaults."
fi

# 2. Configuration: Default topic name (Fallback if not in .env)
# Uses the env variable if present, otherwise defaults to your specific topic
TOPIC="${DEFAULT_TOPIC:-defaulttopic}"

PID=108356
WAIT=120

# Wait for the process to finish
echo "Watching PID $PID..."
while kill -0 $PID 2>/dev/null; do
    sleep $WAIT
done

# Send notification
curl -s \
  -H "Title: Process Complete" \
  -H "Priority: default" \
  -H "Tags: white_check_mark" \
  -d "Process $PID has finished on $(hostname)" \
  ntfy.sh/$TOPIC
