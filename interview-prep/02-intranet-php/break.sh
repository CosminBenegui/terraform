#!/bin/bash
# SPOILER: this script is the outage. Do not read it until the case is finished.

source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"
need_root
need_ubuntu

LAB="$(dirname "$(readlink -f "$0")")"
apt_install apache2 libapache2-mod-php php-cli curl

install -d -m 0755 /var/www/intranet
install -m 0644 "${LAB}/files/index.php" /var/www/intranet/index.php
install -m 0644 "${LAB}/files/health.php" /var/www/intranet/health.php
install -m 0644 "${LAB}/files/config.ini" /var/www/intranet/config.ini
install -m 0644 "${LAB}/files/intranet.conf" /etc/apache2/sites-available/intranet.conf

if ! grep -qE '^[[:space:]]*Listen[[:space:]]+8081([[:space:]]|$)' /etc/apache2/ports.conf; then
  printf '\nListen 8081\n' >> /etc/apache2/ports.conf
fi
if ! grep -q 'intranet.lab.local' /etc/hosts; then
  printf '127.0.0.1 intranet.lab.local\n' >> /etc/hosts
fi

a2ensite intranet.conf >/dev/null
apache2ctl configtest
systemctl reload apache2

php_mod="$(a2query -m | awk '/^php[0-9.]+ / && /enabled/ {print $1; exit}')"
if [[ -z "$php_mod" ]]; then
  php_mod="$(find /etc/apache2/mods-available -maxdepth 1 -name 'php*.load' -printf '%f\n' | sed 's/\.load$//' | sort -V | tail -1)"
fi
[[ -n "$php_mod" ]] || die "No Apache PHP module was installed."
a2dismod "$php_mod" >/dev/null
chown root:root /var/www/intranet/config.ini
chmod 0600 /var/www/intranet/config.ini
systemctl reload apache2

body="$(curl -sS --max-time 3 http://127.0.0.1:8081/health.php || true)"
if [[ "$body" == "ok" ]]; then
  die "Expected health.php to be broken, but it returned ok."
fi

echo
echo "Lab 02 is broken on purpose."
echo "Read interview-prep/02-intranet-php/CASE.md"
echo "Check with: sudo bash interview-prep/02-intranet-php/verify.sh"
