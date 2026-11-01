# How this setup works (learning notes)

## The problem

GitHub cloud runners cannot reach private IP `192.168.0.120`.  
A **self-hosted runner** on the VM pulls jobs and runs Terraform there.

```text
You push to GitHub
        |
        v
GitHub Actions
        |
        v
VM runner (debian-terraform)
        |
        v
terraform apply  (workspace: test)
```

## Pieces on the VM

| Path / name | Role |
|-------------|------|
| `~/actions-runner` | GitHub Actions agent |
| `/home/cosmin/terraform-project` | Stable Terraform working dir + state |
| workspace `test` | Only lab environment for now |
| `~/media/{movies,tv,downloads}` | Shared media folders |

## Why only `test`?

One VM + fixed host ports (`32400`, `7878`, â€¦). A parallel `dev` stack would clash.  
Reintroduce `dev` later with different names/ports or another machine.

## Mental model

1. **Git** = source of truth for `.tf`  
2. **GitHub Actions** = automation  
3. **Self-hosted runner** = run on your VM  
4. **Terraform apply** = make Docker match the code  
