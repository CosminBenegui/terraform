# Ticket INC-2408 — Intranet shows code instead of the status page

Company: Harborline Logistics
Host: this Ubuntu server
Time box: 20 minutes

## Report

Staff open the warehouse status page on port 8081. Since a hardening pass this morning, browsers show the PHP source. Security treats source disclosure as an incident. The health URL used by monitoring is also wrong.

The site must stay on this host. Document root stays `/var/www/intranet`. ServerName stays `intranet.lab.local`. Port stays 8081.

## What "fixed" means

- `curl -fsS http://127.0.0.1:8081/health.php` prints `ok`.
- That response does not contain PHP source.
- `/var/www/intranet/config.ini` is readable by the web server user `www-data`.
- `config.ini` is not readable by other users on the system.

## Constraints

- Do not move the site to another port or another web server.
- Do not make `config.ini` world-readable to "just get it working".
- `index.php` is the directory index. You do not need a database for this ticket.

A hosts entry for `intranet.lab.local` may already point at loopback. The check above uses the IP and the port.
