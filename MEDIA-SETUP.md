# Media stack — wire-up after apply

Terraform puts **plex**, **prowlarr**, **radarr**, **sonarr** on `media-net-*` so they resolve each other by name.

## 0) Folders on the VM (once)

```bash
mkdir -p ~/media/{movies,tv,downloads}
```

Then push/apply this Terraform.

## 1) Open UIs

| App | URL |
|-----|-----|
| Plex | http://192.168.0.150:32400/web |
| Prowlarr | http://192.168.0.150:9696 |
| Radarr | http://192.168.0.150:7878 |
| Sonarr | http://192.168.0.150:8989 |

## 2) Link Prowlarr → Radarr

1. Radarr → Settings → General → copy **API Key**
2. Prowlarr → Settings → Apps → Add → **Radarr**
3. Prowlarr server: `http://radarr:7878` (not localhost)
4. Paste Radarr API key → Test → Save  
5. Sync indexers if prompted

## 3) Link Prowlarr → Sonarr

Same as above, App = **Sonarr**, URL = `http://sonarr:8989`

## 4) Paths inside Radarr / Sonarr

- Radarr root folder: `/movies`
- Sonarr root folder: `/tv`
- Download client folder (when you add one): `/downloads`

## 5) Plex libraries

- Movies → folder `/movies`
- TV → folder `/tv`

Plex does not need Prowlarr API keys; it just reads the same files Radarr/Sonarr write.

## Note

Indexer + download client (qBittorrent, etc.) are separate; add a download client later and point Radarr/Sonarr at it on the same Docker network.
