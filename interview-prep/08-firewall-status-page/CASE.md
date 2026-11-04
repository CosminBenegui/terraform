# Ticket INC-2448 — Office status page is not reachable

Company: Harborline Logistics
Host: this Ubuntu server
Time box: 20 minutes

## Report

The NOC checks `http://<this-host>:8090/health` from another machine on the office LAN. It fails. A curl to `127.0.0.1:8090` on the server itself can still succeed, so "the service is running" is not the same as "the office can reach it".

The page is `harborline-status`. Its bind address is in `/etc/harborline/status.env`.

## What "fixed" means

- The host firewall is active and the default incoming policy is still deny.
- The SSH port you are using stays allowed. Confirm that before you enable or reload the firewall.
- TCP `8090` is allowed.
- TCP `3306` is not allowed. MySQL stays local even if another lab installed it.
- The status process listens beyond loopback, and `curl -fsS http://127.0.0.1:8090/health` prints `ok`.

## Constraints

- This lab enables UFW. The break script does not run until you pass `--enable-firewall`.
- Do not switch the default incoming policy to allow.
- Do not restart `ssh` unless you have a console. You should not need to.

If a DENY rule for 8090 sits above an ALLOW rule, the DENY wins. `ufw status numbered` shows the order.
