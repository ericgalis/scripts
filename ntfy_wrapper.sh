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
DEFAULT_TOPIC="${DEFAULT_TOPIC:-defaulttopic}"

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

# Initialize variables
TITLE="Process Complete"
PRIORITY="default"
USER_TAGS=""
CUSTOM_MESSAGE=""
TOPIC="$DEFAULT_TOPIC"

# Parse arguments
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

# Capture the command string
CMD="$@"

if [ -z "$CMD" ]; then
    echo "Error: No command specified."
    usage
fi

# Execute the command
echo "Running: $CMD"
$CMD
EXIT_CODE=$?

# Logic for the message
if [ -n "$CUSTOM_MESSAGE" ]; then
    FINAL_MESSAGE="$CUSTOM_MESSAGE"
else
    FINAL_MESSAGE="Command: $CMD"
fi

# Logic for Tags and Priority based on Exit Code
if [ $EXIT_CODE -eq 0 ]; then
    FINAL_MESSAGE="$FINAL_MESSAGE (Status: Success)"
    # Set default tag to checkmark if user didn't provide one
    TAGS="${USER_TAGS:-white_check_mark}"
else
    FINAL_MESSAGE="$FINAL_MESSAGE (Status: Failed with exit code $EXIT_CODE)"
    # Set default tag to X if user didn't provide one
    TAGS="${USER_TAGS:-x}"
    # Automatically bump priority on failure if not already set to max
    [ "$PRIORITY" == "default" ] && PRIORITY="high"
fi

# Send notification
curl -H "Title: $TITLE" \
     -H "Priority: $PRIORITY" \
     -H "Tags: $TAGS" \
     -d "$FINAL_MESSAGE" \
     "https://ntfy.sh/$TOPIC"

exit $EXIT_CODE

