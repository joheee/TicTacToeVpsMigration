# Project goals: AWS-to-VPS migration kit

This repo (joheee/TicTacToeVpsMigration) is portfolio project #2 for my Upwork
DevOps profile. The point is the **migration**: a client should look at it and
think "this person can move my app off an expensive cloud setup onto a cheap
VPS, with a written cutover plan, a rollback, measured downtime and no lost
data".

The workload is the tic-tac-toe app from project 4
([joheee/TicTacToeCICD](https://github.com/joheee/TicTacToeCICD)), which today
runs on AWS (EC2 + ECR + SSM, built by
[joheee/TicTacToeInfra](https://github.com/joheee/TicTacToeInfra), about $25 a
month) at `tictactoe.johe.my.id`. This project moves it, with its PostgreSQL
data, to a **DigitalOcean Droplet**, then retires the AWS stack.

## How the three repos fit together

This repo is **Terraform, server setup and the migration runbooks only**. It
follows project 4's split: the infra repo's outputs become the app repo's
GitHub Actions variables, and the app repo owns the pipeline.

| Repo | Holds |
|---|---|
| **TicTacToeVpsMigration** (this repo) | Terraform for the Droplet, VPC, Cloud Firewall, reserved IP and backup bucket; cloud-init hardening; checks workflow; cutover and rollback runbooks, diagrams, downtime log, cost table |
| **TicTacToeCICD** | The app, Compose, Caddyfile, and the pipeline: GHCR push, `deploy-do.yml` (SSH deploy, smoke test, rollback), nightly `pg_dump` job. Its AWS `deploy.yml` stays until cutover. |
| **TicTacToeInfra** | The AWS stack being retired. No DigitalOcean resources; destroyed after the cutover. |

### Outputs contract

TicTacToeCICD copies these outputs into its GitHub Actions variables. Renaming
or removing one is a breaking change for the app repo; add new ones freely.

| Terraform output | App repo variable | What it is |
|---|---|---|
| `droplet_ipv4` | `DO_DROPLET_IP` | Reserved IP the DNS record points at |
| `tailscale_hostname` | `DO_TAILSCALE_HOST` | Host the deploy workflow SSHes to. Name kept for the contract; now the reserved IP (same as `ssh_host`) |
| `deploy_user` | `DO_DEPLOY_USER` | Non-root user the deploy runs as |
| `app_url` | `DO_APP_URL` | Public URL for the smoke test |
| `backup_bucket` | `DO_BACKUP_BUCKET` | Spaces bucket for nightly `pg_dump` files |
| `spaces_endpoint` | `DO_SPACES_ENDPOINT` | S3-compatible endpoint for that bucket |

## The pitch (what a client buys)

> "Move your app from AWS/Render/Heroku to a VPS, 3 days." Containerised app
> on a hardened Ubuntu server, Caddy with automatic HTTPS, Cloudflare DNS and
> WAF in front, CI/CD that deploys and rolls back, nightly database backups,
> uptime monitoring, and a rehearsed cutover with a rollback plan. Before and
> after cost in the README.

It matches jobs like "Render → DigitalOcean migration", "Medusa on OVH VPS",
"Hetzner VPS deployment", "Oracle Cloud → GoDaddy" and "Azure → low-cost AWS".
The kit is provider-agnostic: only the Terraform for the VM is
DigitalOcean-specific, everything from cloud-init upward runs on any Ubuntu VPS.

## Why DigitalOcean

Oracle Cloud Always Free was the first choice ($0), but its sign-up needs a
credit card, which I don't have. DigitalOcean accepts PayPal and cards, and
bills by the hour, so test runs cost cents.

| Option | Cost | Fit |
|---|---|---|
| **DigitalOcean Droplet (2 GB, `sgp1`)** | about $12 a month, plus $5 a month for Spaces; new accounts have a small sign-up credit ($5 at the time of writing) | Common in client posts ("Render → DigitalOcean"), Terraform provider, Cloud Firewall and reserved IP included. Singapore is the nearest region to Indonesia. x86 only. |
| Oracle Cloud Always Free (Ampere A1) | $0 | Needs a card to sign up. Capacity and reclamation risks. Dropped. |
| Hetzner Cloud CAX11 / CX23 | about €6 a month (EU); Singapore starts at €15.49 | The cheapest "real client" VPS. Good second target for the "reuse the kit" section. |
| Google Cloud e2-micro | free, US regions only, 1 GB RAM | Too small and too far away. |
| AWS free plan | credits for a few months | Not a migration *away* from AWS. |

Known DigitalOcean risks, handled in the plan: Droplets bill hourly even when
powered off, so test runs end with `terraform destroy`; a reserved IP costs
money when it is not attached to a Droplet; snapshots, backups and volumes keep
billing after the Droplet is gone, so the plan does not use them; the sign-up
credit amount changes, so it is not counted in the cost table. A billing alert
guards against forgotten resources.

## Objectives

1. **Droplet in Terraform.** `digitalocean` provider: project, VPC, SSH key,
   Cloud Firewall allowing only 80 and 443 from anywhere, one 2 GB Droplet
   (Ubuntu 24.04, `sgp1`), reserved IP with its assignment, and a private Spaces
   bucket for backups with a 7-day lifecycle rule. All six contract outputs.
   Applied locally with the API token and Spaces keys as environment
   variables; no tokens in GitHub.
2. **Remote state.** Local while testing, then a hand-made Space through the
   S3 backend (`endpoints.s3`, `use_path_style`, the `skip_*` validation
   flags). Test whether `use_lockfile = true` works on Spaces with two
   concurrent `plan` runs; if it doesn't, document that state is single-writer.
3. **Hardened server from cloud-init.** Ubuntu LTS, non-root `deploy` user,
   SSH keys only (no passwords, no root login), UFW, fail2ban,
   unattended-upgrades, Docker + Compose plugin, swap file, `/opt/app`. SSH is
   public but key-only (no root login, fail2ban) so GitHub-hosted runners can
   deploy; Tailscale is not used.
   Anything beyond this (app files, `.env`, containers) belongs to the app
   pipeline.
4. **Checks in CI.** `checks.yml` runs `terraform fmt -check`, `validate`,
   `tflint` and `shellcheck` on every pull request and push. No `plan` in CI,
   because DigitalOcean has no OIDC and the token stays off GitHub.
5. **Edge: Cloudflare.** DNS for `johe.my.id` on Cloudflare, proxied record,
   Full (strict) TLS, WAF managed rules and a rate-limit rule on the login and
   register endpoints. Set by hand (or the Cloudflare provider as a stretch)
   and recorded in the runbook. The app repo's Caddy trusts Cloudflare's ranges
   (`trusted_proxies`) so the per-IP rate limit sees the real client address.
6. **Rehearsed cutover with rollback.** A written runbook in `docs/`: lower DNS
   TTL, rehearse on `vps.tictactoe.johe.my.id`, freeze writes, final
   `pg_dump` from EC2 and restore on the Droplet, row-count check, flip DNS,
   smoke test, watch. Rollback = flip DNS back to the EC2 Elastic IP (kept
   running 48 hours). Downtime is measured during the rehearsal and the real
   cutover and logged in `docs/`.
7. **Retire AWS and write it up.** After 48 quiet hours, `terraform destroy`
   in TicTacToeInfra. README as a client case study: before/after diagram,
   runbook, measured downtime, rollback test, monthly cost before (about $25)
   and after (about $17), outputs table, and how to run the same kit on
   Hetzner or another VPS.

Delivered in **TicTacToeCICD** (tracked in its own GOALS.md, needed for this
project's cutover): GHCR push of the `linux/amd64` image, `deploy-do.yml` with
smoke test and rollback to `last_good_tag`, secrets in a GitHub Environment
written to `.env` (mode 600), nightly `pg_dump` to the backup bucket with one
tested restore, uptime monitoring (Uptime Kuma or a free external check).

## Out of scope

- The app's pipeline, Compose file, Caddyfile and backup job. They live in
  TicTacToeCICD.
- Terraform plan or apply from GitHub. DigitalOcean has no OIDC federation,
  so Terraform runs locally with an API token and CI only runs checks.
- Kubernetes, DOKS or multiple servers. One Droplet, Compose.
- High availability or zero-downtime cutover. A few minutes of planned
  downtime with a write freeze is the honest small-business answer.
- Managed Postgres. The database stays in Compose, as on EC2.
- DigitalOcean backups, snapshots, volumes and load balancers. They add cost
  the plan doesn't need.
- Point-in-time recovery and pgBackRest. That's project 3.
- A screen recording. As in project 4, the logged workflow runs, the runbook
  and the measured downtime are the proof.

## Constraints

- Budget: about $17 a month (Droplet ~$12, Spaces $5). A DigitalOcean billing
  alert ($5 or $10) is set by hand in the control panel (Terraform can't
  create it). Flag anything that adds cost before adding it.
- Test runs create and then destroy: Droplets bill by the hour even when off.
  The cutover itself needs the Droplet for about five days (rehearsal,
  cutover, 48-hour watch), roughly $2.
- The current AWS stack stays up until the cutover is proven; destroying it is
  the last step and is done only when asked.
- The app repo keeps working on AWS until cutover day. VPS changes there are
  additive (new workflow, GHCR push) until AWS is retired.

## Plan (3 days)

| Day | Work |
|---|---|
| 1 | DigitalOcean account, billing alert, API token and Spaces keys. Terraform for VPC + firewall + Droplet + reserved IP + backup bucket, outputs, cloud-init hardening (verify key login), `checks.yml`. Hand outputs to TicTacToeCICD. |
| 2 | In TicTacToeCICD: GHCR push, `deploy-do.yml`, nightly `pg_dump` with a tested restore, uptime check. Here: Cloudflare DNS/WAF/rate limit, cutover and rollback runbooks. Rehearsal on `vps.` subdomain with downtime measured. |
| 3 | Real cutover and rollback test, 48-hour watch, AWS destroyed, README case study with diagram and cost table, Upwork portfolio entry. |

## Tools and software

DigitalOcean (Droplet, Cloud Firewall, reserved IP, Spaces) · Terraform
(>= 1.10) with the DigitalOcean provider · cloud-init · Ubuntu LTS · Docker +
Compose · Cloudflare DNS, WAF and rate limiting · GitHub Actions ·
UFW · fail2ban · tflint · shellcheck · draw.io or Mermaid

## Definition of done

- [ ] `terraform apply` creates the VPC, Cloud Firewall, Droplet, reserved IP and Spaces bucket within the budget, with all six contract outputs.
- [ ] State lives in a Space; locking is either proven or documented as single-writer.
- [ ] The VM is hardened by cloud-init: key-only public SSH with no root login, UFW, fail2ban, unattended-upgrades, Docker.
- [ ] `checks.yml` runs fmt, validate, tflint and shellcheck on every PR.
- [ ] Cloudflare proxies the domain with Full (strict) TLS, WAF and a login rate limit.
- [ ] TicTacToeCICD deploys to the Droplet with smoke test and rollback, and backs up nightly to the bucket (tracked there; linked from here).
- [ ] Rehearsal and real cutover done with downtime measured; DNS rollback tested.
- [ ] AWS stack destroyed after 48 quiet hours.
- [ ] README has before/after diagrams, the runbook, downtime numbers, outputs table, cost before and after, and how to reuse the kit on Hetzner or another VPS.
