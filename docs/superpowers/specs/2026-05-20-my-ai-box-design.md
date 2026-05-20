# my-ai-box — Design Spec

- **Date:** 2026-05-20
- **Status:** Draft, pending user approval
- **Author:** brainstorm with Tudor (thestick613@gmail.com)
- **Goal of this doc:** Lock the architecture and scope for v1 of `my-ai-box` before writing an implementation plan.

---

## 1. Summary

`my-ai-box` is a single-file bash installer + interactive wizard that deploys one of four curated open-source AI assistants on a fresh Linux VPS, configured to use the user's own LLM API key (OpenAI / Anthropic / DeepSeek / OpenRouter). It is shaped like a VPN install script: `curl | bash` one-liner, plain `read -p` prompts with sensible defaults, and a re-runnable menu for adding/removing things post-install.

The project is published on GitHub under MIT license. The README softly recommends a small set of VPS providers; the author runs the project on **Zergrush** and discloses that. There is **zero marketing inside the installer itself**.

**Tagline:** *Your AI assistant on your own VPS in 90 seconds. Bring your OpenAI / Anthropic / DeepSeek key.*

---

## 2. Goals and non-goals

### Goals
- One-liner `curl -fsSL get.my-ai-box.sh | bash` produces a working, HTTPS-fronted AI assistant in under two minutes on a $5/mo VPS.
- Beginner-friendly defaults; power-user-friendly env-var overrides for full non-interactive operation.
- Idempotent: re-running enters a management menu instead of clobbering state.
- Curated assistant choices that don't overlap — chat, team chat, RAG, coding.
- Six optional sidecar "extras" (TLS, voice, PWA, Telegram, web search, backups) composable per-install.
- Earn GitHub stars through trust signals: shellcheck-passing, MIT, transparent secret handling, no telemetry, documented `curl|bash` alternative.
- Provide a soft, honest funnel to Zergrush hosting via the README without compromising trust.

### Non-goals (explicit)
- No local LLMs. No Ollama, no GPU support. v1 is BYO API key only.
- No support for OpenClaw (security and quality concerns).
- No web UI for the installer — the wizard is terminal-only.
- No multi-tenant or SaaS mode.
- No auto-update daemon — updates happen on demand via the menu.
- No telemetry of any kind.
- No Windows / macOS installer. Linux VPS only.
- No browser-control / computer-use agents in v1.
- No native iOS/Android apps — PWA is the mobile story.

---

## 3. Target user

Medium-skill VPS user. Can SSH into a fresh Ubuntu/Debian VPS and run a command. Does not necessarily know Docker, Caddy, Let's Encrypt, or compose syntax. Already has at least one LLM API key (OpenAI / Anthropic / DeepSeek / OpenRouter). Wants:

- A private, self-hosted AI UI that doesn't see their data.
- An assistant their family/team can also use, optionally.
- Optional voice and mobile access.
- The ability to walk away from a SaaS chat product.

Power users get full non-interactive control via env vars; everything the wizard prompts for has a matching `MY_AI_BOX_*` variable.

---

## 4. Supported assistants (v1)

| # | Name | Use case | Stack | Resource floor |
|---|------|----------|-------|----------------|
| 1 | **Open WebUI** | Personal ChatGPT-style chat | Single container | Starter (2 vCPU / 4 GB) |
| 2 | **LibreChat** | Team chat, SSO, multi-user | App + MongoDB + Meilisearch | Standard (4 vCPU / 8 GB) |
| 3 | **AnythingLLM** | Chat with your documents (RAG) | Single container + LanceDB | Starter |
| 4 | **Aider** | CLI pair-programming, no web UI | Long-running container; user invokes `my-ai-box aider <args>` to `docker exec` into it. Files live under `/opt/my-ai-box/data/aider/workspace/`. | Starter |

All four work natively with cloud LLM APIs in BYO-API-key mode.

**Aider note:** Aider is included for users who already work on their VPS via SSH (Code-Server / Coder users, or git checkouts on the VPS). For developers who code locally, `pip install aider-chat` on their workstation is simpler — but the VPS path is valid for remote-dev workflows and keeps the assistant set coherent.

Out of v1 by deliberate scope: Lobe Chat, Khoj, n8n, OpenClaw, Cline, Continue, Bolt.diy, h2oGPT.

---

## 5. Supported extras (v1)

