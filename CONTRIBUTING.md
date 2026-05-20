# Contributing to my-ai-box

Thanks for your interest. This project follows a simple workflow.

## Quick start for contributors

1. Fork the repo.
2. Clone your fork and create a branch off `main`.
3. Make changes following the conventions below.
4. Ensure `shellcheck` passes locally: `shellcheck $(find . -name '*.sh' -not -path './tests/bats/lib/*')`
5. Ensure bats tests pass locally: `bats tests/bats/`
6. Open a PR. The CI must be green to merge.

## Conventions

- Shell scripts target Bash 4+ and start with `set -euo pipefail`.
- Filenames and directories are lowercase-with-hyphens.
- Functions use `snake_case`.
- No `latest` Docker tags — pin to a digest or explicit version.
- Commit messages: `feat:`, `fix:`, `test:`, `docs:`, `ci:`, `chore:`.

## Adding an assistant or extra

Each assistant lives in `assistants/<name>/` and each extra in `extras/<name>/`. Both follow the same template — see `assistants/open-webui/` and `extras/caddy/` for working examples. The wizard auto-discovers new directories; no central registration is needed.

## Reporting issues

Use GitHub Issues with the templates provided.
