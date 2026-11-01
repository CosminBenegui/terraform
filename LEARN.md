# How this setup works (learning notes)

## The problem

GitHub's cloud runners live on the public internet. Your VM is at `192.168.0.150` (private LAN). Cloud runners **cannot SSH into it**.

So we installed a **self-hosted runner** on the VM. GitHub sends jobs to that machine instead.

```text
You push to GitHub
        |
        v
GitHub Actions (orchestrator in the cloud)
        |
        v  (job assigned to your runner)
VM 192.168.0.150  -->  debian-terraform service
        |
        v
terraform plan / apply  (workspaces: test, dev)
```

## Pieces on the VM

| Path / name | Role |
|-------------|------|
| `~/actions-runner` | GitHub Actions agent software |
| systemd service `actions.runner...debian-terraform` | Keeps the runner online after reboot |
| `/home/cosmin/terraform-project` | Stable folder where `terraform apply` runs (state stays here) |
| workspaces `test` / `dev` | Separate state + separate nginx containers/ports |

## Why a fixed project path?

Each Actions job checks out code into a temporary `_work` folder. If you ran Terraform only there, **state would be lost** between runs.

The workflow copies the repo into `/home/cosmin/terraform-project` and runs Terraform there so `terraform.tfstate.d/dev` and `.../test` survive.

## What `main.tf` does

- Uses the **Docker** provider to run `nginx:alpine`
- Container name: `terraform-nginx-<workspace>`
- Ports: `dev` → host `8081`, `test` → host `8082`
- Writes `hello-<workspace>.txt` so you can see a local file change too

## Workflow behavior

- **Push to `main`** → plan + apply on workspace **`test`**
- **Actions → Run workflow** → choose `dev` or `test`, and `plan` or `apply`

## Commands worth knowing on the VM

```bash
# Runner
sudo ~/actions-runner/svc.sh status

# Terraform (after a successful apply)
cd ~/terraform-project
terraform workspace list
terraform workspace select test
terraform state list
docker ps --filter name=terraform-nginx
```

## Mental model

1. **Git** = source of truth for `.tf` files  
2. **GitHub Actions** = automation trigger  
3. **Self-hosted runner** = “do the work on MY VM”  
4. **Terraform workspaces** = same code, isolated state per environment  
