#!/bin/bash
set -euo pipefail
# shellcheck disable=SC1091
source /etc/acme/collector.env
date -Is > "${HEARTBEAT_PATH}"
exec sleep infinity
