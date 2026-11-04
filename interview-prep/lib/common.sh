#!/bin/bash
# Shared helpers for the Harborline interview labs.
# Source this file. Do not execute it.

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "Source this file from a lab script. Do not execute it." >&2
  exit 1
fi

set -euo pipefail

FAILED=0

die() {
  echo "ERROR: $*" >&2
  exit 1
}

need_root() {
  [[ "${EUID}" -eq 0 ]] || die "Run as root: sudo bash $0 $*"
}

need_ubuntu() {
  [[ -r /etc/os-release ]] || die "Cannot read /etc/os-release"
  # shellcheck disable=SC1091
  source /etc/os-release
  [[ "${ID:-}" == "ubuntu" ]] || die "These labs target Ubuntu. This host is ${ID:-unknown}."
  if [[ "${VERSION_ID:-}" != "24.04" ]]; then
    echo "WARNING: written for Ubuntu 24.04. This host is ${PRETTY_NAME:-unknown}. Continuing with distro package names."
  fi
}

apt_install() {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y "$@"
}

pass() {
  echo "PASS: $*"
}

fail() {
  echo "FAIL: $*" >&2
  FAILED=1
}

finish() {
  if [[ "$FAILED" -ne 0 ]]; then
    echo "Result: not fixed yet."
    exit 1
  fi
  echo "Result: all checks passed."
}
