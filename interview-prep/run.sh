#!/bin/bash
# Launch a lab break or verify script.
#   sudo bash run.sh 01
#   sudo bash run.sh 01 verify
#   sudo bash run.sh 08 --enable-firewall

set -euo pipefail

ROOT="$(dirname "$(readlink -f "$0")")"

if [[ $# -lt 1 ]]; then
  echo "Usage: sudo bash run.sh <lab-number> [break|verify] [extra args]" >&2
  echo "Labs: 01 02 03 04 05 06 07 08 09" >&2
  exit 1
fi

number="$1"
shift
action="break"
if [[ "${1:-}" == "break" || "${1:-}" == "verify" ]]; then
  action="$1"
  shift
fi

case "$number" in
  01|1) dir="01-shipping-api-down" ;;
  02|2) dir="02-intranet-php" ;;
  03|3) dir="03-mysql-billing" ;;
  04|4) dir="04-access-control" ;;
  05|5) dir="05-updates-and-collector" ;;
  06|6) dir="06-disk-and-cpu" ;;
  07|7) dir="07-backup-and-recovery" ;;
  08|8) dir="08-firewall-status-page" ;;
  09|9) dir="09-hardware-and-software-consulting" ;;
  *)
    echo "Unknown lab: $number" >&2
    exit 1
    ;;
esac

if [[ "$number" == "09" || "$number" == "9" ]]; then
  echo "Lab 09 has no script. Read ${ROOT}/${dir}/CASE.md and write ANSWER.md in that directory."
  exit 0
fi

target="${ROOT}/${dir}/${action}.sh"
[[ -f "$target" ]] || {
  echo "Missing ${target}" >&2
  exit 1
}

exec bash "$target" "$@"
