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
| Destroy skipped | `confirm` was not exactly `destroy`. |

Direct checks that do not need DNS: `http://192.168.0.120:7878` Radarr, `:8989` Sonarr, `:9696` Prowlarr, `:5055` Seerr, `:8080` qBittorrent, `:32400/web` Plex, `:61208` Glances, `:9000` Authentik. Named HTTPS URLs need a client that resolves `lab.home`.
