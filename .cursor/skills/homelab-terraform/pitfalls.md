# Pitfalls

Each line is a failure already seen on this lab and the fix that has to stay in the repo.

| Symptom | Fix that must stay |
|---|---|
| Ansible YAML error on `Status: active` | Quote the whole `when` in `ansible/roles/firewall/tasks/main.yml`. |
| `ghcr.io/goauthentik/server:latest` 404 | Pin `2026.8.5` via `authentik_image`. |
| Radarr `Prowlarr URL is invalid` | `prowlarrUrl` `http://prowlarr:9696`, base URL `http://radarr:7878` (Sonarr `http://sonarr:8989`). |
| Postgres crash, data in `/var/lib/postgresql/data` | Mount `authentik-db:/var/lib/postgresql`. Run `postgres_volume.py` when the old mount remains. |
| Browser sent to `http://localhost/application/o/authorize/` | Outpost `authentik_host` and `authentik_host_browser` = `https://auth.lab.home`. Assigning a field sticks only if the whole `config` object is reassigned and saved. |
| A lab name 404s after Ansible rewrites Traefik config | Traefik mounts the config directory, not individual files. |
| Pool delete says the directory is not empty | The Windows ISO is still in `/var/lib/libvirt/images`. Move it back to Downloads before destroy. |
| `*.lab.home` does not resolve on a client | Client DNS is the router. Query `dig @192.168.0.179`. Do not treat Traefik or fstab as the resolver. |
| Browser warns that the lab certificate is untrusted | Trust `/var/lib/lab/certs/lab-ca.crt`. The leaf must keep `DNS:*.lab.home` and `IP:192.168.0.120`. Do not replace the key on every apply. |
| Destroy skipped | `confirm` was not exactly `destroy`. |
| `secrets.env: permission denied` | Ansible writes that file as root (`become` and `umask 077`). Keep `owner: cosmin` and mode `0600`. The plan workflow chowns it before `terraform plan`. |
| Authentik stays on "Server is starting up" | Mount `/dev/shm` as a tmpfs with no size option on the server and the worker. Do not set `shm_size` or a memory limit. Docker's 64 MB `/dev/shm` leaves both containers unhealthy. |

Direct checks that do not need DNS: `http://192.168.0.120:7878` Radarr, `:8989` Sonarr, `:9696` Prowlarr, `:5055` Seerr, `:8080` qBittorrent, `:32400/web` Plex, `:61208` Glances, `:9000` Authentik. Named HTTPS URLs need a client that resolves `lab.home`.
