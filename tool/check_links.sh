#!/usr/bin/env bash

set -e

# Serve web on localhost.
superstatic --port 4001 > /dev/null &
FBS_PID=$!

# Wait for superstatic to start.
sleep 4

# Check links.
linkcheck :4001 -e

# Kill the localhost server.
kill ${FBS_PID}
