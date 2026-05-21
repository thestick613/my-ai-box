# Open WebUI module

Open WebUI is a self-hosted chat UI. In my-ai-box it runs in BYO-API-key mode, calling cloud LLM providers (OpenAI / Anthropic / DeepSeek / OpenRouter).

- Upstream: https://github.com/open-webui/open-webui
- Container: `ghcr.io/open-webui/open-webui:0.6.32`
- HTTP upstream for reverse proxy: `open-webui:8080`
- Data volume: `./data/open-webui` (mounted at `/app/backend/data` in the container)
- Environment variables consumed (all optional; populated from `/opt/my-ai-box/.env`):
  - `OPENAI_API_KEY`, `OPENAI_API_BASE_URL`
  - `ANTHROPIC_API_KEY`
  - `DEEPSEEK_API_KEY`
  - `OPENROUTER_API_KEY`

Open WebUI also exposes its own admin UI for configuring providers, RAG sources, MCP servers, voice, and more. The wizard only sets the initial provider key; everything else is configured in the web UI.
