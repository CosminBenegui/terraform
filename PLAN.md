# Lab plan

Created: 2026-11-10

No cloud and no S3. Terraform state stays on the Debian host. Terraform creates the Docker stack and the Windows Server VM. Ansible only configures them.

## Who owns what

| Tool | Owns |
|---|---|
| Terraform | Ansible run after apply. State in `/home/cosmin/terraform-project`. The libvirt provider stays only so apply can destroy the old Windows VM. |
| Ansible | Host packages, DNS, firewall allows, media containers if they are missing, Traefik, Authentik, app links. |
| Authentik | Login for the HTTP apps reached by name. |
| Traefik | Ingress on ports 80 and 443. |

## Ingress

```text
https://radarr.lab.home
        |
        v
Traefik :443
        |
        v
Authentik
        |
        v
http://radarr:7878
```

Same path for Sonarr, Prowlarr, Seerr, and the qBittorrent web UI.

`auth.lab.home` goes to Authentik with no login loop. Plex stays on `:32400`. Torrent port `6881` stays open. Glances is on `:61208` and `https://monitor.lab.home`. Grafana is `https://grafana.lab.home` and uses the same Authentik login. Traefik serves a lab CA certificate for `*.lab.home`. Trust `/var/lib/lab/certs/lab-ca.crt` on each client.

The first Authentik login is `admin` / `1234` at `https://auth.lab.home`. qBittorrent web UI uses the same password, and Radarr and Sonarr use it as the download client.

## Media links the playbook makes

- Prowlarr application → Radarr `http://radarr:7878`
- Prowlarr application → Sonarr `http://sonarr:8989`
- Radarr root folder `/movies`, Sonarr root folder `/tv`
- Radarr and Sonarr download client → `qbittorrent:8080` with password `1234`
- Seerr → Radarr and Sonarr after the Seerr wizard has been finished once
- Plex login stays manual

## Pipeline

1. GitHub Actions on the self-hosted runner.
2. Terraform plan.
3. Clean apt lists, then install Ansible.
4. Terraform apply. Terraform itself runs `ansible-playbook site.yml`.
6. Ansible configures the host, ingress, Authentik, and media links.

A manual `terraform apply` on the host does the same Ansible run. The workflow does not call the playbook a second time.

Open the running job log to watch it. Terraform and Ansible write a line at a time (`PYTHONUNBUFFERED` and `stdbuf -oL`), so each plan line and each Ansible `TASK` shows up before the step finishes. Ansible skips are hidden. The task name is the progress marker.

## Not in this lab

Remote state, S3, a Windows VM, putting Plex or the torrent port behind Authentik.
