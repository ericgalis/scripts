#!/bin/bash

# 1. Source the environment file
ENV_FILE="$HOME/scripts/default.env"
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
fi

DEFAULT_TOPIC="${DEFAULT_TOPIC:-prezericlaptop1106}"

usage() {
    echo "Usage: $0 [options] -- <command>"
    echo "Options:"
    echo "  -h, --help      Show this help message"
    echo "  -t, --title     Set notification title"
    echo "  --topic         Override ntfy topic"
    exit 0
}

# ---------------------------------------------------------
# Argument Parsing
# ---------------------------------------------------------
TITLE="Process Complete"
TOPIC="$DEFAULT_TOPIC"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) usage ;;
        -t|--title) TITLE="$2"; shift ;;
        --topic) TOPIC="$2"; shift ;;
        --) shift; break ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
    shift
done

CMD="$@"
[ -z "$CMD" ] && usage

# ---------------------------------------------------------
# The Screen Wrapper Logic
# ---------------------------------------------------------
if [ "$NTFY_IN_SCREEN" != "true" ]; then
    SHORT_CMD=$(echo "$CMD" | awk '{print $1}' | xargs basename)
    SESSION_NAME="ntfy_${SHORT_CMD}_$(date +%M%S)" 
    
    echo "🚀 Launching background screen: $SESSION_NAME"
    echo "The screen session will remain open for review after completion."
    
    export NTFY_IN_SCREEN=true
    
    # NEW LOGIC: We wrap the command and notification in a subshell 
    # and tell screen to run a shell after that subshell finishes.
    screen -d -m -S "$SESSION_NAME" bash -c "$0 -t '$TITLE' --topic '$TOPIC' -- $CMD; exec bash"
    
    exit 0
fi

# ---------------------------------------------------------
# Execution (Inside Screen)
# ---------------------------------------------------------
# Run the actual command
eval "$CMD"
EXIT_CODE=$?

# Logic for Tags/Priority
if [ $EXIT_CODE -eq 0 ]; then
    STATUS="Success"
    TAGS="white_check_mark"
else
    STATUS="Failed (Code: $EXIT_CODE)"
    TAGS="x"
fi

# Send notification
curl -s -H "Title: $TITLE" \
     -H "Tags: $TAGS" \
     -d "Command: $CMD (Status: $STATUS)" \
     "https://ntfy.sh/$TOPIC"

# Final output to the screen terminal so you see it when you reattach
echo "------------------------------------------------"
echo "Process finished with exit code: $EXIT_CODE"
echo "Notification sent to ntfy.sh/$TOPIC"
echo "This screen session is staying open for your review."
echo "Type 'exit' to close this session."
echo "------------------------------------------------"

exit $EXIT_CODE