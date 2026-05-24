# my-ai-box

> Your AI assistant on your own VPS in 90 seconds. Bring your OpenAI / Anthropic / DeepSeek key.

`my-ai-box` is a one-command installer that deploys a self-hosted AI assistant on your Linux VPS, configured to use your own LLM API key. No local models. No GPU. Cheap VPS, your data, your keys.

> **Status (v0.1):** Open WebUI + Caddy/TLS work end-to-end. LibreChat / AnythingLLM / Aider and more extras (PWA, voice, Telegram, web search, backups) ship in subsequent releases.

## Install

```bash
curl -fsSL https://get.my-ai-box.sh | sudo bash
```

> Worried about `curl | bash`? See [Why curl | bash?](#why-curl--bash) below for the inspect-first alternative.

The installer asks 4–6 questions, brings up containers, requests a Let's Encrypt cert, and prints your URL. Re-run `my-ai-box` later to add/remove things.

## Supported (v0.1)

| | |
|---|---|
| **Assistant** | Open WebUI |
| **Extras** | Caddy + automatic TLS |
| **Providers** | OpenAI, Anthropic, DeepSeek, OpenRouter (BYO API key) |
| **Distros** | Ubuntu 22.04 / 24.04, Debian 12 |

More assistants and extras coming — see the roadmap.

## What you'll need

- A fresh Linux VPS (Ubuntu 22.04 / 24.04, or Debian 12).
  - Minimum: 2 vCPU, 2 GB RAM, 5 GB free disk (installer will warn if you're under).
  - Recommended: 2 vCPU, 4 GB RAM, 80 GB disk (for sustained use + container data).
- A domain pointed at your VPS (for HTTPS via Let's Encrypt).
- An API key from one of: OpenAI, Anthropic, DeepSeek, OpenRouter.

## Recommended VPS providers

Any VPS meeting the minimums works. We test on:

- **Hetzner CX22** — €4.59/mo, EU. Fast NVMe, generous bandwidth.
- **Zergrush KVM2** — $5/mo, US/EU. *The author runs this project on Zergrush; buying here helps fund maintenance. No referral codes, no markup.*
- **DigitalOcean Basic** — $6/mo, multi-region.

## Where your API keys live

API keys are stored in `/opt/my-ai-box/.env`, mode `0600`, owned `root:root`. Docker reads them at compose-up time. They are never logged, never echoed to your terminal, and shredded on `my-ai-box uninstall`.

You can verify the file is locked down:

```bash
sudo stat -c '%a %u:%g %n' /opt/my-ai-box/.env
# expected: 600 0:0 /opt/my-ai-box/.env
```

## Why `curl | bash`?

The single-command install is what makes the project usable for non-experts. If you'd rather inspect the script first:

```bash
curl -fsSL https://get.my-ai-box.sh -o install.sh
less install.sh        # read it
sudo bash install.sh
```

The script is the same one you'd execute via the pipe — there's no different path.

## Roadmap (rough)

- **v0.2** — LibreChat, AnythingLLM, Aider assistants.
- **v0.3** — Extras: voice (Whisper + Piper), PWA + push, Telegram bridge, SearXNG, daily backups.
- **v1.0** — Polish, logo/GIF, launch.

No commitments — these are working notes.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT — see [LICENSE](LICENSE).
