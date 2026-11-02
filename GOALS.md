# Project goals: AWS-to-VPS migration kit

This repo (joheee/TicTacToeVpsMigration) is portfolio project #2 for my Upwork DevOps profile. The point is the
**migration**: a client should look at it and think "this person can move my
app off an expensive cloud setup onto a cheap VPS, with a written cutover plan,
a rollback, measured downtime and no lost data".

The workload is the tic-tac-toe app from project 4
([joheee/TicTacToeCICD](https://github.com/joheee/TicTacToeCICD)), which today
runs on AWS (EC2 + ECR + SSM, built by
[joheee/TicTacToeInfra](https://github.com/joheee/TicTacToeInfra), about $25 a
month) at `tictactoe.johe.my.id`. This project moves it, with its PostgreSQL
data, to a **DigitalOcean Droplet**, then retires the AWS stack.

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
   bucket for backups with a 7-day lifecycle rule. State is local while
   testing, then a hand-made Space. Applied locally; no tokens in GitHub.
2. **Hardened server from cloud-init.** Ubuntu LTS, non-root `deploy` user,
   SSH keys only (no passwords, no root login), UFW, fail2ban,
   unattended-upgrades, Docker + Compose plugin, swap file. SSH is **not open
   to the internet**: admin and CI reach the VM over Tailscale.
3. **Same app image via GHCR.** TicTacToeCICD builds the `linux/amd64` image
   and pushes it to GHCR (free) as well as ECR during the migration. Same
   Compose file (db → migrate → app) and Caddy with Let's Encrypt as on EC2.
   DigitalOcean has no ARM Droplets, so no arm64 build is needed.
4. **CI/CD to the VPS.** A deploy workflow that joins the tailnet, pulls the
   SHA-tagged image over SSH, runs the same smoke test and rolls back to
   `last_good_tag` on failure, reusing the project 4 scripts. Secrets live in
   GitHub Environment secrets, written to `.env` on the VM with mode 600.
5. **Edge: Cloudflare.** DNS for `johe.my.id` on Cloudflare, proxied record,
   Full (strict) TLS, WAF managed rules and a rate-limit rule on the login and
   register endpoints. Caddy trusts Cloudflare's ranges (`trusted_proxies`) so
   the app's per-IP rate limit sees the real client address.
6. **Backups and monitoring.** Nightly `pg_dump` to Spaces with 7-day
   retention and one tested restore. Uptime Kuma (or a free external check)
   alerting by email or Telegram.
7. **Rehearsed cutover with rollback.** A written runbook: lower DNS TTL,
   rehearse on `vps.tictactoe.johe.my.id`, freeze writes, final `pg_dump` from
   EC2 and restore on the VM, row-count check, flip DNS, smoke test, watch.
   Rollback = flip DNS back to the EC2 Elastic IP (kept running 48 hours).
   Downtime is measured during the rehearsal and the real cutover.
8. **Retire AWS and write it up.** After 48 quiet hours, `terraform destroy`
   in TicTacToeInfra. README as a client case study: before/after diagram,
   runbook, measured downtime, rollback test, monthly cost before (about $25)
   and after (about $17), and how to run the same kit on Hetzner or another VPS.

## Out of scope

- Terraform for GitHub-to-DigitalOcean authentication. DigitalOcean has no
  OIDC federation, so Terraform runs locally with an API token and CI only
  checks fmt, validate and tflint.
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

- Budget: about $17 a month (Droplet ~$12, Spaces $5). Add a DigitalOcean
  billing alert ($5 or $10). Flag anything that adds cost before adding it.
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
| 1 | DigitalOcean account, API token and Spaces key, Terraform for VPC + firewall + Droplet + reserved IP, cloud-init hardening, Tailscale (verify before closing SSH). Image to GHCR. App runs on the VM by IP. |
| 2 | Caddy + HTTPS, Cloudflare DNS/WAF/rate limit, deploy workflow with smoke test and rollback, nightly `pg_dump` to Spaces with a tested restore, Uptime Kuma. Rehearsal on `vps.` subdomain with downtime measured. |
| 3 | Real cutover and rollback test, 48-hour watch, AWS destroyed, README case study with diagram and cost table, Upwork portfolio entry. |

## Tools and software

DigitalOcean (Droplet, Cloud Firewall, reserved IP, Spaces) · Terraform
(>= 1.12) with the DigitalOcean provider · cloud-init · Ubuntu LTS · Docker +
Compose · Caddy · Let's Encrypt · Cloudflare DNS, WAF and rate limiting ·
Tailscale · GitHub Actions · GitHub Container Registry · UFW · fail2ban ·
PostgreSQL (`pg_dump`) · Uptime Kuma · tflint · shellcheck · draw.io or Mermaid

## Definition of done

- [ ] `terraform apply` creates the VPC, Cloud Firewall, Droplet, reserved IP and Spaces bucket within the budget.
- [ ] The VM is hardened by cloud-init: key-only SSH reachable only over Tailscale, UFW, fail2ban, unattended-upgrades.
- [ ] The app image builds for amd64 and is pulled from GHCR.
- [ ] A merge to `main` deploys to the VPS, smoke-tests and rolls back on failure (one logged rollback).
- [ ] Cloudflare proxies the domain with Full (strict) TLS, WAF and a login rate limit.
- [ ] Nightly `pg_dump` lands in Spaces and one restore has been tested.
- [ ] Uptime monitoring alerts when the app is down.
- [ ] Rehearsal and real cutover done with downtime measured; DNS rollback tested.
- [ ] AWS stack destroyed after 48 quiet hours.
- [ ] README has before/after diagrams, the runbook, downtime numbers, cost before and after, and how to reuse the kit on Hetzner or another VPS.
