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
data, to an **Oracle Cloud Always Free** VM, then retires the AWS stack.

## The pitch (what a client buys)

> "Move your app from AWS/Render/Heroku to a VPS, 3 days." Containerised app
> on a hardened Ubuntu server, Caddy with automatic HTTPS, Cloudflare DNS and
> WAF in front, CI/CD that deploys and rolls back, nightly database backups,
> uptime monitoring, and a rehearsed cutover with a rollback plan. Before and
> after cost in the README.

It matches jobs like "Render → DigitalOcean migration", "Medusa on OVH VPS",
"Hetzner VPS deployment", "Oracle Cloud → GoDaddy" and "Azure → low-cost AWS".
The kit is provider-agnostic: only the Terraform for the VM is Oracle-specific,
everything from cloud-init upward runs on any Ubuntu VPS.

## Why Oracle Cloud Always Free

| Option | Cost | Fit |
|---|---|---|
| **Oracle Cloud Always Free (Ampere A1)** | $0, no time limit | 2 ARM OCPUs and 12 GB RAM (cut from 4/24 on 15 Jun 2026), block storage, Object Storage, reserved public IP. Card needed to sign up, not charged. Terraform provider exists. |
| Hetzner Cloud CAX11 / CX23 | about €6 a month (after the June 2026 price rise), EU only at that price; Singapore starts at €15.49 | The "real client" VPS. Good fallback if Oracle has no capacity. |
| DigitalOcean droplet | from $6 a month; new accounts usually get time-limited credit | Common in client posts, but not free after the credit ends. |
| Google Cloud e2-micro | free, US regions only, 1 GB RAM | Too small and too far away. |
| AWS free plan | credits for a few months | Not a migration *away* from AWS. |

Known Oracle risks, handled in the plan: A1 capacity can be "out of host
capacity" in busy regions (retry, or use Hetzner); idle Always Free instances on
free-only accounts can be reclaimed (the app, Uptime Kuma and backups keep it
busy enough, and upgrading to Pay-As-You-Go stops reclamation while staying
$0 within limits); the home region is permanent, so pick the nearest one once.
The image must be built for `arm64`.

## Objectives

1. **VM in Terraform.** OCI provider: compartment, VCN, public subnet,
   security list allowing only 80 and 443 from anywhere, one Ampere A1 VM
   (within the free 2 OCPU / 12 GB), reserved public IP. State in OCI Object
   Storage (free tier). Applied locally; no OCI keys in GitHub.
2. **Hardened server from cloud-init.** Ubuntu LTS, non-root `deploy` user,
   SSH keys only (no passwords, no root login), UFW, fail2ban,
   unattended-upgrades, Docker + Compose plugin, swap file. SSH is **not open
   to the internet**: admin and CI reach the VM over Tailscale.
3. **Same app, multi-arch image.** TicTacToeCICD builds `linux/amd64` and
   `linux/arm64` images and pushes them to GHCR (free) as well as ECR during
   the migration. Same Compose file (db → migrate → app) and Caddy with
   Let's Encrypt as on EC2.
4. **CI/CD to the VPS.** A deploy workflow that joins the tailnet, pulls the
   SHA-tagged image over SSH, runs the same smoke test and rolls back to
   `last_good_tag` on failure, reusing the project 4 scripts. Secrets live in
   GitHub Environment secrets, written to `.env` on the VM with mode 600.
5. **Edge: Cloudflare.** DNS for `johe.my.id` on Cloudflare, proxied record,
   Full (strict) TLS, WAF managed rules and a rate-limit rule on the login and
   register endpoints.
6. **Backups and monitoring.** Nightly `pg_dump` to OCI Object Storage with
   7-day retention and one tested restore. Uptime Kuma (or a free external
   check) alerting by email or Telegram.