| # | Extra | Description | Implies |
|---|-------|-------------|---------|
| 1 | **Caddy + TLS** | Reverse proxy with automatic Let's Encrypt | On by default *if a domain is provided*; otherwise the assistant is exposed on the VPS IP over HTTP with a warning |
| 2 | **PWA + push** | Manifest + service worker so the web UI installs as an app on mobile | Requires Caddy + domain |
| 3 | **Voice (Whisper + Piper)** | Whisper.cpp STT + Piper TTS containers, wired to the assistant when supported | Adds ~6 GB disk for models |
| 4 | **Telegram bridge** | Generic LLM-to-Telegram bot wired to the chosen assistant's API | Requires bot token from BotFather. Webhook mode used when a domain is set; polling mode used otherwise (no domain required) |
| 5 | **Web search (SearXNG)** | SearXNG container as a search backend for the assistant | None |
| 6 | **Daily backups** | `restic` snapshot of `data/` + `.env` to S3-compatible storage | Requires bucket + key |

The wizard composes a final `compose.yml` (and possibly `compose.override.yml`) from the chosen assistant template + the chosen extras' overlay snippets.

---

## 6. Recommended VPS tiers

The README documents two tiers; the hosting partner stocks them at competitive prices.

| Tier | Specs | Fits |
|------|-------|------|
| **Starter** | 2 vCPU, 4 GB RAM, 80 GB NVMe, 2 TB BW | Open WebUI / AnythingLLM / Aider + a couple of extras |
| **Standard** | 4 vCPU, 8 GB RAM, 160 GB NVMe, 3 TB BW | LibreChat, or any assistant + voice + Telegram + RAG |

Any VPS meeting these floors works. The README lists Hetzner CX22 (€4.59/mo), Zergrush KVM2 ($5/mo), and DigitalOcean Basic ($6/mo) by name, with a one-line disclosure that the author runs on Zergrush.

---

## 7. User-facing flows

### 7.1 First-time install (interactive)

The one-liner produces a single guided wizard. Prompts (in order):

1. Distro / resource detection (read-only, displayed for trust).
2. Assistant choice (1–4, default 1).
3. Domain for HTTPS (or `skip` for IP-only HTTP with a warning).
4. Email for Let's Encrypt.
5. LLM provider choice (OpenAI / Anthropic / DeepSeek / OpenRouter / skip).
6. API key (hidden input via `read -s`).
7. Extras: each presented as `y/N` with sensible defaults. Caddy is only offered if a domain was provided at step 3; if skipped, Caddy and any HTTPS-dependent extras (PWA, Telegram webhook mode) are silently disabled and the wizard explains why.
8. Summary confirmation (Y/n).
9. Container pull + compose up + TLS issuance.
10. Done message: URL, log path, "to manage later, run `my-ai-box`", soft pointer to README's VPS section.

Total wall-clock target: 90 seconds on a 2 vCPU VPS with a warm Docker cache, ~3 minutes cold.

### 7.2 Re-running (the menu)

`my-ai-box` (or re-piping the curl one-liner) detects an existing install at `/opt/my-ai-box` and shows a menu:

```
1) Add an extra
2) Remove an extra
3) Add another assistant (side-by-side; runs a resource-check first)
4) Change API key / provider
5) Update everything (git pull + docker compose up -d)
6) Show status / logs
7) Backup now / restore
8) Uninstall
0) Exit
```

Item 3 ("add another assistant side-by-side") checks free RAM and disk before proceeding; if the VPS is too small for the additional stack it warns and asks for confirmation rather than silently OOM'ing later.

Each menu item produces its own sub-wizard with the same prompt style as the install flow.

### 7.3 Non-interactive (power user)

Every prompt has a matching env var. Example:

```bash
MY_AI_BOX_ASSISTANT=open-webui \
MY_AI_BOX_DOMAIN=chat.example.com \
MY_AI_BOX_EMAIL=you@example.com \
MY_AI_BOX_PROVIDER=anthropic \
MY_AI_BOX_API_KEY=sk-ant-... \
MY_AI_BOX_EXTRAS=caddy,pwa,telegram \
MY_AI_BOX_TELEGRAM_TOKEN=1234:ABCD \
curl -fsSL get.my-ai-box.sh | bash
```

Missing required vars fall back to interactive prompts unless `MY_AI_BOX_NONINTERACTIVE=1` is set, in which case the script errors with a list of missing vars.

---

## 8. Architecture

### 8.1 Repository structure

