# Terraform

Self-hosted GitHub Actions deploy to the Debian VM (`debian-terraform` runner).

## Workspaces

- `test` — applied automatically on push to `main`
- `dev` — manual only (`workflow_dispatch`)

Each workspace runs an `nginx:alpine` container (`terraform-nginx-<workspace>`) and writes `hello-<workspace>.txt`.

| Workspace | Host port |
|-----------|-----------|
| dev       | 8081      |
| test      | 8082      |

## Manual run

GitHub → Actions → Terraform → Run workflow → pick workspace + `plan`/`apply`.
