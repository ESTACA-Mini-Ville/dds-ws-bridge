#!/usr/bin/env bash

# avoid mesg warning on non-interactive shells
mesg n 2>/dev/null || true

cd /root

if [ -f /is-workspace/install/setup.bash ]; then
  # shellcheck disable=SC1091
  . /is-workspace/install/setup.bash
else
  echo "/is-workspace/install/setup.bash not found"
fi

integration-service ./dds_to_ws.yaml