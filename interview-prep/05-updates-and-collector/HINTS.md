# Hints

## Level 1

`systemctl status acme-collector` and `journalctl -u acme-collector -n 30 --no-pager`. Then `systemctl is-enabled acme-collector`. For updates, `apt-config dump APT::Periodic::Unattended-Upgrade` and `ls /etc/apt/apt.conf.d`.

## Level 2

The unit reaches `ExecStart`. The failure is the write to the heartbeat path, which is a directory ownership problem for user `collector`. `enable` and `start` are separate systemd operations. Apt drop-in files are applied in lexical order. `99*` overrides `20auto-upgrades`.

## Level 3 — answer

`chown collector:collector /var/lib/acme-collector` and give that user write access (`750` is enough). `systemctl enable --now acme-collector`. Delete `/etc/apt/apt.conf.d/99lab-freeze.conf` or set both periodic values back to `"1"`. Confirm with `apt-config dump`, not by reading only `20auto-upgrades`.