7. **Rehearsed cutover with rollback.** A written runbook: lower DNS TTL,
   rehearse on `vps.tictactoe.johe.my.id`, freeze writes, final `pg_dump` from
   EC2 and restore on the VM, row-count check, flip DNS, smoke test, watch.
   Rollback = flip DNS back to the EC2 Elastic IP (kept running 48 hours).
   Downtime is measured during the rehearsal and the real cutover.
8. **Retire AWS and write it up.** After 48 quiet hours, `terraform destroy`
   in TicTacToeInfra. README as a client case study: before/after diagram,
   runbook, measured downtime, rollback test, monthly cost before (about $25)
   and after ($0), and how to run the same kit on Hetzner or DigitalOcean.

## Out of scope

- Oracle-to-GitHub OIDC for Terraform. OCI workload identity federation is
  heavy for one VM; Terraform runs locally, CI only checks fmt, validate and
  tflint. Noted as a stretch.
- Kubernetes, k3s or multiple servers. One VM, Compose.
- High availability or zero-downtime cutover. A few minutes of planned
  downtime with a write freeze is the honest small-business answer.
- Managed Postgres. The database stays in Compose, as on EC2.
- Point-in-time recovery and pgBackRest. That's project 3.
- A screen recording. As in project 4, the logged workflow runs, the runbook
  and the measured downtime are the proof.

## Constraints

- Free means free: stay within Oracle Always Free limits (A1 total of 2 OCPU /
  12 GB across the tenancy, Object Storage within the free allowance). Add a
  $1 budget alert in OCI.
- The current AWS stack stays up until the cutover is proven; destroying it is
  the last step and is done only when asked.
- The app repo keeps working on AWS until cutover day. VPS changes there are
  additive (new workflow, multi-arch build) until AWS is retired.

## Plan (3 days)

| Day | Work |
|---|---|
| 1 | Oracle account and home region, Terraform for VCN + A1 VM + Object Storage state, cloud-init hardening, Tailscale. Multi-arch image to GHCR. App runs on the VM by IP. |
| 2 | Caddy + HTTPS, Cloudflare DNS/WAF/rate limit, deploy workflow with smoke test and rollback, nightly `pg_dump` to Object Storage with a tested restore, Uptime Kuma. Rehearsal on `vps.` subdomain with downtime measured. |
| 3 | Real cutover and rollback test, 48-hour watch, AWS destroyed, README case study with diagram and cost table, Upwork portfolio entry. |

## Tools and software

Oracle Cloud Infrastructure (Always Free, Ampere A1) · Terraform (>= 1.12) with
the OCI provider · cloud-init · Ubuntu LTS · Docker + Compose · Caddy · Let's
Encrypt · Cloudflare DNS, WAF and rate limiting · Tailscale · GitHub Actions ·
GitHub Container Registry · UFW · fail2ban · PostgreSQL (`pg_dump`) · OCI Object
Storage · Uptime Kuma · tflint · draw.io or Mermaid

## Definition of done

- [ ] `terraform apply` creates the VCN, security list and A1 VM inside Always Free limits; state is in OCI Object Storage.
- [ ] The VM is hardened by cloud-init: key-only SSH reachable only over Tailscale, UFW, fail2ban, unattended-upgrades.
- [ ] The app image builds for amd64 and arm64 and is pulled from GHCR.
- [ ] A merge to `main` deploys to the VPS, smoke-tests and rolls back on failure (one logged rollback).
- [ ] Cloudflare proxies the domain with Full (strict) TLS, WAF and a login rate limit.
- [ ] Nightly `pg_dump` lands in Object Storage and one restore has been tested.
- [ ] Uptime monitoring alerts when the app is down.
- [ ] Rehearsal and real cutover done with downtime measured; DNS rollback tested.
- [ ] AWS stack destroyed after 48 quiet hours.
- [ ] README has before/after diagrams, the runbook, downtime numbers, cost before and after, and how to reuse the kit on Hetzner or DigitalOcean.
