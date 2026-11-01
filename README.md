# Terraform

Self-hosted GitHub Actions deploy to the Debian VM (`debian-terraform` runner).

## Environment

Single lab workspace: **`test`** (one VM — ports/names can’t host a second full media stack).

Stack: Plex, Prowlarr, Radarr, Sonarr, Seerr on Docker network `media-net-test`.

See [MEDIA-SETUP.md](MEDIA-SETUP.md) for UI linking.

## Manual run

GitHub → Actions → Terraform → Run workflow → `plan` or `apply` (always workspace `test`).
