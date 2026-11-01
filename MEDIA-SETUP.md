# Media stack â€” wire-up after apply

Terraform puts **plex**, **prowlarr**, **radarr**, **sonarr**, **seerr** on `media-net-*` so they resolve each other by name.

## 0) Folders on the VM (once)

```bash
mkdir -p ~/media/{movies,tv,downloads}
```

Then push/apply this Terraform.

## 1) Open UIs

| App | URL |
|-----|-----|
| Plex | http://192.168.0.120:32400/web |
| Prowlarr | http://192.168.0.120:9696 |
| Radarr | http://192.168.0.120:7878 |
| Sonarr | http://192.168.0.120:8989 |
| Seerr | http://192.168.0.120:5055 |

## 2) Link Prowlarr â†’ Radarr

1. Radarr â†’ Settings â†’ General â†’ copy **API Key**
2. Prowlarr â†’ Settings â†’ Apps â†’ Add â†’ **Radarr**
3. Prowlarr server: `http://radarr:7878` (not localhost)
4. Paste Radarr API key â†’ Test â†’ Save  
5. Sync indexers if prompted

## 3) Link Prowlarr â†’ Sonarr

Same as above, App = **Sonarr**, URL = `http://sonarr:8989`

## 4) Paths inside Radarr / Sonarr

- Radarr root folder: `/movies`
- Sonarr root folder: `/tv`
- Download client folder (when you add one): `/downloads`

## 5) Plex libraries

- Movies â†’ folder `/movies`
- TV â†’ folder `/tv`

Plex does not need Prowlarr API keys; it just reads the same files Radarr/Sonarr write.

## 6) Link Seerr â†’ Plex / Radarr / Sonarr

1. Open http://192.168.0.120:5055 and finish the setup wizard
2. **Plex**: sign in / connect; if it asks for a server URL use `http://plex:32400`
3. **Radarr**: Settings â†’ Services â†’ Radarr â†’ URL `http://radarr:7878` + Radarr API key
4. **Sonarr**: same with `http://sonarr:8989` + Sonarr API key
5. Test each service â†’ Save

Seerr is the request UI; it tells Radarr/Sonarr what to grab. Plex shows the files afterward.

## Note

Indexer + download client (qBittorrent, etc.) are separate; add a download client later and point Radarr/Sonarr at it on the same Docker network.
