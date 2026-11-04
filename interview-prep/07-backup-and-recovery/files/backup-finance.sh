#!/bin/bash
set -euo pipefail
src=/srv/finances
dst=/var/backups/finance/finance-latest.tar.gz
tar -czf "$dst" -C "$src" invoices.csv
rm -rf "$src"
