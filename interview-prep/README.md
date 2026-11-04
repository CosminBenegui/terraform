# Harborline Logistics — Linux interview labs

Practice cases for an Ubuntu 24.04 homelab. They follow a normal internal-IT day: a ticket, a broken service, and a definition of done.

Each lab installs real packages, then leaves them broken on purpose. You repair the host. Nothing here prints the fix.

## Do not spoil the case

Open only `CASE.md` before you start. `HINTS.md` is optional and gets more explicit at each level. `break.sh` is the outage. Reading it tells you the answer.

## Safety

Run these on the homelab, not on a machine you cannot afford to change.

- The scripts never edit your sudoers entry, SSH server config, netplan, or `/etc/fstab`.
- Lab 08 is the exception to "just run it": it turns on UFW. It allows the current SSH port first, and it refuses to run until you pass `--enable-firewall`.
- Re-running `break.sh` puts that lab back into the broken state.
- There is no undo script. That would be the answer key.

## Priority if you only have one evening

1. `01-shipping-api-down` — systemd, users, logs
2. `02-intranet-php` — Apache and PHP
3. `03-mysql-billing` — MySQL users and networking
4. `04-access-control` — accounts, sudo, SSH keys, permissions
5. `06-disk-and-cpu` — load, disk, logrotate
6. `05-updates-and-collector` — failed unit plus security updates
7. `07-backup-and-recovery` — restore, cron, written procedures
8. `08-firewall-status-page` — listening address and UFW
9. `09-hardware-and-software-consulting` — talk this one out loud, no breakage

## Run a lab

From this directory:

```bash
sudo bash run.sh 01
sudo bash 01-shipping-api-down/verify.sh
```

Or call the scripts directly:

```bash
sudo bash 02-intranet-php/break.sh
sudo bash 02-intranet-php/verify.sh
```

Lab 08 turns the firewall on. The script prints the SSH ports it will allow, then blocks 8090:

```bash
sudo bash run.sh 08 --enable-firewall
sudo bash 08-firewall-status-page/verify.sh
```

`verify.sh` prints `PASS` or `FAIL` with a message. It checks the outcome. It does not change the system, except lab 07, which runs your backup script after it is safe.

## How to work a ticket

Say this sequence out loud. It is the interview.

1. Read the impact and the constraints before changing anything.
2. Confirm the symptom yourself.
3. Read the service status and the journal. Then look at config and permissions.
4. Change one thing, then test again.
5. Stop when the definition of done is true, including the security constraints.
6. Say what you would hand to the next admin.

Toolbox that is enough for these cases: `systemctl`, `journalctl`, `ss`, `curl`, `apache2ctl`, `mysql`, `ufw`, `logrotate`, `namei -l`, `id`, `stat`, `visudo -c`, `apt-config dump`, `df`, `du`, `top` or `pidstat`, `tar`, `crontab` layout under `/etc/cron.d`.

## Company

Harborline Logistics, internal IT. Office apps on one Ubuntu server: intranet, billing reads, a shipping API, and night jobs. You are the sysadmin on call. Vendors do not get standing root access.
