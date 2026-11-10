---
name: homelab-terraform
description: >-
  Operate this Debian homelab Terraform repo: libvirt Windows VM, Ansible
  media stack, Traefik, and Authentik. Use when editing Terraform, Ansible,
  GitHub Actions, the Windows VM, media apps, DNS for lab.home, or when
  applying or destroying on the self-hosted runner.
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

`main.tf` creates the Windows VM, then always runs Ansible:

- Provider `dmacvicar/libvirt ~> 0.7`, `uri = qemu:///system`. Plain `virsh` is the session URI. Always `virsh -c qemu:///system`.
- Domain `windows-srv-test`, disk `windows-srv-disk-test.qcow2`, 250 GiB, pool `default` at `/var/lib/libvirt/images`.
- Network `win-internal-test` (`autostart = true`) plus the libvirt `default` NAT network.
- Boot `hd` then `cdrom`. OS disk bus is SATA via XSLT (`xsltproc` required) so Windows Setup sees the disk.
- VNC listens on `0.0.0.0` (RealVNC on the LAN, port from `vncdisplay`, usually `5900`). Do not close it.
- `terraform_data.ansible_configure` uses `triggers_replace = [timestamp()]` and `stdbuf` so Ansible runs on every apply with live logs. That replace on every plan is intentional.

## What Ansible owns

`ansible/site.yml` on host `debian`, `become: true`, local connection. Role order: `base`, `docker_host`, `libvirt_host`, `dns`, `firewall`, `media_stack`, `monitor`, `authentik`, `traefik`, `media_link`.

Docker network `media-net-test` (`10.20.0.0/16`). Images that publish `latest` use `:latest`. Authentik does not. Pin `ghcr.io/goauthentik/server:2026.8.5`.

Plex stays on host port `32400` and is not behind Authentik. qBittorrent torrent port `6881` tcp/udp stays open. Plex sign-in and the Seerr first-run wizard stay manual.

Firewall allows 22, 80, 443, 32400, 5900, 61208, 6881 only when ufw is already active. Never `ufw enable`. The `when` that checks `Status: active` must be a quoted string (Ansible 2.19).

Workflow installs always `apt-get clean` and drop `/var/lib/apt/lists` first. Logs use `stdbuf -oL` and `PYTHONUNBUFFERED=1`.

## Do not regress

- ISO source is `/home/cosmin/Downloads/SERVER_EVAL_x64FRE_en-us.iso`. QEMU cannot traverse `/home/cosmin`. Stage it into the pool as `libvirt-qemu:kvm`. `sudo mkdir -p /var/lib/libvirt/images` before the copy. Destroy of an empty pool deletes that directory.
- Start `win-internal-test` and pool `default` before plan. A defined but inactive network or pool fails domain create.
- AppArmor: `/etc/libvirt/qemu.conf` has `security_driver = "none"`. Do not remove it.
- Postgres 18 volume is `authentik-db:/var/lib/postgresql`, not `/var/lib/postgresql/data`. `postgres_volume.py` drops a volume still mounted at the old path.
- Outpost `authentik_host` and `authentik_host_browser` are `https://auth.lab.home`. Empty values send the browser to `http://localhost`. `AUTHENTIK_HOST` is set on server and worker. Blueprint is mounted on both.
- Traefik file provider watches a directory mount `/var/lib/lab/compose/traefik:/etc/traefik:ro`. A file bind-mount goes stale when Ansible replaces the file. Traefik matches `Host`, so `https://192.168.0.120` is a 404. `auth.lab.home` has no Authentik middleware. Cert is Traefik's default self-signed cert.
- Prowlarr apps use `prowlarrUrl=http://prowlarr:9696` and Docker DNS base URLs. `http://localhost:9696` makes Radarr reject the app. qBittorrent login needs `Referer`. Field payloads are `{name, value}` only. Seerr link failures before the wizard are `skipped-until-wizard`.
- Monitoring is Glances, not Netdata. Image `nicolargo/glances:latest`, web mode, `pid: host`, Docker socket read-only. It has no password of its own. Open `http://192.168.0.120:61208`, or `https://monitor.lab.home` with Authentik `admin` / `1234`. Traefik reaches it at `http://10.20.0.1:61208` because Glances uses the host network. The Netdata container, volumes, and Authentik app stay marked for removal.
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
