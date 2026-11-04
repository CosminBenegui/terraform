# Hints

## Level 1

`id deploy`, `id auditor`, `namei -l /srv/webapp/releases`, `sudo -l -U vendor_acme`, and `ls -l /home/vendor_acme/.ssh /usr/local/bin/nightly-deploy.sh /etc/sudoers.d`. A directory can be writable by a group only when the user is in that group.

## Level 2

New files inherit the directory's group when the setgid bit is on (`2` in the special mode digit, for example `2775`). Locking a password with `usermod -L` does not stop public-key SSH. Sudo from a file under `/etc/sudoers.d` is separate from the `sudo` group.

## Level 3 — answer

`chown root:webdev /srv/webapp/releases`, `chmod 2775` that directory, and `usermod -aG webdev deploy`. Delete `/etc/sudoers.d/vendor-acme` and `/home/vendor_acme/.ssh/authorized_keys`. Then `usermod --shell /usr/sbin/nologin vendor_acme` or `chage -E 1 vendor_acme`. Remove `auditor` from group `sudo`, put `auditor` in a log group, and set the log to `640` owned by that group. `chmod 755 /usr/local/bin/nightly-deploy.sh` (or `750`).
