#!/bin/bash

# Configuration: Default topic name
DEFAULT_TOPIC="topic"

usage() {
    echo "Usage: $0 [options] -- <command>"
    echo ""
    echo "Options:"
    echo "  -h, --help      Show this help message"
    echo "  -t, --title     Set the notification title (Default: Process Complete)"
    echo "  -p, --priority  Set the priority (1-5 or min, low, default, high, max)"
    echo "  -g, --tags      Set notification tags (comma separated)"
    echo "  -m, --message   Override message (Default: The command string)"
    echo "  --topic         Override the default ntfy topic"
    exit 0
}

# ---------------------------------------------------------
# Argument Parsing
# ---------------------------------------------------------
TITLE="Process Complete"
PRIORITY="default"
USER_TAGS=""
CUSTOM_MESSAGE=""
TOPIC="$DEFAULT_TOPIC"

# Extract options before the -- separator
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) usage ;;
        -t|--title) TITLE="$2"; shift ;;
        -p|--priority) PRIORITY="$2"; shift ;;
        -g|--tags) USER_TAGS="$2"; shift ;;
        -m|--message) CUSTOM_MESSAGE="$2"; shift ;;
        --topic) TOPIC="$2"; shift ;;
        --) shift; break ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
    shift
done

CMD="$@"

if [ -z "$CMD" ]; then
    echo "Error: No command specified."
    usage
fi

# ---------------------------------------------------------
# The Screen Wrapper Logic
# ---------------------------------------------------------
# Check if we are already inside a screen session named 'ntfy_bg'
# If not, relaunch the script inside screen and exit the current shell.
if [ "$NTFY_IN_SCREEN" != "true" ]; then
    # Extract the first word of the command for the screen name
    # e.g., "rsync -av ..." becomes "rsync"
    SHORT_CMD=$(echo "$CMD" | awk '{print $1}' | xargs basename)
    SESSION_NAME="ntfy_${SHORT_CMD}_$(date +%M%S)"
    echo "🚀 Launching command in background screen: $SESSION_NAME"
    echo "You can check progress with: screen -r $SESSION_NAME"
    
    # Relaunch the script with a flag to prevent infinite loops
    export NTFY_IN_SCREEN=true
    screen -d -m -S "$SESSION_NAME" "$0" \
        -t "$TITLE" -p "$PRIORITY" -g "$USER_TAGS" \
        -m "$CUSTOM_MESSAGE" --topic "$TOPIC" -- $CMD
    
    exit 0
fi

# ---------------------------------------------------------
# Execution (This part runs INSIDE the screen session)
# ---------------------------------------------------------
$CMD
EXIT_CODE=$?

# Build the message
if [ -n "$CUSTOM_MESSAGE" ]; then
    FINAL_MESSAGE="$CUSTOM_MESSAGE"
else
    FINAL_MESSAGE="Command: $CMD"
fi

# Logic for Tags/Priority
if [ $EXIT_CODE -eq 0 ]; then
    FINAL_MESSAGE="$FINAL_MESSAGE (Status: Success)"
    TAGS="${USER_TAGS:-white_check_mark}"
else
    FINAL_MESSAGE="$FINAL_MESSAGE (Status: Failed with exit code $EXIT_CODE)"
    TAGS="${USER_TAGS:-x}"
    [ "$PRIORITY" == "default" ] && PRIORITY="high"
fi

# Send notification
curl -s -H "Title: $TITLE" \
     -H "Priority: $PRIORITY" \
     -H "Tags: $TAGS" \
     -d "$FINAL_MESSAGE" \
     "https://ntfy.sh/$TOPIC"

exit $EXIT_CODE

