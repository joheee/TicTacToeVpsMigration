# CLAUDE.md

Read `GOALS.md` first. It defines what this repo creates, what is out of scope
and the definition of done. When a choice is unclear, pick the option that makes
the "move an app off AWS to a cheap VPS, safely and measurably" story clearer.

## Context

- This repo (joheee/TicTacToeVpsMigration) is portfolio project #2: migrate the tic-tac-toe app (joheee/TicTacToeCICD,
  infra in joheee/TicTacToeInfra) from AWS EC2 to an Oracle Cloud Always Free
  Ampere A1 VM, then retire the AWS stack.
- Reuse project 4's patterns: Compose (db → migrate → app), Caddy with Let's
  Encrypt, SHA-tagged images, smoke test, rollback to `last_good_tag`. Reuse
  project 1/4 Terraform style (versions pinned, small files by concern).
- The kit should stay provider-agnostic: only `terraform/` is Oracle-specific.

## Layout

- `terraform/`: OCI provider, VCN, subnet, security list (80/443 only), A1 VM,
  reserved IP, Object Storage bucket for backups. Backend in OCI Object
  Storage. Applied locally.
- `cloud-init/`: user-data that hardens Ubuntu and installs Docker, Tailscale,
  UFW, fail2ban, unattended-upgrades.
- `deploy/`: Compose file, Caddyfile, deploy/rollback/backup scripts run on the
  VM.
- `docs/`: cutover runbook, rollback runbook, before/after diagrams, downtime
  log, cost table.
- `.github/workflows/`: `checks.yml` (fmt, validate, tflint, shellcheck) and
  the VPS deploy workflow if it lives here rather than in TicTacToeCICD.

## Working rules

- Never commit secrets, `*.tfstate`, `.terraform/`, OCI API keys, Tailscale
  auth keys, `.env` files or real tfvars. Commit `*.example` files.
- Stay inside Oracle Always Free limits (A1 total 2 OCPU / 12 GB across the
  tenancy). Flag anything that could cost money before adding it.
- Images must be multi-arch (`linux/amd64,linux/arm64`).
- No public SSH: the security list and UFW allow only 80 and 443 from the
  internet; SSH only over Tailscale, keys only, no root login.
- Changes to TicTacToeCICD are additive until cutover; don't break its AWS
  pipeline before the AWS stack is retired.
- Never destroy the AWS stack, run `terraform apply`/`destroy`, or change DNS
  without being asked; show the plan or the exact change first.
- Run `terraform fmt -recursive`, `terraform validate`, `tflint` and
  `shellcheck` before every commit.
- Commits: author `joheee <johevinblesstowi07@gmail.com>`, no Co-Authored-By
  trailer. Ask before committing or pushing.
- Tick the boxes in the GOALS.md "Definition of done" as items are finished.
