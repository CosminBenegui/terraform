#!/bin/bash
# Logic checks that do not install packages or change the host.
# Each failure names what broke.

source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"

assert_ok() {
  local message="$1"
  shift
  if "$@"; then
    pass "$message"
  else
    fail "$message"
  fi
}

assert_fail() {
  local message="$1"
  shift
  if "$@"; then
    fail "$message"
  else
    pass "$message"
  fi
}

ROOT="$(dirname "$(readlink -f "$0")")/.."

cron_ok() {
  awk '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    /=/ { next }
    NF >= 7 && $6 == "root" && index($0, "/usr/local/sbin/backup-finance.sh") { found=1 }
    END { exit found ? 0 : 1 }
  ' "$1"
}

broken_cron="$(mktemp)"
fixed_cron="$(mktemp)"
cp "${ROOT}/07-backup-and-recovery/files/finance-backup.cron" "$broken_cron"
printf '%s\n' '0 2 * * * root /usr/local/sbin/backup-finance.sh' > "$fixed_cron"
assert_fail "broken cron.d line is rejected" cron_ok "$broken_cron"
assert_ok "cron.d line with user root is accepted" cron_ok "$fixed_cron"
rm -f "$broken_cron" "$fixed_cron"

path_matches() {
  printf '%s\n' "$1" | grep -E -q '/srv/finance([^[:alnum:]_]|$)'
}
path_typo() {
  printf '%s\n' "$1" | grep -E -q '/srv/finances([^[:alnum:]_]|$)'
}
assert_ok "path regex matches /srv/finance" path_matches 'src=/srv/finance'
assert_fail "path regex does not match the typo /srv/finances" path_matches 'src=/srv/finances'
assert_ok "typo regex matches /srv/finances" path_typo 'src=/srv/finances'

work="$(mktemp -d)"
printf '%s\n' 'id,customer,amount' '1001,Northwind,1500.00' '1002,Contoso,875.50' > "${work}/invoices.csv"
tar -C "$work" -czf "${work}/good.tar.gz" invoices.csv
: > "${work}/empty.tar.gz"
if tar -tzf "${work}/good.tar.gz" | grep -qx 'invoices.csv'; then
  pass "known-good archive lists invoices.csv"
else
  fail "known-good archive lists invoices.csv"
fi
assert_fail "empty latest archive is not a tar" bash -c 'tar -tzf "$1" >/dev/null 2>&1' bash "${work}/empty.tar.gz"
rm -rf "$work"

logdir="$(mktemp -d)"
touch "${logdir}/metrics.log"
fixed_rotate="$(mktemp)"
{
  echo "${logdir}/metrics.log {"
  grep -v '^/var/log/acme/metrics.log$' "${ROOT}/06-disk-and-cpu/files/acme-metrics.logrotate"
  echo '}'
} > "$fixed_rotate"
broken_local="$(mktemp)"
sed "s|/var/log/acme/metrics.log|${logdir}/metrics.log|" \
  "${ROOT}/06-disk-and-cpu/files/acme-metrics.logrotate" > "$broken_local"
assert_fail "broken logrotate policy is rejected" bash -c 'logrotate -d "$1" >/dev/null 2>&1' bash "$broken_local"
assert_ok "braced logrotate policy is accepted" bash -c 'logrotate -d "$1" >/dev/null 2>&1' bash "$fixed_rotate"
rm -f "$fixed_rotate" "$broken_local"
rm -rf "$logdir"

assert_ok "python lab programs compile" python3 -m py_compile \
  "${ROOT}/01-shipping-api-down/files/shipping-api.py" \
  "${ROOT}/08-firewall-status-page/files/harborline-status.py"

mode=640
other=$((10#$mode % 10))
if (( other & 4 )); then
  fail "mode 640 was treated as world-readable"
else
  pass "mode 640 is not world-readable"
fi
mode=644
other=$((10#$mode % 10))
if (( other & 4 )); then
  pass "mode 644 is world-readable"
else
  fail "mode 644 was not treated as world-readable"
fi

finish
