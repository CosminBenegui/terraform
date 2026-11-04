#!/bin/bash
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"
need_root
need_ubuntu

if id shipping >/dev/null 2>&1; then
  pass "user shipping exists"
else
  fail "user shipping does not exist"
fi

active="$(systemctl is-active shipping-api.service 2>/dev/null || true)"
if [[ "$active" == "active" ]]; then
  pass "shipping-api is active"
else
  fail "shipping-api is ${active:-missing}, expected active"
fi

pid="$(systemctl show -p MainPID --value shipping-api.service 2>/dev/null || true)"
run_user="$(ps -o user= -p "${pid:-0}" 2>/dev/null | awk '{print $1}' || true)"
if [[ "$run_user" == "shipping" ]]; then
  pass "shipping-api runs as user shipping"
else
  fail "shipping-api user is '${run_user:-none}', expected shipping"
fi

listeners="$(ss -H -lnt | awk '{print $4}' | grep -E ':8095$' || true)"
if [[ "$listeners" == "127.0.0.1:8095" ]]; then
  pass "shipping-api listens on 127.0.0.1:8095 only"
else
  fail "expected listener 127.0.0.1:8095, saw: ${listeners:-none}"
fi

if body="$(curl -fsS --max-time 3 http://127.0.0.1:8095/health 2>/dev/null)"; then
  if [[ "$body" == "ok" ]]; then
    pass "health returned ok"
  else
    fail "health returned '${body}', expected ok"
  fi
else
  fail "health URL http://127.0.0.1:8095/health did not succeed"
fi

finish
