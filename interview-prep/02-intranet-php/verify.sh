#!/bin/bash
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"
need_root
need_ubuntu

config=/var/www/intranet/config.ini
if [[ ! -f "$config" ]]; then
  fail "missing ${config}"
else
  mode="$(stat -c %a "$config")"
  other=$((10#$mode % 10))
  if (( other & 4 )); then
    fail "config.ini mode ${mode} is readable by others"
  else
    pass "config.ini is not world-readable (mode ${mode})"
  fi
  if sudo -u www-data test -r "$config"; then
    pass "www-data can read config.ini"
  else
    fail "www-data cannot read config.ini"
  fi
fi

tmp="$(mktemp)"
code="$(curl -sS --max-time 3 -o "$tmp" -w '%{http_code}' http://127.0.0.1:8081/health.php || true)"
body="$(tr -d '\r' < "$tmp")"
rm -f "$tmp"
trimmed="${body//$'\n'/}"

if [[ "$code" == "200" && "$trimmed" == "ok" ]]; then
  pass "health.php returned ok over HTTP"
else
  fail "health.php HTTP ${code:-none}, body '${trimmed}', expected 200 and ok"
fi

if [[ "$body" == *'<?php'* ]]; then
  fail "HTTP response still contains PHP source"
fi

finish
