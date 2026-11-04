# Hints

## Level 1

Compare three executions of the same file: `php /var/www/intranet/health.php` as root, the same command as `www-data`, and `curl` against Apache. Also `apache2ctl -M` and the intranet error log.

## Level 2

If the HTTP body contains `<?php`, Apache is not executing PHP. Fix the module, reload, and curl again. A 500 with `config unreadable` is the next fault, and it is a file mode / owner problem, not a PHP bug.

## Level 3 — answer

Enable the installed Apache PHP module (`a2enmod php8.x` for whatever version is on the host; Ubuntu 24.04 is php8.3) and reload Apache. Then give `www-data` read access to `config.ini` without granting it to others. `root:www-data` mode `640` satisfies the ticket. `644` does not.
