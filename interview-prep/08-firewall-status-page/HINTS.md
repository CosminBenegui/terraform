# Hints

## Level 1

`ss -lnt` for port 8090 and `ufw status verbose`. Compare a curl to `127.0.0.1` with a connection aimed at the host's LAN address. Read `/etc/harborline/status.env` and the unit file.

## Level 2

A process bound to `127.0.0.1` never accepts a packet that arrived on the office NIC, even if the firewall allows the port. Fix the bind and the firewall rule. Leave the default incoming policy as deny, and do not add 3306.

## Level 3 — answer

Set `BIND_HOST=0.0.0.0` (or the LAN address) and restart `harborline-status`. Delete the `8090` DENY rule and `ufw allow 8090/tcp`. Keep the SSH allow rule. Confirm `ufw status verbose` still says `Default: deny (incoming)` and that `8090/tcp` ALLOW is the rule that matches, with no earlier DENY.
