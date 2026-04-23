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
TOPIC="${DEFAULT_TOPIC:-topic}"

# 3. Handle Arguments
# Argument 1: PID (Required)
# Argument 2: Wait interval in seconds (Optional, defaults to 60)
PID=$1
WAIT=${2:-60}

if [ -z "$PID" ]; then
    echo "Usage: $0 <PID> [wait_interval_seconds]"
    exit 1
fi

# 4. The Screen Wrapper Logic
# This allows you to run ntfy-watch 1234 and immediately get your prompt back.
if [ "$NTFY_IN_SCREEN" != "true" ]; then
    # Get process name for the screen label
    PROC_NAME=$(ps -p "$PID" -o comm= 2>/dev/null || echo "pid")
    SESSION_NAME="watch_${PROC_NAME}_${PID}"
    
    echo "🚀 Watching PID $PID in background screen: $SESSION_NAME"
    
    export NTFY_IN_SCREEN=true
    screen -d -m -S "$SESSION_NAME" "$0" "$PID" "$WAIT"
    exit 0
fi

# ---------------------------------------------------------
# Execution (Inside Screen)
# ---------------------------------------------------------

# Try to capture the command string before the process finishes
CMD_INFO=$(ps -p "$PID" -o args= 2>/dev/null)

# Wait for the process to finish
while kill -0 "$PID" 2>/dev/null; do
    sleep "$WAIT"
done

# Prepare notification details
MSG="Process $PID ($CMD_INFO) has finished on $(hostname)"

# Send notification
curl -s \
  -H "Title: Process Complete" \
  -H "Priority: default" \
  -H "Tags: white_check_mark" \
  -d "$MSG" \
  "ntfy.sh/$TOPIC"