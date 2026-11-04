# Hints

## Level 1

`top` or `pidstat -u 1 3`, then `systemctl status` on the unit that owns the busy process. Separately `du -sh /var/log/acme` and `logrotate -d /etc/logrotate.d/acme-metrics`.

## Level 2

The load is a service with `Restart=always`. `systemctl disable --now` is the durable fix. The log policy file is missing the block braces logrotate requires, so the large file will never rotate until that file parses.

## Level 3 — answer

`systemctl disable --now acme-debug-load`. Put braces around the directives in `/etc/logrotate.d/acme-metrics`, keep `daily` and `compress`, then `logrotate --force /etc/logrotate.d/acme-metrics` (or truncate only after the policy is valid). Leave `/etc/cron.d/acme-metrics` in place.
