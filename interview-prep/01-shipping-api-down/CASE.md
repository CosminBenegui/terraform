# Ticket INC-2401 — Shipping API down after a change window

Company: Harborline Logistics
Host: this Ubuntu server
Time box: 15 minutes

## Report

The warehouse app calls `http://127.0.0.1:8095/health` before it prints labels. Since this morning the health check fails. Dispatch is writing labels by hand.

A config run touched the shipping API. Nobody rebooted the machine. Do not reboot it.

## What "fixed" means

- `systemctl` shows `shipping-api` active (running).
- `curl -fsS http://127.0.0.1:8095/health` prints `ok`.
- The process listens on `127.0.0.1:8095` only. Do not publish it on all interfaces.

## Constraints

- Leave the unit name `shipping-api.service`.
- The API token and bind address that the application expects are already on the server. Find them. Do not invent a new token.
- Do not disable SSH, sudo, or the firewall rules for other labs.

## Where to look

The service name is `shipping-api`. Old log lines under `/var/log/shipping/` are from a database migration last month. Confirm they are unrelated before you spend time on them.
