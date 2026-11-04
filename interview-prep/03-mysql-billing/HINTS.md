# Hints

## Level 1

Read `/etc/billing/db.env`. Try the client the same way the vendor connects (TCP, that host, that user). Then try a socket login as the admin user so you know whether the server process itself is up. `ss` on port 3306 and files under `/etc/mysql/mysql.conf.d/` matter.

## Level 2

`skip-networking` and a user account are separate faults. MySQL treats `localhost` and `127.0.0.1` as different accounts. The error "Can't connect" and the error "Access denied" are not the same problem.

## Level 3 — answer

Remove the `skip-networking` drop-in and restart MySQL. Keep `bind-address` on `127.0.0.1` (the packaged default). Create `'billing_app'@'127.0.0.1'` with the password already in `db.env` and `GRANT SELECT ON billing.*`. Do not reuse the `localhost` account: TCP will not match it. Leave `DB_HOST` as `127.0.0.1`.
