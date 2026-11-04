#!/bin/bash
if [[ "${DEBUG_SPIN:-0}" == "1" ]]; then
  echo "debug spin enabled" >&2
  while true; do
    :
  done
fi
exec sleep infinity
