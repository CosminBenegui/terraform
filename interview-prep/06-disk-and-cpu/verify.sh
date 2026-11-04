#!/bin/bash
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"
need_root
need_ubuntu

if pgrep -f /usr/local/sbin/acme-debug-load.sh >/dev/null; then
  fail "acme-debug-load.sh is still running"
else
  pass "debug load process is not running"
fi

enabled="$(systemctl is-enabled acme-debug-load.service 2>/dev/null || true)"
case "$enabled" in
  disabled|masked|not-found)
    pass "debug load service will not start on boot (${enabled})"
    ;;
  *)
    fail "acme-debug-load is ${enabled:-unknown}. Disable it so it does not return on boot"
    ;;
esac

if [[ -f /etc/logrotate.d/acme-metrics ]] && logrotate -d /etc/logrotate.d/acme-metrics >/dev/null 2>&1; then
  pass "logrotate accepts /etc/logrotate.d/acme-metrics"
else
  fail "logrotate -d /etc/logrotate.d/acme-metrics failed"
fi

policy="$(cat /etc/logrotate.d/acme-metrics 2>/dev/null || true)"
if [[ "$policy" == *daily* && "$policy" == *compress* && "$policy" == */var/log/acme/metrics.log* ]]; then
  pass "policy rotates /var/log/acme/metrics.log daily and compresses"
else
  fail "policy must mention /var/log/acme/metrics.log, daily, and compress"
fi

if [[ -f /var/log/acme/metrics.log ]]; then
  size="$(stat -c %s /var/log/acme/metrics.log)"
  if [[ "$size" -lt 20000000 ]]; then
    pass "metrics.log is ${size} bytes"
  else
    fail "metrics.log is ${size} bytes. Reclaim it to under 20 MB after rotation works"
  fi
else
  fail "metrics.log is missing. Rotate it; do not delete the path the cron job writes"
fi

if [[ -f /etc/cron.d/acme-metrics ]] && grep -q '/usr/local/sbin/acme-metrics.sh' /etc/cron.d/acme-metrics; then
  pass "metrics cron job is still installed"
else
  fail "metrics cron job is missing"
fi

finish
