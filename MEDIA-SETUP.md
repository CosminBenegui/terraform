# Media stack — wire-up

Ansible links the apps after apply. See [PLAN.md](PLAN.md).

Plex sign-in and the Seerr wizard still need a browser once. After that, the playbook adds Radarr and Sonarr to Seerr.

Direct ports stay open. Names below go through Traefik and Authentik:

| Name | Backend |
|---|---|
| https://radarr.lab.home | Radarr |
| https://sonarr.lab.home | Sonarr |
| https://prowlarr.lab.home | Prowlarr |
| https://seerr.lab.home | Seerr |
| https://qbit.lab.home | qBittorrent web UI |
| https://auth.lab.home | Authentik |

Point the client DNS at `192.168.0.120` so `*.lab.home` resolves. VNC stays `192.168.0.120:5900`.

## What the playbook links

- Prowlarr → Radarr at `http://radarr:7878`
- Prowlarr → Sonarr at `http://sonarr:8989`
- Radarr root `/movies`, Sonarr root `/tv`
- Download client `qbittorrent` with password `1234`

## Folders

```bash
mkdir -p ~/media/{movies,tv,downloads}
```


## Still done in the browser

- Plex libraries: `/movies` and `/tv`
- Plex account sign-in. Server URL inside Seerr, if asked: `http://plex:32400`
- Seerr first-run wizard. The next Ansible run then adds Radarr and Sonarr.

