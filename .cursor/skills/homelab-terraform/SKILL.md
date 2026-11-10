---
name: homelab-terraform
description: >-
  Operate this Debian homelab Terraform repo: Ansible media stack, Glances,
  Traefik, and Authentik. Use when editing Terraform, Ansible, GitHub Actions,
  media apps, DNS for lab.home, or when applying or destroying on the
  self-hosted runner. Do not recreate the Windows VM.
---

# Homelab Terraform

Replies stay in English. Stay on `main`. Do not check out or merge `interview-labs`. Do not change `interview-prep/` while doing lab work.

## Where things run

- Lab host: Debian bare metal `192.168.0.120`, user `cosmin`. SSH only when the user asks. Password auth; never commit the password.
- This checkout is not the lab host. Terraform state is only on the host at `/home/cosmin/terraform-project`, workspace `test`. No S3, no remote backend.
- Runner `debian-terraform` (`~/actions-runner`, labels `self-hosted, terraform-vm`) applies on push to `main`. `workflow_dispatch` input `action` is `plan` or `apply`. Plan does not apply.
- Destroy is `.github/workflows/terraform-destroy.yml`, `workflow_dispatch` only. Input `confirm` must be exactly `destroy`. It does not remove Docker.
- `gh` is not installed. Dispatch with the GitHub API and the token in `~/.git-credentials`. Git identity via `GIT_AUTHOR_*` / `GIT_COMMITTER_*` only. Never `git config`.

## What Terraform owns

`main.tf` no longer creates a Windows VM. The libvirt provider stays so apply can destroy `windows-srv-test`, its disk, `win-internal-test`, and pool `default` while they are still in state. Do not add the domain back.

`terraform_data.ansible_configure` uses `triggers_replace = [timestamp()]` and `stdbuf` so Ansible runs on every apply with live logs. That replace on every plan is intentional. Plain `virsh` is the session URI. Always `virsh -c qemu:///system`.

## What Ansible owns

`ansible/site.yml` on host `debian`, `become: true`, local connection. Role order: `base`, `docker_host`, `dns`, `firewall`, `media_stack`, `monitor`, `authentik`, `traefik`, `media_link`.

Docker network `media-net-test` (`10.20.0.0/16`). Images that publish `latest` use `:latest`. Authentik does not. Pin `ghcr.io/goauthentik/server:2026.8.5`.

Plex stays on host port `32400` and is not behind Authentik. qBittorrent torrent port `6881` tcp/udp stays open. Plex sign-in and the Seerr first-run wizard stay manual.

Firewall allows 22, 80, 443, 32400, 61208, 6881 only when ufw is already active. Never `ufw enable`. The `when` that checks `Status: active` must be a quoted string (Ansible 2.19).

Workflow installs always `apt-get clean` and drop `/var/lib/apt/lists` first. Logs use `stdbuf -oL` and `PYTHONUNBUFFERED=1`.

## Do not regress

- Before plan, move the staged Windows ISO out of `/var/lib/libvirt/images`. Pool delete fails while that file is there. Do not `virsh undefine windows-srv-test` in that step; Terraform destroys it from state.
- Postgres 18 volume is `authentik-db:/var/lib/postgresql`, not `/var/lib/postgresql/data`. `postgres_volume.py` drops a volume still mounted at the old path.
- Outpost `authentik_host` and `authentik_host_browser` are `https://auth.lab.home`. Empty values send the browser to `http://localhost`. `AUTHENTIK_HOST` is set on server and worker. Blueprint is mounted on both.
- Traefik file provider watches a directory mount `/var/lib/lab/compose/traefik:/etc/traefik:ro`. A file bind-mount goes stale when Ansible replaces the file. Traefik matches `Host`, so `https://192.168.0.120` is a 404. `auth.lab.home` has no Authentik middleware. `issue_lab_cert.py` creates a local CA and a leaf for `*.lab.home`, `lab.home`, and `192.168.0.120` only when the files are missing. Traefik uses that leaf as the default certificate. Clients trust `/var/lib/lab/certs/lab-ca.crt`. Do not regenerate the key on every apply.
- Prowlarr apps use `prowlarrUrl=http://prowlarr:9696` and Docker DNS base URLs. `http://localhost:9696` makes Radarr reject the app. qBittorrent login needs `Referer`. Field payloads are `{name, value}` only. Seerr link failures before the wizard are `skipped-until-wizard`.
- Monitoring is Glances, not Netdata. Image `nicolargo/glances:latest`, web mode, `pid: host`, Docker socket read-only. It has no password of its own. Open `http://192.168.0.120:61208`, or `https://monitor.lab.home` with Authentik `admin` / `1234`. Traefik reaches it at `http://10.20.0.1:61208` because Glances uses the host network. The Netdata container, volumes, and Authentik app stay marked for removal. Grafana stays as the friendlier UI at `https://grafana.lab.home`. Its login form is off; Authentik's `X-authentik-username` header signs the user in. Loki stores container logs, Prometheus stores host metrics, Alloy collects both. Do not publish Grafana's port on the host.
- Secrets stay in `/home/cosmin/.config/lab/secrets.env` (gitignored). Login `admin` / `1234`, qBittorrent web `1234`.
- Tests in `ansible/tests/` must keep an assert message. Clean up unused code. Do not commit `__pycache__` or `*.pyc`.

## DNS

Names are `*.lab.home` → `192.168.0.120`. dnsmasq on the lab host listens only on `192.168.0.120` and must not fail the play. Clients do not use it by default.

AdGuard at `192.168.0.179` has the rewrite and answers when queried directly. The router `192.168.0.1` resolves `lab.home` on the public root and caches NXDOMAIN. Its SSH port is closed. A browser fails while its current DNS server is the router. Point the client at `192.168.0.179` only. This is not fstab and not Traefik.

## Change flow

1. Edit on `main`.
2. Commit and push only when the user asked, or when they asked to fix and let the runner apply.
3. Destroy, then apply, only through the two workflows. Do not hand-edit the host to simulate a run.
4. Read the Actions job log. Runner diag logs do not contain the playbook text.

Known failure strings and the fix that must stay in git: [pitfalls.md](pitfalls.md).
