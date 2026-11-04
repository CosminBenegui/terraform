# Ticket INC-2433 — High load and a growing log

Company: Harborline Logistics
Host: this Ubuntu server
Time box: 20 minutes

## Report

Monitoring paged at lunch. The load average is high, and `/var/log/acme` is much larger than it should be. The metrics job is supposed to keep running. It appends one line a minute via `/etc/cron.d/acme-metrics`. What is not supposed to be running is a debug load generator left over from a test.

This lab will occupy about one CPU until you stop that generator. Do it early so the machine stays usable.

## What "fixed" means

- The debug load process is not running, and its service will not come back on boot.
- `/var/log/acme/metrics.log` is under 20 MB. Reclaim the space. Do not delete the log without a rotation policy.
- `logrotate -d` accepts `/etc/logrotate.d/acme-metrics`.
- The policy rotates that log daily and compresses old copies.
- The cron job that appends metrics is still installed.

## Constraints

- Do not remove `/usr/local/sbin/acme-metrics.sh`.
- `sysstat` is installed (`pidstat`, `iostat`, `mpstat`) if you want it. `top`, `ps`, `df`, and `du` are enough.
- Fix the cause. Killing a process and leaving the unit enabled is not done.
