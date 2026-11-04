#!/bin/bash
# SPOILER: this script is the outage. Do not read it until the case is finished.

source "$(dirname "$(readlink -f "$0")")/../lib/common.sh"
need_root
need_ubuntu

LAB="$(dirname "$(readlink -f "$0")")"

getent group webdev >/dev/null || groupadd webdev
getent group logaudit >/dev/null || groupadd logaudit
id deploy >/dev/null 2>&1 || useradd --create-home --shell /bin/bash deploy
id auditor >/dev/null 2>&1 || useradd --create-home --shell /bin/bash auditor
id vendor_acme >/dev/null 2>&1 || useradd --create-home --shell /bin/bash vendor_acme

usermod --shell /bin/bash vendor_acme
chage -E -1 vendor_acme
gpasswd -d deploy webdev >/dev/null 2>&1 || true
usermod -aG sudo auditor

install -d -m 0755 -o root -g root /srv/webapp/releases
install -d -m 0755 /var/log/company /root/lab-keys
printf '%s\n' '2026-11-03T02:00:00Z backup=ok' > /var/log/company/audit.log
chown root:root /var/log/company/audit.log
chmod 0600 /var/log/company/audit.log

install -m 0755 "${LAB}/files/nightly-deploy.sh" /usr/local/bin/nightly-deploy.sh
chmod 0777 /usr/local/bin/nightly-deploy.sh

printf '%s\n' 'vendor_acme ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/vendor-acme
chmod 0440 /etc/sudoers.d/vendor-acme
visudo -cf /etc/sudoers.d/vendor-acme >/dev/null

rm -f /root/lab-keys/vendor_acme /root/lab-keys/vendor_acme.pub
ssh-keygen -t ed25519 -f /root/lab-keys/vendor_acme -N '' -C 'vendor_acme-contract' >/dev/null
install -d -m 0700 -o vendor_acme -g vendor_acme /home/vendor_acme/.ssh
install -m 0600 -o vendor_acme -g vendor_acme /root/lab-keys/vendor_acme.pub /home/vendor_acme/.ssh/authorized_keys
chmod 0700 /root/lab-keys

if sudo -u deploy test -w /srv/webapp/releases; then
  die "Expected deploy to be unable to write the release directory."
fi

echo
echo "Lab 04 is broken on purpose."
echo "Read interview-prep/04-access-control/CASE.md"
echo "Check with: sudo bash interview-prep/04-access-control/verify.sh"