```
my-ai-box/
├── install.sh                 # Bootstrapper, ~150 lines.
├── bin/
│   └── my-ai-box              # Wizard entrypoint, ~600 lines.
├── lib/
│   ├── distro.sh              # detect_distro, install_docker, install_pkg
│   ├── menu.sh                # render_menu, prompt_choice (plain read -p)
│   ├── compose.sh             # compose_render, compose_up, compose_down
│   ├── secrets.sh             # write_env, read_env, rotate_key, scrub_on_uninstall
│   ├── tls.sh                 # caddy_render, caddy_reload, domain_validate
│   └── state.sh               # /opt/my-ai-box/state.json read/write
├── assistants/
│   ├── open-webui/{compose.yml, install.sh, README.md, prompts.sh}
│   ├── librechat/{...}
│   ├── anythingllm/{...}
│   └── aider/{install.sh, README.md, prompts.sh}    # CLI-only, ssh-attached container
├── extras/
│   ├── caddy/{compose-overlay.yml, Caddyfile.tpl, install.sh}
│   ├── pwa/{manifest.json.tpl, sw.js, install.sh}
│   ├── voice/{compose-overlay.yml, install.sh}
│   ├── telegram/{compose-overlay.yml, bot-config.tpl, install.sh}
│   ├── searxng/{compose-overlay.yml, settings.yml.tpl, install.sh}
│   └── backups/{compose-overlay.yml, restic-wrapper.sh, install.sh}
├── tests/
│   ├── bats/                  # bats-core unit tests for lib/
│   └── e2e/                   # Multipass-based VM tests
├── README.md
└── LICENSE                    # MIT
```

### 8.2 Bootstrap flow

`install.sh` is intentionally tiny. It does only what must happen before the modular wizard can run:

1. Run as `set -euo pipefail`.
2. Detect distro via `/etc/os-release`. Hard-stop if not Ubuntu 22.04/24.04 or Debian 12.
3. Verify required tools: `curl`, `git`, `tar`. Install missing ones with the native package manager.
4. Install Docker via `get.docker.com` if absent. The script assumes root (via `sudo`); it does **not** add the invoking user to the `docker` group by default, because docker-group membership is effectively root and users should opt into that themselves with `sudo usermod -aG docker $USER` if they want unprivileged `docker` CLI access.
5. Clone the repo (or unpack a pinned-version tarball if offline-friendly is requested) into `/opt/my-ai-box`.
6. Pin to a specific tag if `MY_AI_BOX_VERSION` is set; else `main`.
7. `exec /opt/my-ai-box/bin/my-ai-box install "$@"`.

### 8.3 Runtime layout on the VPS

```
/opt/my-ai-box/
├── (everything from the repo)
├── state.json               # what's installed; safe to back up
├── .env                     # all secrets, mode 0600, root:root
├── compose.yml              # generated; never hand-edit
├── compose.override.yml     # generated per active extras
└── data/                    # bind-mounted persistent volumes
    ├── open-webui/
    ├── caddy/
    └── ...

/var/log/my-ai-box/
└── install.log              # last install/menu-action log
```

`state.json` schema (example):

```json
{
  "schema_version": 1,
  "assistant": "open-webui",
  "extras": ["caddy", "pwa", "telegram"],
  "domain": "chat.example.com",
  "provider": "anthropic",
  "created_at": "2026-05-20T12:00:00Z",
  "version": "v0.1.0"
}
```

### 8.4 Data flow

```
prompts (interactive or env) -> state.json + .env
                              -> assistants/<x>/compose.yml + extras/<y>/compose-overlay.yml
                              -> docker compose -f compose.yml -f compose.override.yml up -d
                              -> health check + URL print
```

### 8.5 Separation of state and secrets

`state.json` is what's installed (assistant, extras, domain, version). It is safe to log, copy to a support thread, and back up. `.env` is what is secret (API keys, Telegram tokens, S3 credentials, Let's Encrypt account email). It is never logged, has mode `0600`, and is shredded on uninstall. Conflating these is how credential leaks happen, so the boundary is enforced in `lib/secrets.sh` (only it reads or writes `.env`; everything else gets values via function calls or env vars from `docker compose`).

---

## 9. Reverse proxy, TLS, and domains

- **Caddy** is the default reverse proxy: single binary, auto-TLS via Let's Encrypt, containerized so users never edit Caddyfiles by hand.
- The wizard validates the domain resolves to the VPS public IP before requesting a certificate. If not, it prints the IP to set in DNS and offers to retry or skip TLS.
- A user can skip the domain entirely; the wizard then serves on the VPS IP over HTTP with a clear warning. PWA and Telegram extras are blocked in this mode (they need HTTPS callbacks).
- TLS cert lifecycle is fully delegated to Caddy. Renewal is automatic.
- The wizard offers to enable `ufw` (Y default) opening 22, 80, 443.

---

## 10. Secret handling

