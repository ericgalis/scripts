#!/bin/bash

PID=108356
WAIT=120

TOPIC="topic"  # Change to your ntfy.sh topic


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
