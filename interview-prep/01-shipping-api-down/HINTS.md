# Hints — open only after you have read the journal

## Level 1

`systemctl status shipping-api` and `journalctl -u shipping-api -n 50 --no-pager` are the whole starting point. The unit file is `/etc/systemd/system/shipping-api.service`. The old file in `/var/log/shipping/` is not why the process is down.

## Level 2

systemd reports the user problem before it reports anything else. After that user exists, start the service again. The next error is about an environment file path that is not on disk. Same directory, different name.

## Level 3 — answer

Create the `shipping` system user and group named in the unit. Restore `/etc/shipping/api.env` from `/etc/shipping/api.env.bak` (the file already contains `API_BIND` and `API_TOKEN`). `daemon-reload` is only required if you edited the unit. `systemctl start shipping-api`, then curl the health URL. Keep the bind address on loopback.
