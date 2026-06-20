# Nexinus — node status & bootstrap scripts

A solo-built monitoring setup for a few rented servers, plus the scripts used to
stand them up. Built in public by one person, on a limited budget. Some nodes
are live; some are not. This README states the real status plainly — no hype.

## What this is

- A small set of servers (Hetzner) in different regions.
- A status page that checks whether each one actually responds, and shows the
  honest result: **up**, **down**, or **unknown** (never a faked green light).
- The shell scripts used to configure those servers (health endpoints, TLS).

That's it. It's infrastructure monitoring with one rule: **don't show a server
as working unless it actually answers.**

## Current status (as last measured)

| Node | Region | Status |
|------|--------|--------|
| Valkyrie | Oregon, US | up |
| xinus.one | hosted | up |
| Monarch (Bolt endpoint) | Singapore | up |
| Monarch (own domain) | Singapore | not serving yet |
| Tesseract-A | Falkenstein, DE | not serving yet |
| XinUS-Lens | Nuremberg, DE | powered off |

Live feed: [`status.json`](./status.json) · Status page: `index.html` (GitHub Pages).
The status page refuses to show stale data — if a reading is older than its
freshness window, it shows **unknown** instead of the last known color.

## Files

- `setup.sh` — installs a health endpoint + enables SSH login on a fresh server.
- `monarch-health.sh` — standalone HTTP `/health` (systemd, no reverse proxy).
- `tesseract-a-setup.sh` — Caddy + auto-TLS `/health` for nexinus.net.
- `zapier-refresh.js` — scheduled probe that rewrites `status.json` from an
  independent vantage point. Stamps each node only when its own probe completes.
- `status.json` — the current measured snapshot (per-node timestamps).
- `index.html` — externally-hosted status page (freshness-gated).

## How to use a setup script

On the target server, as root:

```
curl -fsSL https://raw.githubusercontent.com/tychomorr-ui/nexinus-bootstrap/main/setup.sh | bash
```

Requires ports 80 and 443 open in the server's firewall (and 22 for SSH).

## Honesty rules this repo follows

- A status is only shown as "up" if a real check confirmed it recently.
- Stale data shows "unknown," never the last known color.
- No secrets are committed. Scripts reference credentials; they never embed them.
