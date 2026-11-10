# Terraform

Self-hosted GitHub Actions deploy to the Debian VM (`debian-terraform` runner).

## Environment

Single lab workspace: **`test`** (one VM — ports/names can’t host a second full media stack).

Stack: Plex, Prowlarr, Radarr, Sonarr, Seerr, qBittorrent. Ansible links them and puts Authentik in front of the named URLs. See [PLAN.md](PLAN.md).

## Manual run

GitHub → Actions → Terraform → Run workflow → `plan` or `apply` (always workspace `test`).
