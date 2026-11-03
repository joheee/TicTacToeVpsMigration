# CLAUDE.md

Read `GOALS.md` first. It defines what this repo creates, what is out of scope
and the definition of done. When a choice is unclear, pick the option that makes
the "move an app off AWS to a cheap VPS, safely and measurably" story clearer.

## Context

- This repo (joheee/TicTacToeVpsMigration) is portfolio project #2: migrate
  the tic-tac-toe app (joheee/TicTacToeCICD, infra in joheee/TicTacToeInfra)
  from AWS EC2 to a DigitalOcean Droplet (2 GB, Ubuntu 24.04, `sgp1`), then
  retire the AWS stack. Oracle Cloud was dropped because it needs a credit
  card to sign up.
- This repo is Terraform, cloud-init and the migration docs only. The deploy
  pipeline, Compose file, Caddyfile and backup job live in TicTacToeCICD,
  which reads this repo's outputs as GitHub Actions variables (same split as
  project 4).
- Reuse project 1/4 Terraform style (versions pinned, small files by concern,
  modules where they help).
- The kit should stay provider-agnostic: only the Terraform at the repo root
  (`*.tf`, `modules/`) is DigitalOcean-specific.

## Layout

- Repo root (`*.tf`, `modules/`): `digitalocean` provider, project, VPC, SSH key, Cloud Firewall
  (22, 80 and 443), Droplet, reserved IP and its assignment, Spaces bucket
  for backups (7-day lifecycle rule), outputs. Applied locally. State is local
  while testing, then a hand-made Space via the S3 backend.
- `cloud-init/`: user-data that hardens Ubuntu and installs Docker,
  UFW, fail2ban, unattended-upgrades, and creates the `deploy` user and
  `/opt/app`.
- `docs/`: cutover runbook, rollback runbook, Cloudflare settings,
  before/after diagrams, downtime log, cost table.
- `.github/workflows/checks.yml`: fmt, validate, tflint, shellcheck. No plan
  or apply from CI.

## Working rules

- Never commit secrets, `*.tfstate`, `.terraform/`, DigitalOcean API tokens,
  Spaces keys, `.env` files or real tfvars. Pass the
  token and Spaces keys as environment variables (`DIGITALOCEAN_TOKEN`,
  `SPACES_ACCESS_KEY_ID`, `SPACES_SECRET_ACCESS_KEY`). Commit `*.example`
  files.
- Budget: about $17 a month (Droplet ~$12, Spaces $5). Flag anything that adds
  cost before adding it. Skip DO backups, snapshots, volumes, load balancers and
  managed databases. Droplets bill hourly even when powered off, so test runs
  end with `terraform destroy`, never a shutdown. A billing alert must exist
  (set by hand in the control panel).
- SSH is public (decided to keep deploys simple; GitHub runners have no fixed
  IP): the Cloud Firewall and UFW allow 22, 80 and 443. Keys only, no
  passwords, no root login, `AllowUsers deploy`, fail2ban. Tailscale is not
  used. Confirm key login works before relying on the server.
- Outputs are a contract with TicTacToeCICD. Don't rename or remove the
  outputs listed in `GOALS.md`; add new ones and note them in the README.
- Don't add app deploy logic here. Changes to TicTacToeCICD are additive until
  cutover; don't break its AWS pipeline before the AWS stack is retired.
- Never destroy the AWS stack, run `terraform apply`/`destroy`, or change DNS
  without being asked; show the plan or the exact change first.
- Pin Terraform (>= 1.10) and provider versions in `versions.tf`; commit
  `.terraform.lock.hcl`.
- Run `terraform fmt -recursive`, `terraform validate`, `tflint` and
  `shellcheck` before every commit.
- Commits: author `joheee <johevinblesstowi07@gmail.com>`, no Co-Authored-By
  trailer. Ask before committing or pushing.
- Tick the boxes in the GOALS.md "Definition of done" as items are finished.