- All secrets live in `/opt/my-ai-box/.env`, mode `0600`, owned `root:root`. Docker (running as root) consumes them via `env_file:` in compose.
- `my-ai-box` always runs as root (re-invokes itself with `sudo` if needed). No non-root path to read `.env`.
- API key prompts use `read -s` so the key never appears on screen.
- If the user chose "Skip" at the provider prompt (intending to configure the API key inside the assistant's web UI later), the API-key prompt is skipped entirely and `.env` simply omits that variable.
- Success messages reference the **provider name**, never the key.
- `my-ai-box change-key` rewrites only the affected variable.
- `my-ai-box uninstall` asks: "delete data + secrets? [y/N]"; if yes, `shred -u /opt/my-ai-box/.env` then `rm -rf /opt/my-ai-box`.
- The README has a section called **"Where your API keys live"** that points at `/opt/my-ai-box/.env` with a one-line `stat -c '%a'` check.

---

## 11. Error handling and robustness

- `set -euo pipefail` at the top of every shell file.
- Tailscale's installer is the reference for distro detection and clean exits.
- Distro support v1: Ubuntu 22.04, Ubuntu 24.04, Debian 12. Detection via `/etc/os-release`. Unsupported distro = exit with a message and a link to GitHub Discussions.
- Idempotency: re-running on a partial install resumes (state.json + a "phase" marker tells us where we left off).
- Port conflicts (80/443/3000/etc.) checked before `compose up`; offer to remap.
- DNS / TLS failures: explicit, actionable messages. Fall back to self-signed only if the user opts in; never silently.
- All output goes to both stdout and `/var/log/my-ai-box/install.log`. The log-mirror tee is suppressed for any `read -s` input (API keys, tokens, bot tokens) so secrets never reach disk via the log path. The wizard prints the log path on any non-zero exit.
- `my-ai-box doctor` (planned subcommand) prints a system report: distro, Docker version, ports in use, container health, TLS cert expiry. This is what users paste into bug reports.

---

## 12. Testing strategy

- **`shellcheck`** on every shell file. CI fails on any warning.
- **`bats-core`** unit tests for `lib/*.sh` (pure functions like `parse_state`, `render_compose`, `validate_domain`).
- **End-to-end tests** in Multipass VMs: Ubuntu 22.04, Ubuntu 24.04, Debian 12. Each runs the full installer non-interactively across a representative matrix:
  - Open WebUI + Caddy + PWA
  - LibreChat + Caddy
  - AnythingLLM + Caddy + voice
  - Aider only
- E2E asserts: container is healthy, HTTP/HTTPS returns 200, `state.json` matches expected, `.env` is mode `0600`.
- Tests run nightly + on PRs touching `assistants/` or `extras/`.

---

## 13. README structure (the star-driver)

**Above the fold, in order:**

1. Logo banner.
2. One sentence: "Your AI assistant on your own VPS in 90 seconds. Bring your OpenAI / Anthropic / DeepSeek key."
3. Animated GIF / screencast of the 90-second install → chat → Telegram. Load-bearing.
4. Install one-liner in a copy-button code block.
5. Badges: stars, latest release, MIT license, Discord member count, shellcheck-passing, build status.
6. Discord link.

**Below the fold:**

- Features bullet list (10–12, focused).
- Supported assistants table.
- Supported extras grid with icons.
- Screenshots gallery.
- **"Recommended VPS providers"** with Hetzner / Zergrush (one-line disclosure) / DigitalOcean.
- **"Where your API keys live"** (trust signal).
- **"Why `curl | bash`?"** with the alternative `wget && less && bash` flow.
- Roadmap (high-level only — no commitments).
- Sponsors / Contributors / License.

**Launch plan:** Show HN with the GIF as the highlight. Cross-post to r/selfhosted and r/LocalLLaMA (positioned there as "no GPU needed"). HN post timed for a Tuesday/Wednesday US morning. Discord set up before launch; pinned welcome.

---

## 14. Open questions

- Logo / icon: needs commissioning before launch.
- Domain ownership: who registers `my-ai-box.sh` and `get.my-ai-box.sh`? (Author.)
- Support model: GitHub Discussions + Discord. Author commits to triaging issues weekly.
- Monetization beyond the Zergrush funnel: open. Could be GitHub Sponsors later; not in v1.
- License of bundled compose templates: each assistant's license is respected; the templates we author are MIT. Documented in `assistants/<x>/LICENSE-NOTES.md`.

---

## 15. Success criteria for v1

- One-liner works on a stock Ubuntu 22.04 / 24.04 / Debian 12 VPS with 2 vCPU / 4 GB / 80 GB.
- Install completes in ≤ 3 minutes on a 2 vCPU VPS (cold cache).
- All four assistants reachable on `https://<domain>` after install with a valid Let's Encrypt cert.
- Re-running enters the management menu without prompting reinstall.
- `uninstall` removes containers, data, and secrets cleanly (verified by E2E).
- `shellcheck` passes on the full tree.
- README scores well against the high-star template checklist (logo, GIF, one-liner, badges, Discord, providers section, trust pages).

---

## 16. Next steps after this spec is approved

1. Hand off to `writing-plans` skill to produce a step-by-step implementation plan.
2. The plan will break into milestones: bootstrap → first assistant (Open WebUI) end-to-end → Caddy/TLS → remaining assistants → extras → tests → README + launch assets.
3. Each milestone gets its own session.

---

*End of spec. Ready for user review.*
