# CLAUDE.md

Read `GOALS.md` first. It defines what this repo creates, what is out of scope
and the definition of done. When a choice is unclear, pick the option that makes
the "move an app off AWS to a cheap VPS, safely and measurably" story clearer.

## Context

- This repo (joheee/TicTacToeVpsMigration) is portfolio project #2: migrate the tic-tac-toe app (joheee/TicTacToeCICD,
  infra in joheee/TicTacToeInfra) from AWS EC2 to a DigitalOcean Droplet
  (2 GB, Ubuntu 24.04, `sgp1`), then retire the AWS stack. Oracle Cloud was
  dropped because it needs a credit card to sign up.
- Reuse project 4's patterns: Compose (db → migrate → app), Caddy with Let's
  Encrypt, SHA-tagged images, smoke test, rollback to `last_good_tag`. Reuse
  project 1/4 Terraform style (versions pinned, small files by concern).
- The kit should stay provider-agnostic: only `terraform/` is DigitalOcean-specific.

## Layout

- `terraform/`: `digitalocean` provider, project, VPC, SSH key, Cloud Firewall
  (80/443 only, no 22), Droplet, reserved IP and its assignment, Spaces bucket
  for backups (7-day lifecycle rule). Applied locally. State is local while
  testing, then a hand-made Space. Small files by concern.
- `cloud-init/`: user-data that hardens Ubuntu and installs Docker, Tailscale,
  UFW, fail2ban, unattended-upgrades.
- `deploy/`: Compose file, Caddyfile, deploy/rollback/backup scripts run on the
  VM.
- `docs/`: cutover runbook, rollback runbook, before/after diagrams, downtime
  log, cost table.
- `.github/workflows/`: `checks.yml` (fmt, validate, tflint, shellcheck) and
  the VPS deploy workflow if it lives here rather than in TicTacToeCICD.

## Working rules

- Never commit secrets, `*.tfstate`, `.terraform/`, DigitalOcean API tokens,
  Spaces keys, Tailscale auth keys, `.env` files or real tfvars. Commit
  `*.example` files.
- Budget: about $17 a month (Droplet ~$12, Spaces $5). Flag anything that adds
  cost before adding it. Skip DO backups, snapshots, volumes, load balancers and
  managed databases. Droplets bill hourly even when powered off, so test runs
  end with `terraform destroy`, never a shutdown. A billing alert must exist.
- Images are `linux/amd64` (DigitalOcean has no ARM Droplets), pushed to GHCR.
- No public SSH: the Cloud Firewall and UFW allow only 80 and 443 from the
  internet; SSH only over Tailscale, keys only, no root login. Confirm
  Tailscale access works before closing everything else.
- Changes to TicTacToeCICD are additive until cutover; don't break its AWS
  pipeline before the AWS stack is retired.
- Never destroy the AWS stack, run `terraform apply`/`destroy`, or change DNS
  without being asked; show the plan or the exact change first.
- Run `terraform fmt -recursive`, `terraform validate`, `tflint` and
  `shellcheck` before every commit.
- Commits: author `joheee <johevinblesstowi07@gmail.com>`, no Co-Authored-By
  trailer. Ask before committing or pushing.
- Tick the boxes in the GOALS.md "Definition of done" as items are finished.
