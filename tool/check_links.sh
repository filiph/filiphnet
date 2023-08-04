#!/usr/bin/env bash

# Serve web on localhost.
superstatic --port 4001 . > /dev/null &
FBS_PID=$!

# Wait for superstatic to start.
sleep 4

# Check links.
linkcheck :4001 -e --skip-file tool/check_links_skip_file.txt
LINKCHECK_EXIT_CODE=$?

# Kill the localhost server.
kill ${FBS_PID}

if [ ${LINKCHECK_EXIT_CODE} -eq 1 ]
then
  echo "The linkcheck tool had some warnings. We won't fail the build for that."
  exit 0
else
  exit ${LINKCHECK_EXIT_CODE}
fi
