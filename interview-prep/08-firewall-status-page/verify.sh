#!/bin/bash
source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"
# shellcheck disable=SC1091
source "$(dirname "$(readlink -f "$0")")/files/ssh-ports.sh"
need_root
need_ubuntu

ufw_action() {
  local port="$1"
  ufw status | awk -v port="${port}/tcp" '
    $1 == port {
      action = $2
      if ($2 == "(v6)") {
        action = $3
      }
      print action
      exit
    }
  '
}

if ufw status | grep -q '^Status: active'; then
  pass "UFW is active"
else
  fail "UFW is not active"
fi

if ufw status verbose | grep -q 'Default: deny (incoming)'; then
  pass "default incoming policy is deny"
else
  fail "default incoming policy must stay deny"
fi

while read -r port; do
  action="$(ufw_action "$port")"
  if [[ "$action" == "ALLOW" ]]; then
    pass "SSH port ${port}/tcp is allowed"
  else
    fail "SSH port ${port}/tcp is '${action:-not listed}'. Allow it before you disconnect"
  fi
done < <(lab_ssh_ports)

action_8090="$(ufw_action 8090)"
if [[ "$action_8090" == "ALLOW" ]]; then
  pass "8090/tcp is allowed and is the first matching rule"
else
  fail "first 8090/tcp rule is '${action_8090:-missing}', expected ALLOW"
fi

if [[ -n "$(ufw_action 3306)" && "$(ufw_action 3306)" == "ALLOW" ]]; then
  fail "3306/tcp must not be allowed through the firewall"
else
  pass "3306/tcp is not allowed"
fi

listeners="$(ss -H -lnt | awk '{print $4}' | grep -E ':8090$' || true)"
if echo "$listeners" | grep -Ev '^(127\.0\.0\.1|\[::1\]):8090$' | grep -q .; then
  pass "status page listens beyond loopback (${listeners//$'\n'/, })"
else
  fail "status page is loopback-only (${listeners:-not listening})"
fi

if body="$(curl -fsS --max-time 3 http://127.0.0.1:8090/health 2>/dev/null)"; then
  if [[ "$body" == "ok" ]]; then
    pass "local health returned ok"
  else
    fail "local health returned '${body}', expected ok"
  fi
else
  fail "curl http://127.0.0.1:8090/health failed"
fi

finish
