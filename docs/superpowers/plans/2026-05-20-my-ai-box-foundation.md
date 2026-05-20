# my-ai-box Foundation Implementation Plan (Plan 1 of 4)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a working `curl | bash` installer that deploys Open WebUI behind Caddy+TLS on a fresh Ubuntu/Debian VPS, configured to use the user's own LLM API key, with the bootstrapper, library helpers, state/secret management, and test harness in place to support adding the remaining three assistants and five extras in later plans.

**Architecture:** Bootstrapper `install.sh` (~150 lines) clones a modular repo to `/opt/my-ai-box`, then execs `bin/my-ai-box`, which is the wizard entrypoint. Helpers live in `lib/*.sh`. Each assistant and extra is a self-contained subdirectory with a compose template and a small install hook. State is `state.json`, secrets are `.env` mode `0600` root:root. Reverse proxy/TLS is Caddy via Let's Encrypt. Tests use bats-core for unit tests on `lib/` and Multipass-driven VMs for end-to-end. CI is GitHub Actions running shellcheck + bats on every push.

**Tech Stack:** Bash 4+, Docker Engine, Docker Compose v2, Caddy (containerized), Open WebUI (containerized), bats-core, shellcheck, jq, Multipass (E2E), GitHub Actions.

**Out of scope for this plan (deferred to Plans 2-4):** LibreChat, AnythingLLM, Aider assistants; PWA/Voice/Telegram/SearXNG/Backups extras; logo/GIF; launch posts. The architecture lets these slot in as new subdirectories without changing foundation code.

**Repo conventions:** Lowercase-with-hyphens filenames and directories. `set -euo pipefail` at the top of every script. Functions use `snake_case`. No `latest` Docker tags — pin to a specific digest or version. Commit message format: `feat:`, `fix:`, `test:`, `docs:`, `ci:`, `chore:`.

**Placeholder note:** Where the GitHub user/org appears, use `<USER>` until the user provides their handle. Where a real domain like `get.my-ai-box.sh` appears, leave the placeholder; the user will register it before launch. Tasks that reference these note it explicitly.

---

## Phase A: Project bootstrap

### Task A1: Initialize git repo and root files

**Files:**
- Create: `/Users/tudoraursulesei/own-ai-assistant/.git/` (via `git init`)
- Create: `/Users/tudoraursulesei/own-ai-assistant/LICENSE`
- Create: `/Users/tudoraursulesei/own-ai-assistant/.gitignore`
- Create: `/Users/tudoraursulesei/own-ai-assistant/.editorconfig`
- Create: `/Users/tudoraursulesei/own-ai-assistant/README.md` (skeleton)

- [ ] **Step 1: Initialize git repo**

Run: `cd /Users/tudoraursulesei/own-ai-assistant && git init -b main`
Expected: `Initialized empty Git repository in .../.git/`

- [ ] **Step 2: Create LICENSE (MIT)**

Create `LICENSE`:

```
MIT License

Copyright (c) 2026 <author name>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 3: Create .gitignore**

Create `.gitignore`:

```
# Local runtime artifacts that should never be committed
.env
.env.*
state.json
data/
compose.yml
compose.override.yml
*.log

# Editor / OS noise
.DS_Store
.idea/
.vscode/
*.swp

# Test artifacts
.bats-tmp/
test-output/
tests/bats/lib/bats-*/   # bats deps installed locally
```

- [ ] **Step 4: Create .editorconfig**

Create `.editorconfig`:

```
root = true

[*]
end_of_line = lf
insert_final_newline = true
charset = utf-8
trim_trailing_whitespace = true

[*.{sh,bash,bats}]
indent_style = space
indent_size = 2

[*.md]
trim_trailing_whitespace = false

[Makefile]
indent_style = tab
```

- [ ] **Step 5: Create README.md skeleton**

Create `README.md`:

```markdown
# my-ai-box

> Your AI assistant on your own VPS in 90 seconds. Bring your OpenAI / Anthropic / DeepSeek key.

**Status:** under construction — see [the design spec](docs/superpowers/specs/2026-05-20-my-ai-box-design.md).

```bash
# Install (will work once Plan 1 is complete):
curl -fsSL https://get.my-ai-box.sh | bash
```

## License

MIT — see [LICENSE](LICENSE).
```

- [ ] **Step 6: Commit**

```bash
git add LICENSE .gitignore .editorconfig README.md
git commit -m "chore: initialize repo with LICENSE, .gitignore, .editorconfig, README skeleton"
```

---

### Task A2: Create the directory skeleton

**Files:**
- Create: `bin/.gitkeep`
- Create: `lib/.gitkeep`
- Create: `assistants/.gitkeep`
- Create: `extras/.gitkeep`
- Create: `tests/bats/.gitkeep`
- Create: `tests/e2e/.gitkeep`
- Create: `docs/superpowers/specs/.gitkeep` (already populated)
- Create: `docs/superpowers/plans/.gitkeep` (already populated)

- [ ] **Step 1: Create empty directories with .gitkeep**

Run:
```bash
mkdir -p bin lib assistants extras tests/bats tests/e2e
touch bin/.gitkeep lib/.gitkeep assistants/.gitkeep extras/.gitkeep tests/bats/.gitkeep tests/e2e/.gitkeep
```

- [ ] **Step 2: Commit**

```bash
git add bin lib assistants extras tests
git commit -m "chore: scaffold top-level directory structure"
```

---

### Task A3: Add CI config (shellcheck + bats on every push)

**Files:**
- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Create the CI workflow**

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

permissions:
  contents: read

jobs:
  shellcheck:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4
      - name: Install shellcheck
        run: sudo apt-get update && sudo apt-get install -y shellcheck
      - name: Run shellcheck
        run: |
          find . -type f \( -name '*.sh' -o -name '*.bash' \) \
            -not -path './tests/bats/lib/*' \
            -print0 | xargs -0 shellcheck -S style

  bats:
    runs-on: ubuntu-24.04
    needs: shellcheck
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: recursive
      - name: Install bats
        run: |
          sudo apt-get update
          sudo apt-get install -y bats
      - name: Install jq
        run: sudo apt-get install -y jq
      - name: Run bats tests
        run: bats tests/bats/
```

- [ ] **Step 2: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add shellcheck + bats GitHub Actions workflow"
```

---

### Task A4: Create CONTRIBUTING.md and a basic Code of Conduct

**Files:**
- Create: `CONTRIBUTING.md`
- Create: `CODE_OF_CONDUCT.md`

- [ ] **Step 1: Create CONTRIBUTING.md**

Create `CONTRIBUTING.md`:

```markdown
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
```

- [ ] **Step 2: Create CODE_OF_CONDUCT.md**

Create `CODE_OF_CONDUCT.md`:

```markdown
# Code of Conduct

This project follows the [Contributor Covenant 2.1](https://www.contributor-covenant.org/version/2/1/code_of_conduct/).

Report issues to: <author email>
```

- [ ] **Step 3: Commit**

```bash
git add CONTRIBUTING.md CODE_OF_CONDUCT.md
git commit -m "docs: add CONTRIBUTING and CODE_OF_CONDUCT"
```

---

## Phase B: Test infrastructure

### Task B1: Add bats-core as a git submodule

**Files:**
- Create: `tests/bats/lib/bats-core/` (submodule)
- Create: `tests/bats/lib/bats-assert/` (submodule)
- Create: `tests/bats/lib/bats-support/` (submodule)
- Create: `tests/bats/test_helper.bash`

- [ ] **Step 1: Add the three bats-related submodules**

```bash
git submodule add https://github.com/bats-core/bats-core.git tests/bats/lib/bats-core
git submodule add https://github.com/bats-core/bats-assert.git tests/bats/lib/bats-assert
git submodule add https://github.com/bats-core/bats-support.git tests/bats/lib/bats-support
```

- [ ] **Step 2: Pin to specific tags**

```bash
cd tests/bats/lib/bats-core && git checkout v1.11.0 && cd -
cd tests/bats/lib/bats-assert && git checkout v2.1.0 && cd -
cd tests/bats/lib/bats-support && git checkout v0.3.0 && cd -
```

- [ ] **Step 3: Create test_helper.bash**

Create `tests/bats/test_helper.bash`:

```bash
#!/usr/bin/env bash
# Shared test helper sourced by every .bats file via `load test_helper`.

bats_load_library bats-support
bats_load_library bats-assert

# Path to the repo root, computed from this file's location.
REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"
export REPO_ROOT

# Convenience: source a library file under lib/ for tests.
load_lib() {
  local name="$1"
  # shellcheck disable=SC1090
  source "${REPO_ROOT}/lib/${name}.sh"
}

# Create a per-test temp dir under BATS_TEST_TMPDIR.
setup_tmp() {
  TEST_TMP="${BATS_TEST_TMPDIR}/work"
  mkdir -p "${TEST_TMP}"
  export TEST_TMP
}
```

- [ ] **Step 4: Commit**

```bash
git add .gitmodules tests/bats/lib tests/bats/test_helper.bash
git commit -m "test: add bats-core, bats-assert, bats-support as pinned submodules + shared test helper"
```

---

### Task B2: Add .shellcheckrc with strict defaults

**Files:**
- Create: `.shellcheckrc`

- [ ] **Step 1: Create .shellcheckrc**

Create `.shellcheckrc`:

```
# Enable optional, strict checks not on by default.
enable=all

# Tests run with bats; bats macros redefine `run`, `load`, `setup`. Allow them.
external-sources=true

# Style severity (-S style in CI; locally see all).
severity=style
```

- [ ] **Step 2: Verify locally**

Run: `shellcheck --rcfile=.shellcheckrc LICENSE 2>&1 | head -3`
Expected: shellcheck complains LICENSE is not a shell script — fine, it just confirms `.shellcheckrc` is picked up.

- [ ] **Step 3: Commit**

```bash
git add .shellcheckrc
git commit -m "ci: add .shellcheckrc with strict defaults"
```

---

### Task B3: Write a smoke test that passes (proves the harness works)

**Files:**
- Create: `tests/bats/smoke.bats`

- [ ] **Step 1: Write the smoke test**

Create `tests/bats/smoke.bats`:

```bash
#!/usr/bin/env bats

load test_helper

@test "bats harness is wired up correctly" {
  run echo "hello"
  assert_success
  assert_output "hello"
}

@test "REPO_ROOT points at a directory with LICENSE" {
  assert [ -f "${REPO_ROOT}/LICENSE" ]
}
```

- [ ] **Step 2: Run the test locally**

Run: `tests/bats/lib/bats-core/bin/bats tests/bats/smoke.bats`
Expected:
```
 ✓ bats harness is wired up correctly
 ✓ REPO_ROOT points at a directory with LICENSE
2 tests, 0 failures
```

- [ ] **Step 3: Add a Makefile target for `make test`**

Create `Makefile`:

```makefile
.PHONY: test lint

BATS := tests/bats/lib/bats-core/bin/bats

test:
	$(BATS) tests/bats/

lint:
	@find . -type f \( -name '*.sh' -o -name '*.bash' \) \
		-not -path './tests/bats/lib/*' \
		-print0 | xargs -0 shellcheck -S style
```

- [ ] **Step 4: Verify `make test` and `make lint`**

Run: `make test`
Expected: Same output as Step 2.

Run: `make lint`
Expected: (no output — no shell scripts to lint yet)

- [ ] **Step 5: Commit**

```bash
git add tests/bats/smoke.bats Makefile
git commit -m "test: add smoke test verifying bats harness + Makefile for make test/lint"
```

---

## Phase C: `lib/distro.sh`

### Task C1: Test and implement `detect_distro`

**Files:**
- Create: `lib/distro.sh`
- Create: `tests/bats/distro.bats`

- [ ] **Step 1: Write the failing test**

Create `tests/bats/distro.bats`:

```bash
#!/usr/bin/env bats

load test_helper

setup() {
  load_lib distro
  setup_tmp
  # Fake /etc/os-release for these tests.
  FAKE_OS_RELEASE="${TEST_TMP}/os-release"
  export FAKE_OS_RELEASE
}

@test "detect_distro: Ubuntu 24.04 returns 'ubuntu-24.04'" {
  cat > "${FAKE_OS_RELEASE}" <<EOF
ID=ubuntu
VERSION_ID="24.04"
EOF
  run detect_distro "${FAKE_OS_RELEASE}"
  assert_success
  assert_output "ubuntu-24.04"
}

@test "detect_distro: Ubuntu 22.04 returns 'ubuntu-22.04'" {
  cat > "${FAKE_OS_RELEASE}" <<EOF
ID=ubuntu
VERSION_ID="22.04"
EOF
  run detect_distro "${FAKE_OS_RELEASE}"
  assert_success
  assert_output "ubuntu-22.04"
}

@test "detect_distro: Debian 12 returns 'debian-12'" {
  cat > "${FAKE_OS_RELEASE}" <<EOF
ID=debian
VERSION_ID="12"
EOF
  run detect_distro "${FAKE_OS_RELEASE}"
  assert_success
  assert_output "debian-12"
}

@test "detect_distro: unsupported distro returns non-zero with message on stderr" {
  cat > "${FAKE_OS_RELEASE}" <<EOF
ID=arch
VERSION_ID="rolling"
EOF
  run detect_distro "${FAKE_OS_RELEASE}"
  assert_failure
  assert_output --partial "unsupported distro"
}

@test "detect_distro: missing os-release returns non-zero" {
  run detect_distro "${TEST_TMP}/does-not-exist"
  assert_failure
  assert_output --partial "cannot detect distro"
}
```

- [ ] **Step 2: Run the test, expect failure**

Run: `make test`
Expected: 5 failures (`detect_distro: command not found`).

- [ ] **Step 3: Implement `detect_distro`**

Create `lib/distro.sh`:

```bash
#!/usr/bin/env bash
# lib/distro.sh — distro detection and package install helpers.
# This file is meant to be sourced, not executed.

# detect_distro [os_release_path]
# Echoes a normalized distro tag like "ubuntu-24.04" or "debian-12".
# Returns 0 on success, 1 on unsupported distro, 2 if os-release is missing.
detect_distro() {
  local release_path="${1:-/etc/os-release}"

  if [[ ! -r "${release_path}" ]]; then
    echo "cannot detect distro: ${release_path} not readable" >&2
    return 2
  fi

  local id version
  # shellcheck disable=SC1090
  id=$(. "${release_path}"; echo "${ID:-}")
  # shellcheck disable=SC1090
  version=$(. "${release_path}"; echo "${VERSION_ID:-}")

  case "${id}-${version}" in
    ubuntu-22.04|ubuntu-24.04|debian-12)
      echo "${id}-${version}"
      return 0
      ;;
    *)
      echo "unsupported distro: ${id} ${version}" >&2
      return 1
      ;;
  esac
}
```

- [ ] **Step 4: Run the test, expect success**

Run: `make test`
Expected: All 5 distro tests pass; smoke tests still pass.

- [ ] **Step 5: Commit**

```bash
git add lib/distro.sh tests/bats/distro.bats
git commit -m "feat(lib): add detect_distro covering ubuntu-22.04/24.04 and debian-12"
```

---

### Task C2: Test and implement `require_root`

**Files:**
- Modify: `lib/distro.sh`
- Modify: `tests/bats/distro.bats`

- [ ] **Step 1: Add the failing test**

Append to `tests/bats/distro.bats`:

```bash
@test "require_root: succeeds when EUID=0" {
  EUID=0 run require_root
  assert_success
}

@test "require_root: fails with a helpful message when not root" {
  EUID=1000 run require_root
  assert_failure
  assert_output --partial "must be run as root"
}
```

- [ ] **Step 2: Run, expect failure**

Run: `make test`
Expected: Two new failures.

- [ ] **Step 3: Add `require_root` to `lib/distro.sh`**

Append to `lib/distro.sh`:

```bash
# require_root
# Exits non-zero with a helpful message if the current process isn't root.
require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "must be run as root (try: sudo $0 \"\$@\")" >&2
    return 1
  fi
  return 0
}
```

- [ ] **Step 4: Run, expect pass**

Run: `make test`
Expected: All pass.

- [ ] **Step 5: Commit**

```bash
git add lib/distro.sh tests/bats/distro.bats
git commit -m "feat(lib): add require_root helper"
```

---

### Task C3: Test and implement `install_pkg`

**Files:**
- Modify: `lib/distro.sh`
- Modify: `tests/bats/distro.bats`

`install_pkg` shells out to `apt-get` on Ubuntu/Debian. The test mocks `apt-get` via `PATH` injection so we can assert the right invocation without touching the system.

- [ ] **Step 1: Add the failing test**

Append to `tests/bats/distro.bats`:

```bash
@test "install_pkg: invokes apt-get install -y with the given packages" {
  # Mock apt-get by putting a fake on PATH.
  mkdir -p "${TEST_TMP}/bin"
  cat > "${TEST_TMP}/bin/apt-get" <<'EOF'
#!/usr/bin/env bash
echo "apt-get called with: $*" >> "${TEST_TMP}/apt-get.log"
EOF
  chmod +x "${TEST_TMP}/bin/apt-get"
  export PATH="${TEST_TMP}/bin:${PATH}"

  run install_pkg curl jq
  assert_success
  run cat "${TEST_TMP}/apt-get.log"
  assert_output --partial "update"
  assert_output --partial "install -y curl jq"
}
```

- [ ] **Step 2: Run, expect failure**

Run: `make test`
Expected: One new failure.

- [ ] **Step 3: Implement `install_pkg`**

Append to `lib/distro.sh`:

```bash
# install_pkg <pkg> [<pkg> ...]
# Installs one or more system packages using the distro's package manager.
# Currently supports apt-based distros (Ubuntu, Debian).
install_pkg() {
  if [[ $# -eq 0 ]]; then
    echo "install_pkg: no packages given" >&2
    return 1
  fi
  # `apt-get update` once per invocation is acceptable for our wizard's usage pattern.
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
}
```

- [ ] **Step 4: Run, expect pass**

Run: `make test`
Expected: All pass.

- [ ] **Step 5: Commit**

```bash
git add lib/distro.sh tests/bats/distro.bats
git commit -m "feat(lib): add install_pkg wrapping apt-get"
```

---

### Task C4: Test and implement `install_docker`

**Files:**
- Modify: `lib/distro.sh`
- Modify: `tests/bats/distro.bats`

`install_docker` checks `command -v docker` and bootstraps via `get.docker.com` if absent. Tests cover both branches with PATH-injected mocks.

- [ ] **Step 1: Add the failing tests**

Append to `tests/bats/distro.bats`:

```bash
@test "install_docker: is a no-op when docker is already on PATH" {
  mkdir -p "${TEST_TMP}/bin"
  cat > "${TEST_TMP}/bin/docker" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "${TEST_TMP}/bin/docker"
  export PATH="${TEST_TMP}/bin:${PATH}"

  run install_docker
  assert_success
  assert_output --partial "docker already installed"
}

@test "install_docker: downloads and runs get.docker.com when docker is missing" {
  # Force docker missing by overriding PATH to exclude any real docker.
  export PATH="${TEST_TMP}/bin:/usr/bin:/bin"
  # Mock curl + sh so we record the URL it was asked to fetch.
  mkdir -p "${TEST_TMP}/bin"
  cat > "${TEST_TMP}/bin/curl" <<'EOF'
#!/usr/bin/env bash
echo "curl called: $*" >> "${TEST_TMP}/curl.log"
echo "echo 'fake install script'"
EOF
  chmod +x "${TEST_TMP}/bin/curl"
  cat > "${TEST_TMP}/bin/sh" <<'EOF'
#!/usr/bin/env bash
echo "sh called" >> "${TEST_TMP}/sh.log"
exit 0
EOF
  chmod +x "${TEST_TMP}/bin/sh"

  run install_docker
  assert_success
  run cat "${TEST_TMP}/curl.log"
  assert_output --partial "get.docker.com"
}
```

- [ ] **Step 2: Run, expect failure**

Run: `make test`
Expected: Two new failures.

- [ ] **Step 3: Implement `install_docker`**

Append to `lib/distro.sh`:

```bash
# install_docker
# Installs Docker Engine via get.docker.com if `docker` is not on PATH.
# Idempotent: prints a message and returns 0 if Docker is already installed.
install_docker() {
  if command -v docker >/dev/null 2>&1; then
    echo "docker already installed: $(command -v docker)"
    return 0
  fi
  echo "installing Docker via get.docker.com…"
  curl -fsSL https://get.docker.com | sh
}
```

- [ ] **Step 4: Run, expect pass**

Run: `make test`
Expected: All pass.

- [ ] **Step 5: Commit**

```bash
git add lib/distro.sh tests/bats/distro.bats
git commit -m "feat(lib): add install_docker via get.docker.com when missing"
```

---

## Phase D: `lib/menu.sh`

### Task D1: Test and implement `prompt_choice`

**Files:**
- Create: `lib/menu.sh`
- Create: `tests/bats/menu.bats`

`prompt_choice` reads from stdin and returns the selected option. Tests pipe answers into it.

- [ ] **Step 1: Write the failing tests**

Create `tests/bats/menu.bats`:

```bash
#!/usr/bin/env bats

load test_helper

setup() {
  load_lib menu
  setup_tmp
}

@test "prompt_choice: returns selected index for valid numeric input" {
  run bash -c 'source "${REPO_ROOT}/lib/menu.sh"; echo "2" | prompt_choice "Pick" "Apple" "Banana" "Cherry"'
  assert_success
  assert_output --partial "Banana"
}

@test "prompt_choice: defaults to choice 1 when input is empty" {
  run bash -c 'source "${REPO_ROOT}/lib/menu.sh"; echo "" | prompt_choice "Pick" "Apple" "Banana"'
  assert_success
  assert_output --partial "Apple"
}

@test "prompt_choice: re-prompts on invalid input then accepts a valid one" {
  run bash -c 'source "${REPO_ROOT}/lib/menu.sh"; printf "99\n2\n" | prompt_choice "Pick" "Apple" "Banana"'
  assert_success
  assert_output --partial "Banana"
  assert_output --partial "invalid"
}
```

- [ ] **Step 2: Run, expect failure**

Run: `make test`
Expected: Three new failures.

- [ ] **Step 3: Implement `prompt_choice`**

Create `lib/menu.sh`:

```bash
#!/usr/bin/env bash
# lib/menu.sh — terminal prompts and menu rendering for the wizard.
# Sourced, not executed.

# prompt_choice <prompt> <option1> [<option2> ...]
# Prints the numbered options, reads a number from stdin (default 1),
# echoes the chosen option's text on stdout. Re-prompts on invalid input.
prompt_choice() {
  local prompt="$1"; shift
  local -a opts=("$@")
  local count=${#opts[@]}
  if [[ $count -eq 0 ]]; then
    echo "prompt_choice: no options" >&2
    return 2
  fi

  echo "${prompt}" >&2
  local i
  for ((i = 0; i < count; i++)); do
    printf "  %d) %s\n" "$((i + 1))" "${opts[$i]}" >&2
  done

  local choice
  while :; do
    printf "Choice [1]: " >&2
    IFS= read -r choice || choice=""
    [[ -z "${choice}" ]] && choice=1
    if [[ "${choice}" =~ ^[0-9]+$ ]] \
       && (( choice >= 1 )) && (( choice <= count )); then
      echo "${opts[$((choice - 1))]}"
      return 0
    fi
    echo "invalid choice: ${choice}" >&2
  done
}
```

- [ ] **Step 4: Run, expect pass**

Run: `make test`
Expected: All pass.

- [ ] **Step 5: Commit**

```bash
git add lib/menu.sh tests/bats/menu.bats
git commit -m "feat(lib): add prompt_choice menu helper"
```

---

### Task D2: Test and implement `prompt_yesno` and `prompt_string`

**Files:**
- Modify: `lib/menu.sh`
- Modify: `tests/bats/menu.bats`

- [ ] **Step 1: Add the failing tests**

Append to `tests/bats/menu.bats`:

```bash
@test "prompt_yesno: Y default + empty input -> yes" {
  run bash -c 'source "${REPO_ROOT}/lib/menu.sh"; echo "" | prompt_yesno "Continue?" "Y" && echo "YES" || echo "NO"'
  assert_success
  assert_output --partial "YES"
}

@test "prompt_yesno: N default + empty input -> no" {
  run bash -c 'source "${REPO_ROOT}/lib/menu.sh"; echo "" | prompt_yesno "Continue?" "N" && echo "YES" || echo "NO"'
  assert_output --partial "NO"
}

@test "prompt_yesno: 'y' input -> yes regardless of default" {
  run bash -c 'source "${REPO_ROOT}/lib/menu.sh"; echo "y" | prompt_yesno "Continue?" "N" && echo "YES" || echo "NO"'
  assert_output --partial "YES"
}

@test "prompt_string: returns the typed value" {
  run bash -c 'source "${REPO_ROOT}/lib/menu.sh"; echo "chat.example.com" | prompt_string "Domain" ""'
  assert_success
  assert_output --partial "chat.example.com"
}

@test "prompt_string: returns the default when input is empty" {
  run bash -c 'source "${REPO_ROOT}/lib/menu.sh"; echo "" | prompt_string "Domain" "default.example"'
  assert_success
  assert_output --partial "default.example"
}
```

- [ ] **Step 2: Run, expect failure**

Run: `make test`
Expected: Five new failures.

- [ ] **Step 3: Implement `prompt_yesno` and `prompt_string`**

Append to `lib/menu.sh`:

```bash
# prompt_yesno <prompt> <default Y|N>
# Returns 0 if user answered yes, 1 if no.
prompt_yesno() {
  local prompt="$1"
  local default="${2:-N}"
  local hint
  if [[ "${default}" =~ ^[Yy]$ ]]; then hint="[Y/n]"; else hint="[y/N]"; fi
  local ans
  printf "%s %s: " "${prompt}" "${hint}" >&2
  IFS= read -r ans || ans=""
  [[ -z "${ans}" ]] && ans="${default}"
  [[ "${ans}" =~ ^[Yy]$ ]]
}

# prompt_string <prompt> <default>
# Reads a single line from stdin, echoes it. Returns default if empty.
prompt_string() {
  local prompt="$1"
  local default="${2:-}"
  local ans
  if [[ -n "${default}" ]]; then
    printf "%s [%s]: " "${prompt}" "${default}" >&2
  else
    printf "%s: " "${prompt}" >&2
  fi
  IFS= read -r ans || ans=""
  [[ -z "${ans}" ]] && ans="${default}"
  echo "${ans}"
}

# prompt_secret <prompt>
# Reads a single line from stdin WITHOUT echoing characters. Echoes value on stdout.
prompt_secret() {
  local prompt="$1"
  local ans
  printf "%s (input hidden): " "${prompt}" >&2
  IFS= read -rs ans || ans=""
  echo >&2  # newline after hidden input
  echo "${ans}"
}
```

- [ ] **Step 4: Run, expect pass**

Run: `make test`
Expected: All pass.

- [ ] **Step 5: Commit**

```bash
git add lib/menu.sh tests/bats/menu.bats
git commit -m "feat(lib): add prompt_yesno, prompt_string, prompt_secret"
```

---

## Phase E: `lib/secrets.sh`

### Task E1: Test and implement `write_env_var` and `read_env_var`

**Files:**
- Create: `lib/secrets.sh`
- Create: `tests/bats/secrets.bats`

- [ ] **Step 1: Write the failing tests**

Create `tests/bats/secrets.bats`:

```bash
#!/usr/bin/env bats

load test_helper

setup() {
  load_lib secrets
  setup_tmp
  ENV_FILE="${TEST_TMP}/.env"
  export ENV_FILE
}

@test "write_env_var: creates file with mode 0600 and writes KEY=VALUE" {
  write_env_var "${ENV_FILE}" "OPENAI_API_KEY" "sk-test-123"
  assert [ -f "${ENV_FILE}" ]
  run stat -c "%a" "${ENV_FILE}"
  assert_output "600"
  run cat "${ENV_FILE}"
  assert_output --partial "OPENAI_API_KEY=sk-test-123"
}

@test "write_env_var: overwrites an existing key in-place" {
  printf 'OPENAI_API_KEY=old\nUNRELATED=keepme\n' > "${ENV_FILE}"
  chmod 600 "${ENV_FILE}"
  write_env_var "${ENV_FILE}" "OPENAI_API_KEY" "sk-new"
  run cat "${ENV_FILE}"
  assert_output --partial "OPENAI_API_KEY=sk-new"
  assert_output --partial "UNRELATED=keepme"
  refute_output --partial "OPENAI_API_KEY=old"
}

@test "read_env_var: returns value of existing key" {
  printf 'OPENAI_API_KEY=sk-test-123\n' > "${ENV_FILE}"
  chmod 600 "${ENV_FILE}"
  run read_env_var "${ENV_FILE}" "OPENAI_API_KEY"
  assert_success
  assert_output "sk-test-123"
}

@test "read_env_var: empty output and non-zero exit when missing" {
  echo "" > "${ENV_FILE}"
  chmod 600 "${ENV_FILE}"
  run read_env_var "${ENV_FILE}" "MISSING_KEY"
  assert_failure
  assert_output ""
}
```

- [ ] **Step 2: Run, expect failure**

Run: `make test`
Expected: Four new failures.

- [ ] **Step 3: Implement `secrets.sh`**

Create `lib/secrets.sh`:

```bash
#!/usr/bin/env bash
# lib/secrets.sh — write, read, and shred secrets in a .env file.
# Sourced, not executed.

# write_env_var <env_file> <key> <value>
# Writes KEY=VALUE to env_file, replacing any existing line for KEY.
# Creates the file with mode 0600 if it doesn't exist.
write_env_var() {
  local env_file="$1" key="$2" value="$3"
  if [[ ! -f "${env_file}" ]]; then
    : > "${env_file}"
    chmod 600 "${env_file}"
  fi
  # Strip any existing line for this key.
  local tmp
  tmp=$(mktemp "${env_file}.tmp.XXXXXX")
  chmod 600 "${tmp}"
  grep -v "^${key}=" "${env_file}" > "${tmp}" || true
  printf '%s=%s\n' "${key}" "${value}" >> "${tmp}"
  mv "${tmp}" "${env_file}"
  chmod 600 "${env_file}"
}

# read_env_var <env_file> <key>
# Echoes the VALUE for KEY, or returns 1 if not present.
read_env_var() {
  local env_file="$1" key="$2"
  if [[ ! -f "${env_file}" ]]; then
    return 1
  fi
  local line
  line=$(grep -E "^${key}=" "${env_file}" | tail -n1) || return 1
  if [[ -z "${line}" ]]; then
    return 1
  fi
  echo "${line#"${key}="}"
}
```

- [ ] **Step 4: Run, expect pass**

Run: `make test`
Expected: All pass.

- [ ] **Step 5: Commit**

```bash
git add lib/secrets.sh tests/bats/secrets.bats
git commit -m "feat(lib): add write_env_var / read_env_var with 0600 enforcement"
```

---

### Task E2: Test and implement `shred_env`

**Files:**
- Modify: `lib/secrets.sh`
- Modify: `tests/bats/secrets.bats`

- [ ] **Step 1: Add the failing test**

Append to `tests/bats/secrets.bats`:

```bash
@test "shred_env: removes the env file" {
  printf 'X=1\n' > "${ENV_FILE}"
  chmod 600 "${ENV_FILE}"
  shred_env "${ENV_FILE}"
  assert [ ! -f "${ENV_FILE}" ]
}

@test "shred_env: no-op when file is absent" {
  run shred_env "${TEST_TMP}/does-not-exist"
  assert_success
}
```

- [ ] **Step 2: Run, expect failure**

Run: `make test`
Expected: Two new failures.

- [ ] **Step 3: Implement `shred_env`**

Append to `lib/secrets.sh`:

```bash
# shred_env <env_file>
# Securely removes the env file. Uses `shred -u` if available, else `rm -f`.
shred_env() {
  local env_file="$1"
  [[ -f "${env_file}" ]] || return 0
  if command -v shred >/dev/null 2>&1; then
    shred -u "${env_file}"
  else
    rm -f "${env_file}"
  fi
}
```

- [ ] **Step 4: Run, expect pass**

Run: `make test`
Expected: All pass.

- [ ] **Step 5: Commit**

```bash
git add lib/secrets.sh tests/bats/secrets.bats
git commit -m "feat(lib): add shred_env for secure secret removal"
```

---

## Phase F: `lib/state.sh`

### Task F1: Test and implement `read_state` and `write_state`

**Files:**
- Create: `lib/state.sh`
- Create: `tests/bats/state.bats`

State is a small JSON file. We use `jq` to manipulate it.

- [ ] **Step 1: Verify jq is available** (one-time prerequisite check; not a code change)

Run: `command -v jq || echo "jq missing"`
Expected: A path to jq, not "jq missing". If missing, install: `brew install jq` or `apt-get install -y jq`.

- [ ] **Step 2: Write the failing tests**

Create `tests/bats/state.bats`:

```bash
#!/usr/bin/env bats

load test_helper

setup() {
  load_lib state
  setup_tmp
  STATE_FILE="${TEST_TMP}/state.json"
  export STATE_FILE
}

@test "write_state: creates a JSON file with given fields + schema_version" {
  write_state "${STATE_FILE}" \
    assistant=open-webui \
    domain=chat.example.com \
    provider=anthropic
  assert [ -f "${STATE_FILE}" ]
  run jq -r '.schema_version' "${STATE_FILE}"
  assert_output "1"
  run jq -r '.assistant' "${STATE_FILE}"
  assert_output "open-webui"
  run jq -r '.domain' "${STATE_FILE}"
  assert_output "chat.example.com"
}

@test "write_state: preserves existing fields not in this call" {
  write_state "${STATE_FILE}" assistant=open-webui domain=chat.example.com
  write_state "${STATE_FILE}" provider=openai
  run jq -r '.assistant' "${STATE_FILE}"
  assert_output "open-webui"
  run jq -r '.provider' "${STATE_FILE}"
  assert_output "openai"
}

@test "read_state: returns value of an existing field" {
  write_state "${STATE_FILE}" assistant=open-webui
  run read_state "${STATE_FILE}" assistant
  assert_success
  assert_output "open-webui"
}

@test "read_state: returns empty + non-zero for a missing field" {
  write_state "${STATE_FILE}" assistant=open-webui
  run read_state "${STATE_FILE}" provider
  assert_failure
}

@test "add_extra: appends to .extras array, dedups, sorts" {
  write_state "${STATE_FILE}" assistant=open-webui
  add_extra "${STATE_FILE}" caddy
  add_extra "${STATE_FILE}" pwa
  add_extra "${STATE_FILE}" caddy   # duplicate; should be ignored
  run jq -c '.extras' "${STATE_FILE}"
  assert_output '["caddy","pwa"]'
}

@test "remove_extra: removes from .extras array" {
  write_state "${STATE_FILE}" assistant=open-webui
  add_extra "${STATE_FILE}" caddy
  add_extra "${STATE_FILE}" pwa
  remove_extra "${STATE_FILE}" caddy
  run jq -c '.extras' "${STATE_FILE}"
  assert_output '["pwa"]'
}
```

- [ ] **Step 3: Run, expect failure**

Run: `make test`
Expected: Six new failures.

- [ ] **Step 4: Implement `lib/state.sh`**

Create `lib/state.sh`:

```bash
#!/usr/bin/env bash
# lib/state.sh — read/write /opt/my-ai-box/state.json.
# Sourced, not executed.
# Requires: jq.

STATE_SCHEMA_VERSION=1

# _state_init <state_file>
# Ensures the file exists and has the baseline structure.
_state_init() {
  local state_file="$1"
  if [[ ! -f "${state_file}" ]]; then
    jq -n --argjson v "${STATE_SCHEMA_VERSION}" \
      '{schema_version: $v, extras: [], created_at: now | todate}' \
      > "${state_file}"
  fi
}

# write_state <state_file> key=value [key=value ...]
# Sets the given keys atomically. Preserves other fields.
write_state() {
  local state_file="$1"; shift
  _state_init "${state_file}"
  local jq_filter='.' arg_idx=0
  local -a jq_args=()
  for kv in "$@"; do
    local k="${kv%%=*}" v="${kv#*=}"
    jq_args+=(--arg "k${arg_idx}" "${k}" --arg "v${arg_idx}" "${v}")
    # shellcheck disable=SC2016
    jq_filter+=" | .[\$k${arg_idx}] = \$v${arg_idx}"
    arg_idx=$((arg_idx + 1))
  done
  local tmp
  tmp=$(mktemp "${state_file}.tmp.XXXXXX")
  jq "${jq_args[@]}" "${jq_filter}" "${state_file}" > "${tmp}"
  mv "${tmp}" "${state_file}"
}

# read_state <state_file> <key>
# Echoes the value of the given top-level key, or returns 1 if missing/null.
read_state() {
  local state_file="$1" key="$2"
  [[ -f "${state_file}" ]] || return 1
  local val
  val=$(jq -r --arg k "${key}" '.[$k] // empty' "${state_file}")
  if [[ -z "${val}" ]]; then return 1; fi
  echo "${val}"
}

# add_extra <state_file> <extra_name>
# Adds to .extras (deduped, sorted alphabetically).
add_extra() {
  local state_file="$1" name="$2"
  _state_init "${state_file}"
  local tmp
  tmp=$(mktemp "${state_file}.tmp.XXXXXX")
  jq --arg n "${name}" '.extras = ((.extras + [$n]) | unique)' \
    "${state_file}" > "${tmp}"
  mv "${tmp}" "${state_file}"
}

# remove_extra <state_file> <extra_name>
# Removes the given extra from .extras.
remove_extra() {
  local state_file="$1" name="$2"
  [[ -f "${state_file}" ]] || return 0
  local tmp
  tmp=$(mktemp "${state_file}.tmp.XXXXXX")
  jq --arg n "${name}" '.extras = (.extras - [$n])' \
    "${state_file}" > "${tmp}"
  mv "${tmp}" "${state_file}"
}
```

- [ ] **Step 5: Run, expect pass**

Run: `make test`
Expected: All pass.

- [ ] **Step 6: Commit**

```bash
git add lib/state.sh tests/bats/state.bats
git commit -m "feat(lib): add state.json helpers (read/write/add_extra/remove_extra) using jq"
```

---

## Phase G: `lib/tls.sh`

### Task G1: Test and implement `validate_domain`

**Files:**
- Create: `lib/tls.sh`
- Create: `tests/bats/tls.bats`

`validate_domain` checks that a given domain resolves to a given expected IP. Tests mock `dig` via PATH injection.

- [ ] **Step 1: Write the failing tests**

Create `tests/bats/tls.bats`:

```bash
#!/usr/bin/env bats

load test_helper

setup() {
  load_lib tls
  setup_tmp
  mkdir -p "${TEST_TMP}/bin"
  export PATH="${TEST_TMP}/bin:${PATH}"
}

@test "validate_domain: succeeds when dig returns the expected IP" {
  cat > "${TEST_TMP}/bin/dig" <<'EOF'
#!/usr/bin/env bash
echo "203.0.113.5"
EOF
  chmod +x "${TEST_TMP}/bin/dig"
  run validate_domain "chat.example.com" "203.0.113.5"
  assert_success
}

@test "validate_domain: fails when dig returns a different IP, with helpful message" {
  cat > "${TEST_TMP}/bin/dig" <<'EOF'
#!/usr/bin/env bash
echo "198.51.100.99"
EOF
  chmod +x "${TEST_TMP}/bin/dig"
  run validate_domain "chat.example.com" "203.0.113.5"
  assert_failure
  assert_output --partial "does not resolve to"
  assert_output --partial "203.0.113.5"
}

@test "validate_domain: fails on empty dig output" {
  cat > "${TEST_TMP}/bin/dig" <<'EOF'
#!/usr/bin/env bash
echo ""
EOF
  chmod +x "${TEST_TMP}/bin/dig"
  run validate_domain "chat.example.com" "203.0.113.5"
  assert_failure
  assert_output --partial "no DNS A record"
}
```

- [ ] **Step 2: Run, expect failure**

Run: `make test`
Expected: Three new failures.

- [ ] **Step 3: Implement `lib/tls.sh`**

Create `lib/tls.sh`:

```bash
#!/usr/bin/env bash
# lib/tls.sh — domain validation and Caddyfile rendering.
# Sourced, not executed.

# validate_domain <domain> <expected_ip>
# Checks that <domain> resolves to <expected_ip>.
# Returns 0 if match, 1 if mismatch, 2 if no A record.
validate_domain() {
  local domain="$1" expected="$2"
  local resolved
  resolved=$(dig +short A "${domain}" | head -n1)
  if [[ -z "${resolved}" ]]; then
    echo "domain ${domain} has no DNS A record" >&2
    return 2
  fi
  if [[ "${resolved}" != "${expected}" ]]; then
    echo "domain ${domain} does not resolve to ${expected} (got: ${resolved})" >&2
    return 1
  fi
  return 0
}

# public_ip
# Echoes the VPS's public IPv4 address.
public_ip() {
  curl -fsS --max-time 5 https://api.ipify.org \
    || curl -fsS --max-time 5 https://ifconfig.me \
    || { echo "could not determine public IP" >&2; return 1; }
}
```

- [ ] **Step 4: Run, expect pass**

Run: `make test`
Expected: All pass.

- [ ] **Step 5: Commit**

```bash
git add lib/tls.sh tests/bats/tls.bats
git commit -m "feat(lib): add validate_domain + public_ip helpers"
```

---

### Task G2: Test and implement `caddy_render`

**Files:**
- Modify: `lib/tls.sh`
- Modify: `tests/bats/tls.bats`

`caddy_render` writes a Caddyfile based on a domain + upstream container:port.

- [ ] **Step 1: Add the failing test**

Append to `tests/bats/tls.bats`:

```bash
@test "caddy_render: produces a Caddyfile for the given domain + upstream" {
  local out="${TEST_TMP}/Caddyfile"
  caddy_render "${out}" "chat.example.com" "you@example.com" "open-webui:8080"
  assert [ -f "${out}" ]
  run cat "${out}"
  assert_output --partial "chat.example.com"
  assert_output --partial "you@example.com"
  assert_output --partial "reverse_proxy open-webui:8080"
}
```

- [ ] **Step 2: Run, expect failure**

Run: `make test`
Expected: One new failure.

- [ ] **Step 3: Implement `caddy_render`**

Append to `lib/tls.sh`:

```bash
# caddy_render <out_file> <domain> <acme_email> <upstream_host:port>
# Writes a Caddyfile that reverse-proxies <domain> to <upstream>, with
# automatic Let's Encrypt cert issuance.
caddy_render() {
  local out="$1" domain="$2" email="$3" upstream="$4"
  cat > "${out}" <<EOF
{
  email ${email}
}

${domain} {
  encode zstd gzip
  reverse_proxy ${upstream}
}
EOF
}
```

- [ ] **Step 4: Run, expect pass**

Run: `make test`
Expected: All pass.

- [ ] **Step 5: Commit**

```bash
git add lib/tls.sh tests/bats/tls.bats
git commit -m "feat(lib): add caddy_render for generating Caddyfiles"
```

---

## Phase H: `lib/compose.sh`

### Task H1: Test and implement `compose_render` (concatenates a base + overlays)

**Files:**
- Create: `lib/compose.sh`
- Create: `tests/bats/compose.bats`

The wizard produces `compose.yml` (the assistant) + `compose.override.yml` (extras stacked). `compose_render` is a thin wrapper that copies the assistant's `compose.yml` to `/opt/my-ai-box/compose.yml` and concatenates extras' overlays into `compose.override.yml`. We don't merge YAML in bash — Docker Compose v2 natively merges multiple `-f` files.

- [ ] **Step 1: Write the failing tests**

Create `tests/bats/compose.bats`:

```bash
#!/usr/bin/env bats

load test_helper

setup() {
  load_lib compose
  setup_tmp
  REPO="${TEST_TMP}/repo"
  RUNTIME="${TEST_TMP}/runtime"
  mkdir -p "${REPO}/assistants/open-webui" "${REPO}/extras/caddy" "${RUNTIME}"

  cat > "${REPO}/assistants/open-webui/compose.yml" <<EOF
services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:0.6.32
EOF
  cat > "${REPO}/extras/caddy/compose-overlay.yml" <<EOF
services:
  caddy:
    image: caddy:2.10
EOF
}

@test "compose_render: copies assistant compose to runtime/compose.yml" {
  compose_render "${REPO}" "${RUNTIME}" "open-webui" ""
  assert [ -f "${RUNTIME}/compose.yml" ]
  run grep "open-webui" "${RUNTIME}/compose.yml"
  assert_success
}

@test "compose_render: writes compose.override.yml when extras are present" {
  compose_render "${REPO}" "${RUNTIME}" "open-webui" "caddy"
  assert [ -f "${RUNTIME}/compose.override.yml" ]
  run grep "caddy" "${RUNTIME}/compose.override.yml"
  assert_success
}

@test "compose_render: removes compose.override.yml when no extras are present" {
  : > "${RUNTIME}/compose.override.yml"
  compose_render "${REPO}" "${RUNTIME}" "open-webui" ""
  assert [ ! -f "${RUNTIME}/compose.override.yml" ]
}
```

- [ ] **Step 2: Run, expect failure**

Run: `make test`
Expected: Three new failures.

- [ ] **Step 3: Implement `lib/compose.sh`**

Create `lib/compose.sh`:

```bash
#!/usr/bin/env bash
# lib/compose.sh — render and operate Docker Compose files for my-ai-box.
# Sourced, not executed.

# compose_render <repo_root> <runtime_dir> <assistant_name> <extras_space_separated>
# Copies assistants/<assistant>/compose.yml to <runtime_dir>/compose.yml
# and concatenates extras/<extra>/compose-overlay.yml into
# <runtime_dir>/compose.override.yml. Removes the override when extras is empty.
compose_render() {
  local repo="$1" runtime="$2" assistant="$3" extras="$4"

  local base="${repo}/assistants/${assistant}/compose.yml"
  if [[ ! -f "${base}" ]]; then
    echo "compose_render: assistant base not found: ${base}" >&2
    return 1
  fi
  cp "${base}" "${runtime}/compose.yml"

  local override="${runtime}/compose.override.yml"
  if [[ -z "${extras}" ]]; then
    rm -f "${override}"
    return 0
  fi

  : > "${override}"
  local first=1
  for ex in ${extras}; do
    local snippet="${repo}/extras/${ex}/compose-overlay.yml"
    if [[ ! -f "${snippet}" ]]; then
      echo "compose_render: extra overlay not found: ${snippet}" >&2
      return 1
    fi
    if [[ ${first} -eq 1 ]]; then
      cat "${snippet}" >> "${override}"
      first=0
    else
      # Subsequent overlays: strip leading 'services:' to avoid double-keys.
      # Docker Compose merges multiple -f files; concatenating overlays under
      # a single override file requires only one top-level 'services:' line.
      awk 'BEGIN{started=0} /^services:/{started=1; next} {if (started) print}' \
        "${snippet}" >> "${override}"
    fi
  done
}

# compose_up <runtime_dir> <env_file>
# Brings up the stack with optional override.
compose_up() {
  local runtime="$1" env_file="$2"
  local -a args=(-f "${runtime}/compose.yml")
  [[ -f "${runtime}/compose.override.yml" ]] && args+=(-f "${runtime}/compose.override.yml")
  args+=(--env-file "${env_file}")
  ( cd "${runtime}" && docker compose "${args[@]}" up -d )
}

# compose_down <runtime_dir>
compose_down() {
  local runtime="$1"
  ( cd "${runtime}" && docker compose down --remove-orphans )
}
```

- [ ] **Step 4: Run, expect pass**

Run: `make test`
Expected: All pass.

- [ ] **Step 5: Commit**

```bash
git add lib/compose.sh tests/bats/compose.bats
git commit -m "feat(lib): add compose_render + compose_up/down using docker compose v2"
```

---

## Phase I: `bin/my-ai-box` entrypoint

### Task I1: Scaffold the entrypoint with a help command

**Files:**
- Create: `bin/my-ai-box`
- Create: `tests/bats/cli.bats`

- [ ] **Step 1: Write the failing test**

Create `tests/bats/cli.bats`:

```bash
#!/usr/bin/env bats

load test_helper

@test "my-ai-box: prints help on --help" {
  run "${REPO_ROOT}/bin/my-ai-box" --help
  assert_success
  assert_output --partial "Usage:"
  assert_output --partial "install"
  assert_output --partial "menu"
}

@test "my-ai-box: prints version on --version" {
  run "${REPO_ROOT}/bin/my-ai-box" --version
  assert_success
  assert_output --partial "my-ai-box"
}

@test "my-ai-box: unknown command exits non-zero with help pointer" {
  run "${REPO_ROOT}/bin/my-ai-box" not-a-real-command
  assert_failure
  assert_output --partial "unknown command"
}
```

- [ ] **Step 2: Run, expect failure**

Run: `make test`
Expected: Three new failures.

- [ ] **Step 3: Create the entrypoint**

Create `bin/my-ai-box`:

```bash
#!/usr/bin/env bash
set -euo pipefail

readonly MY_AI_BOX_VERSION="0.1.0-dev"

# Resolve repo root regardless of how this is invoked.
SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
REPO_ROOT=$(dirname "$(dirname "${SCRIPT_PATH}")")
readonly REPO_ROOT

# Source helpers.
# shellcheck source=../lib/distro.sh
source "${REPO_ROOT}/lib/distro.sh"
# shellcheck source=../lib/menu.sh
source "${REPO_ROOT}/lib/menu.sh"
# shellcheck source=../lib/secrets.sh
source "${REPO_ROOT}/lib/secrets.sh"
# shellcheck source=../lib/state.sh
source "${REPO_ROOT}/lib/state.sh"
# shellcheck source=../lib/tls.sh
source "${REPO_ROOT}/lib/tls.sh"
# shellcheck source=../lib/compose.sh
source "${REPO_ROOT}/lib/compose.sh"

usage() {
  cat <<EOF
my-ai-box ${MY_AI_BOX_VERSION}

Usage: my-ai-box <command> [options]

Commands:
  install            Run the install wizard (default when nothing is installed).
  menu               Open the management menu (default when something is installed).
  add-extra <name>   Add an extra (caddy, pwa, voice, telegram, searxng, backups).
  remove-extra <n>   Remove an extra.
  update             git pull + docker compose up -d.
  uninstall          Remove containers, data, secrets. Prompts before destruction.
  status             Show what's installed + container health.
  logs               Tail container logs.
  doctor             Print a system report (paste into bug reports).
  --help, -h         Show this help.
  --version, -v      Show the version.
EOF
}

cmd="${1:---help}"
case "${cmd}" in
  --help|-h|help)     usage; exit 0 ;;
  --version|-v)       echo "my-ai-box ${MY_AI_BOX_VERSION}"; exit 0 ;;
  install)            shift; cmd_install "$@" ;;
  menu)               shift; cmd_menu "$@" ;;
  add-extra)          shift; cmd_add_extra "$@" ;;
  remove-extra)       shift; cmd_remove_extra "$@" ;;
  update)             shift; cmd_update "$@" ;;
  uninstall)          shift; cmd_uninstall "$@" ;;
  status)             shift; cmd_status "$@" ;;
  logs)               shift; cmd_logs "$@" ;;
  doctor)             shift; cmd_doctor "$@" ;;
  *)
    echo "unknown command: ${cmd}" >&2
    echo "Run 'my-ai-box --help' for usage." >&2
    exit 2
    ;;
esac
```

- [ ] **Step 4: Add command stubs (each printing "not yet implemented")**

Append to `bin/my-ai-box` (after the `usage` function, before `cmd="${1:---help}"`):

```bash
# Command stubs — each task in this Phase + Phases J/K/L fleshes one out.
cmd_install()       { echo "install: not yet implemented" >&2; exit 1; }
cmd_menu()          { echo "menu: not yet implemented" >&2; exit 1; }
cmd_add_extra()     { echo "add-extra: not yet implemented" >&2; exit 1; }
cmd_remove_extra()  { echo "remove-extra: not yet implemented" >&2; exit 1; }
cmd_update()        { echo "update: not yet implemented" >&2; exit 1; }
cmd_uninstall()     { echo "uninstall: not yet implemented" >&2; exit 1; }
cmd_status()        { echo "status: not yet implemented" >&2; exit 1; }
cmd_logs()          { echo "logs: not yet implemented" >&2; exit 1; }
cmd_doctor()        { echo "doctor: not yet implemented" >&2; exit 1; }
```

- [ ] **Step 5: Make executable**

Run: `chmod +x bin/my-ai-box`

- [ ] **Step 6: Run, expect pass**

Run: `make test`
Expected: All pass.

- [ ] **Step 7: Commit**

```bash
git add bin/my-ai-box tests/bats/cli.bats
git commit -m "feat(cli): scaffold my-ai-box entrypoint with --help, --version, dispatch stubs"
```

---

### Task I2: Implement `cmd_install` — the first-time wizard

**Files:**
- Modify: `bin/my-ai-box`
- Modify: `tests/bats/cli.bats`

This is the big one. The full install flow is described in §7.1 of the spec. We implement it iteratively; this task wires the happy path for Open WebUI + Caddy.

- [ ] **Step 1: Add an integration test (non-interactive via env vars)**

Append to `tests/bats/cli.bats`:

```bash
@test "my-ai-box install: NONINTERACTIVE mode fails with a clear list of missing vars" {
  MY_AI_BOX_NONINTERACTIVE=1 run "${REPO_ROOT}/bin/my-ai-box" install
  assert_failure
  assert_output --partial "missing required env vars"
  assert_output --partial "MY_AI_BOX_ASSISTANT"
}

@test "my-ai-box install: --dry-run + env vars writes state and renders compose without docker" {
  setup_tmp
  local fake_root="${TEST_TMP}/opt/my-ai-box"
  mkdir -p "${fake_root}/data"
  MY_AI_BOX_DRY_RUN=1 \
  MY_AI_BOX_RUNTIME_DIR="${fake_root}" \
  MY_AI_BOX_ASSISTANT=open-webui \
  MY_AI_BOX_DOMAIN=chat.example.com \
  MY_AI_BOX_EMAIL=you@example.com \
  MY_AI_BOX_PROVIDER=anthropic \
  MY_AI_BOX_API_KEY=sk-test-123 \
  MY_AI_BOX_EXTRAS=caddy \
  MY_AI_BOX_NONINTERACTIVE=1 \
    run "${REPO_ROOT}/bin/my-ai-box" install
  assert_success
  assert [ -f "${fake_root}/state.json" ]
  assert [ -f "${fake_root}/.env" ]
  assert [ -f "${fake_root}/compose.yml" ]
}
```

- [ ] **Step 2: Run, expect failure**

Run: `make test`
Expected: Two new failures.

- [ ] **Step 3: Implement `cmd_install`**

Replace the `cmd_install` stub in `bin/my-ai-box` with:

```bash
cmd_install() {
  local runtime_dir="${MY_AI_BOX_RUNTIME_DIR:-/opt/my-ai-box}"
  local dry_run="${MY_AI_BOX_DRY_RUN:-0}"
  local noninteractive="${MY_AI_BOX_NONINTERACTIVE:-0}"

  mkdir -p "${runtime_dir}/data"

  # 1. Gather inputs.
  local assistant domain email provider api_key extras

  if [[ "${noninteractive}" == "1" ]]; then
    local missing=()
    [[ -z "${MY_AI_BOX_ASSISTANT:-}" ]] && missing+=("MY_AI_BOX_ASSISTANT")
    [[ -z "${MY_AI_BOX_DOMAIN:-}" ]]    && missing+=("MY_AI_BOX_DOMAIN")
    [[ -z "${MY_AI_BOX_EMAIL:-}" ]]     && missing+=("MY_AI_BOX_EMAIL")
    [[ -z "${MY_AI_BOX_PROVIDER:-}" ]]  && missing+=("MY_AI_BOX_PROVIDER")
    [[ -z "${MY_AI_BOX_API_KEY:-}" ]]   && missing+=("MY_AI_BOX_API_KEY")
    if [[ ${#missing[@]} -gt 0 ]]; then
      echo "missing required env vars: ${missing[*]}" >&2
      return 1
    fi
    assistant="${MY_AI_BOX_ASSISTANT}"
    domain="${MY_AI_BOX_DOMAIN}"
    email="${MY_AI_BOX_EMAIL}"
    provider="${MY_AI_BOX_PROVIDER}"
    api_key="${MY_AI_BOX_API_KEY}"
    extras="${MY_AI_BOX_EXTRAS:-}"
  else
    echo "[my-ai-box] First-time install. Detecting environment…"
    detect_distro >/dev/null
    assistant=$(prompt_choice "What do you want to run?" \
      "open-webui" "librechat" "anythingllm" "aider")
    domain=$(prompt_string "Domain name for HTTPS (or 'skip' for IP-only)" "skip")
    email=$(prompt_string "Email for Let's Encrypt" "")
    provider=$(prompt_choice "Pick your LLM provider" \
      "openai" "anthropic" "deepseek" "openrouter" "skip")
    if [[ "${provider}" != "skip" ]]; then
      api_key=$(prompt_secret "${provider} API key")
    else
      api_key=""
    fi
    extras=""
    if [[ "${domain}" != "skip" ]]; then
      prompt_yesno "Reverse proxy + TLS (Caddy)?" "Y" && extras="caddy"
    fi
  fi

  # 2. Persist state + secrets.
  local state_file="${runtime_dir}/state.json"
  local env_file="${runtime_dir}/.env"

  write_state "${state_file}" \
    assistant="${assistant}" \
    domain="${domain}" \
    email="${email}" \
    provider="${provider}"

  # Replace .extras with the chosen extras (idempotent re-run).
  for ex in ${extras}; do add_extra "${state_file}" "${ex}"; done

  if [[ -n "${api_key}" ]]; then
    case "${provider}" in
      openai)     write_env_var "${env_file}" "OPENAI_API_KEY" "${api_key}" ;;
      anthropic)  write_env_var "${env_file}" "ANTHROPIC_API_KEY" "${api_key}" ;;
      deepseek)   write_env_var "${env_file}" "DEEPSEEK_API_KEY" "${api_key}" ;;
      openrouter) write_env_var "${env_file}" "OPENROUTER_API_KEY" "${api_key}" ;;
    esac
  fi
  # Ensure .env exists even when provider was skipped, so docker compose --env-file works.
  [[ ! -f "${env_file}" ]] && { : > "${env_file}"; chmod 600 "${env_file}"; }

  # 3. Render compose.
  compose_render "${REPO_ROOT}" "${runtime_dir}" "${assistant}" "${extras}"

  # 4. Render Caddyfile if applicable.
  if [[ " ${extras} " == *" caddy "* ]]; then
    mkdir -p "${runtime_dir}/data/caddy"
    caddy_render \
      "${runtime_dir}/data/caddy/Caddyfile" \
      "${domain}" "${email}" \
      "$(assistant_upstream "${assistant}")"
  fi

  # 5. Bring up (skipped in dry-run).
  if [[ "${dry_run}" == "1" ]]; then
    echo "[my-ai-box] dry-run: skipping docker compose up"
    return 0
  fi

  compose_up "${runtime_dir}" "${env_file}"

  # 6. Print done.
  if [[ "${domain}" != "skip" ]]; then
    echo "✓ Done. https://${domain}"
  else
    echo "✓ Done. http://$(public_ip 2>/dev/null || echo 'your-vps-ip')"
  fi
  echo "  To manage later, run:    my-ai-box"
  echo "  ℹ Don't have a VPS? See README's 'Recommended VPS providers'."
}

# assistant_upstream <assistant-name>
# Echoes the docker-compose service name and port the reverse proxy points at.
assistant_upstream() {
  case "$1" in
    open-webui)   echo "open-webui:8080" ;;
    librechat)    echo "librechat:3080" ;;
    anythingllm)  echo "anythingllm:3001" ;;
    aider)        echo "aider:0" ;;   # CLI-only; no HTTP upstream
    *) echo "unknown assistant: $1" >&2; return 1 ;;
  esac
}
```

- [ ] **Step 4: Run, expect failure (we don't have open-webui assistant dir yet)**

Run: `make test`
Expected: The dry-run test fails because `assistants/open-webui/compose.yml` doesn't exist yet.

- [ ] **Step 5: Commit (intentionally before passing — the next phase creates open-webui)**

```bash
git add bin/my-ai-box tests/bats/cli.bats
git commit -m "feat(cli): implement cmd_install for happy path (non-interactive + interactive)"
```

The integration test will go green at the end of Phase K when the open-webui assistant directory exists.

---

### Task I3: Implement `cmd_menu` — the re-run menu

**Files:**
- Modify: `bin/my-ai-box`
- Modify: `tests/bats/cli.bats`

- [ ] **Step 1: Add the failing test**

Append to `tests/bats/cli.bats`:

```bash
@test "my-ai-box menu: prints the menu when state.json exists" {
  setup_tmp
  local fake_root="${TEST_TMP}/opt/my-ai-box"
  mkdir -p "${fake_root}"
  jq -n '{schema_version: 1, assistant: "open-webui", extras: ["caddy"]}' \
    > "${fake_root}/state.json"
  echo "0" | MY_AI_BOX_RUNTIME_DIR="${fake_root}" \
    run "${REPO_ROOT}/bin/my-ai-box" menu
  assert_success
  assert_output --partial "Add an extra"
  assert_output --partial "Uninstall"
}

@test "my-ai-box menu: errors when no state.json exists" {
  setup_tmp
  MY_AI_BOX_RUNTIME_DIR="${TEST_TMP}/nope" \
    run "${REPO_ROOT}/bin/my-ai-box" menu
  assert_failure
  assert_output --partial "not installed"
}
```

- [ ] **Step 2: Run, expect failure**

Run: `make test`

- [ ] **Step 3: Replace the `cmd_menu` stub in `bin/my-ai-box`**

```bash
cmd_menu() {
  local runtime_dir="${MY_AI_BOX_RUNTIME_DIR:-/opt/my-ai-box}"
  local state_file="${runtime_dir}/state.json"
  if [[ ! -f "${state_file}" ]]; then
    echo "my-ai-box is not installed. Run 'my-ai-box install' first." >&2
    return 1
  fi
  local current_assistant
  current_assistant=$(read_state "${state_file}" assistant)
  local current_extras
  current_extras=$(jq -r '.extras | join(", ")' "${state_file}")

  echo "my-ai-box is installed at ${runtime_dir}."
  echo "Currently running: ${current_assistant} (extras: ${current_extras:-none})"
  echo
  local choice
  choice=$(prompt_choice "What would you like to do?" \
    "Add an extra" \
    "Remove an extra" \
    "Update everything" \
    "Show status / logs" \
    "Uninstall" \
    "Exit")
  case "${choice}" in
    "Add an extra")        cmd_add_extra ;;
    "Remove an extra")     cmd_remove_extra ;;
    "Update everything")   cmd_update ;;
    "Show status / logs")  cmd_status ;;
    "Uninstall")           cmd_uninstall ;;
    "Exit")                return 0 ;;
  esac
}
```

- [ ] **Step 4: Run, expect pass**

Run: `make test`
Expected: Menu tests pass.

- [ ] **Step 5: Commit**

```bash
git add bin/my-ai-box tests/bats/cli.bats
git commit -m "feat(cli): implement cmd_menu for re-run management"
```

---

### Task I4: Implement `cmd_uninstall`

**Files:**
- Modify: `bin/my-ai-box`
- Modify: `tests/bats/cli.bats`

- [ ] **Step 1: Add the failing test**

Append to `tests/bats/cli.bats`:

```bash
@test "my-ai-box uninstall: with --yes shreds .env and removes runtime dir" {
  setup_tmp
  local fake_root="${TEST_TMP}/opt/my-ai-box"
  mkdir -p "${fake_root}/data"
  echo "X=1" > "${fake_root}/.env"
  chmod 600 "${fake_root}/.env"
  jq -n '{schema_version:1}' > "${fake_root}/state.json"

  MY_AI_BOX_DRY_RUN=1 MY_AI_BOX_RUNTIME_DIR="${fake_root}" \
    run "${REPO_ROOT}/bin/my-ai-box" uninstall --yes
  assert_success
  assert [ ! -f "${fake_root}/.env" ]
  assert [ ! -d "${fake_root}/data" ]
}
```

- [ ] **Step 2: Run, expect failure**

Run: `make test`

- [ ] **Step 3: Replace the `cmd_uninstall` stub**

```bash
cmd_uninstall() {
  local runtime_dir="${MY_AI_BOX_RUNTIME_DIR:-/opt/my-ai-box}"
  local dry_run="${MY_AI_BOX_DRY_RUN:-0}"
  local assume_yes=0
  [[ "${1:-}" == "--yes" ]] && assume_yes=1

  if [[ ${assume_yes} -eq 0 ]]; then
    prompt_yesno "Delete all data + secrets at ${runtime_dir}?" "N" || {
      echo "aborted."; return 0
    }
  fi

  if [[ "${dry_run}" != "1" ]]; then
    ( cd "${runtime_dir}" 2>/dev/null && docker compose down --remove-orphans ) || true
  fi
  shred_env "${runtime_dir}/.env"
  rm -rf "${runtime_dir}/data"
  rm -f "${runtime_dir}/compose.yml" "${runtime_dir}/compose.override.yml" "${runtime_dir}/state.json"
  echo "✓ Uninstalled. The cloned repo at ${runtime_dir} can be 'rm -rf'd manually if you want."
}
```

- [ ] **Step 4: Run, expect pass**

Run: `make test`

- [ ] **Step 5: Commit**

```bash
git add bin/my-ai-box tests/bats/cli.bats
git commit -m "feat(cli): implement cmd_uninstall with --yes flag for unattended use"
```

---

## Phase J: `install.sh` bootstrapper

### Task J1: Create the bootstrapper

**Files:**
- Create: `install.sh`

The bootstrapper is the file fetched by `curl -fsSL get.my-ai-box.sh | bash`. It does just enough to get `bin/my-ai-box` running on a fresh VPS.

- [ ] **Step 1: Create `install.sh`**

Create `install.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# install.sh — the bootstrapper.
# Fetched by: curl -fsSL https://get.my-ai-box.sh | bash
#
# Pipeline:
#   1. require_root
#   2. detect_distro (Ubuntu 22.04 / 24.04 / Debian 12 only)
#   3. install curl, git, jq, ca-certificates if missing
#   4. install Docker via get.docker.com if missing
#   5. clone github.com/<USER>/my-ai-box to /opt/my-ai-box (or use $MY_AI_BOX_DIR)
#   6. exec /opt/my-ai-box/bin/my-ai-box install "$@"

readonly MY_AI_BOX_REPO_URL="${MY_AI_BOX_REPO_URL:-https://github.com/<USER>/my-ai-box.git}"
readonly MY_AI_BOX_VERSION="${MY_AI_BOX_VERSION:-main}"
readonly MY_AI_BOX_DIR="${MY_AI_BOX_DIR:-/opt/my-ai-box}"

log() { printf '[my-ai-box] %s\n' "$*"; }
die() { printf '[my-ai-box] error: %s\n' "$*" >&2; exit 1; }

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    die "must be run as root (try: curl -fsSL https://get.my-ai-box.sh | sudo bash)"
  fi
}

detect_distro() {
  if [[ ! -r /etc/os-release ]]; then
    die "cannot detect distro: /etc/os-release missing"
  fi
  # shellcheck disable=SC1091
  . /etc/os-release
  case "${ID:-}-${VERSION_ID:-}" in
    ubuntu-22.04|ubuntu-24.04|debian-12)
      log "detected: ${ID} ${VERSION_ID}"
      ;;
    *)
      die "unsupported distro: ${ID:-?} ${VERSION_ID:-?} (supported: Ubuntu 22.04/24.04, Debian 12)"
      ;;
  esac
}

install_deps() {
  log "installing base dependencies (curl git jq ca-certificates)…"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y curl git jq ca-certificates
}

install_docker() {
  if command -v docker >/dev/null 2>&1; then
    log "docker already installed: $(command -v docker)"
    return 0
  fi
  log "installing Docker via get.docker.com…"
  curl -fsSL https://get.docker.com | sh
}

clone_repo() {
  if [[ -d "${MY_AI_BOX_DIR}/.git" ]]; then
    log "repo exists at ${MY_AI_BOX_DIR}, fetching latest…"
    git -C "${MY_AI_BOX_DIR}" fetch --tags
    git -C "${MY_AI_BOX_DIR}" checkout "${MY_AI_BOX_VERSION}"
    git -C "${MY_AI_BOX_DIR}" pull --ff-only || true
  else
    log "cloning ${MY_AI_BOX_REPO_URL} (${MY_AI_BOX_VERSION}) to ${MY_AI_BOX_DIR}…"
    mkdir -p "$(dirname "${MY_AI_BOX_DIR}")"
    git clone --branch "${MY_AI_BOX_VERSION}" "${MY_AI_BOX_REPO_URL}" "${MY_AI_BOX_DIR}"
  fi
}

main() {
  require_root
  detect_distro
  install_deps
  install_docker
  clone_repo

  log "starting wizard…"
  # If this is a re-run on an existing install, jump into the menu.
  if [[ -f "${MY_AI_BOX_DIR}/state.json" ]]; then
    exec "${MY_AI_BOX_DIR}/bin/my-ai-box" menu "$@"
  else
    exec "${MY_AI_BOX_DIR}/bin/my-ai-box" install "$@"
  fi
}

main "$@"
```

- [ ] **Step 2: Make executable**

Run: `chmod +x install.sh`

- [ ] **Step 3: Run shellcheck on it**

Run: `shellcheck install.sh`
Expected: No warnings (or only style warnings we acknowledge).

- [ ] **Step 4: Commit**

```bash
git add install.sh
git commit -m "feat: add install.sh bootstrapper (require_root, detect_distro, install_deps, install_docker, clone_repo)"
```

---

## Phase K: `assistants/open-webui/`

### Task K1: Create the Open WebUI assistant module

**Files:**
- Create: `assistants/open-webui/compose.yml`
- Create: `assistants/open-webui/README.md`
- Create: `assistants/open-webui/install.sh` (post-install hook, optional)

`compose.yml` is read by `compose_render` and copied to `/opt/my-ai-box/compose.yml`. Variables like `${ANTHROPIC_API_KEY}` are resolved by Docker Compose from the `.env` file.

- [ ] **Step 1: Create `assistants/open-webui/compose.yml`**

Create `assistants/open-webui/compose.yml`:

```yaml
services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:0.6.32
    container_name: my-ai-box-open-webui
    restart: unless-stopped
    environment:
      OPENAI_API_KEY: "${OPENAI_API_KEY:-}"
      OPENAI_API_BASE_URL: "${OPENAI_API_BASE_URL:-}"
      ANTHROPIC_API_KEY: "${ANTHROPIC_API_KEY:-}"
      DEEPSEEK_API_KEY: "${DEEPSEEK_API_KEY:-}"
      OPENROUTER_API_KEY: "${OPENROUTER_API_KEY:-}"
      WEBUI_AUTH: "true"
      ENABLE_SIGNUP: "false"
    volumes:
      - ./data/open-webui:/app/backend/data
    networks:
      - my-ai-box-net

networks:
  my-ai-box-net:
    name: my-ai-box-net
```

- [ ] **Step 2: Create `assistants/open-webui/README.md`**

Create `assistants/open-webui/README.md`:

```markdown
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

Open Web UI also exposes its own admin UI for configuring providers, RAG sources, MCP servers, voice, and more. The wizard only sets the initial provider key; everything else is configured in the web UI.
```

- [ ] **Step 3: Create `assistants/open-webui/install.sh` (no-op for v1)**

Create `assistants/open-webui/install.sh`:

```bash
#!/usr/bin/env bash
# assistants/open-webui/install.sh
# Optional post-install hook for the Open WebUI assistant.
# Called by the wizard after `docker compose up` if it exists and is executable.
# v1 has no per-assistant post-install work to do, so this is a no-op.
set -euo pipefail
exit 0
```

- [ ] **Step 4: Make it executable**

Run: `chmod +x assistants/open-webui/install.sh`

- [ ] **Step 5: Run the previously-failing integration test**

Run: `make test`
Expected: The `--dry-run` integration test from Task I2 now passes.

- [ ] **Step 6: Commit**

```bash
git add assistants/open-webui/
git commit -m "feat(assistants): add open-webui module (compose.yml + README + no-op install hook)"
```

---

## Phase L: `extras/caddy/`

### Task L1: Create the Caddy extra module

**Files:**
- Create: `extras/caddy/compose-overlay.yml`
- Create: `extras/caddy/README.md`

- [ ] **Step 1: Create `extras/caddy/compose-overlay.yml`**

Create `extras/caddy/compose-overlay.yml`:

```yaml
services:
  caddy:
    image: caddy:2.10
    container_name: my-ai-box-caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./data/caddy/Caddyfile:/etc/caddy/Caddyfile:ro
      - ./data/caddy/data:/data
      - ./data/caddy/config:/config
    networks:
      - my-ai-box-net
    depends_on:
      - open-webui   # NB: this hard-codes open-webui; Plan 2 will generalize.
```

> **Plan 2 note:** This overlay currently lists `open-webui` as a `depends_on`. When other assistants are added in Plan 2, replace this with a wizard-generated overlay that depends on whichever assistant is installed. For Plan 1 this is acceptable because only Open WebUI exists.

- [ ] **Step 2: Create `extras/caddy/README.md`**

Create `extras/caddy/README.md`:

```markdown
# Caddy + TLS extra

Adds an automatic-TLS reverse proxy fronting the assistant's HTTP port.

- Container: `caddy:2.10`
- Ports: 80, 443
- Caddyfile path: `./data/caddy/Caddyfile` (generated by `lib/tls.sh::caddy_render`)
- Cert/data: `./data/caddy/data` (Caddy persists Let's Encrypt account + certs here)

The wizard validates that the chosen domain resolves to the VPS public IP before requesting a certificate. If validation fails, the wizard offers to retry or skip TLS.
```

- [ ] **Step 3: Commit**

```bash
git add extras/caddy/
git commit -m "feat(extras): add caddy module (compose overlay + README)"
```

---

## Phase M: End-to-end test

### Task M1: Multipass E2E test for the dry-run install

**Files:**
- Create: `tests/e2e/dry-run.bats`
- Create: `tests/e2e/run-in-multipass.sh`

E2E tests boot a fresh Ubuntu 24.04 VM via Multipass, mount the repo, and run the installer with `MY_AI_BOX_DRY_RUN=1`. This catches distro-specific bugs (apt versions, shell builtins) without paying the time cost of pulling Docker images.

- [ ] **Step 1: Document Multipass as a contributor prereq**

Append to `CONTRIBUTING.md`:

```markdown
## End-to-end tests

E2E tests run on local Multipass VMs. Install Multipass:
- macOS:    `brew install --cask multipass`
- Linux:    `snap install multipass`

Then run: `make test-e2e`
```

- [ ] **Step 2: Create the wrapper script**

Create `tests/e2e/run-in-multipass.sh`:

```bash
#!/usr/bin/env bash
# tests/e2e/run-in-multipass.sh
# Runs the dry-run install inside a fresh Multipass VM and asserts artifacts.
set -euo pipefail

VM_NAME="my-ai-box-e2e-$RANDOM"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

cleanup() {
  multipass delete "${VM_NAME}" 2>/dev/null || true
  multipass purge 2>/dev/null || true
}
trap cleanup EXIT

echo "[e2e] launching VM ${VM_NAME}…"
multipass launch 24.04 --name "${VM_NAME}" --cpus 2 --memory 2G --disk 10G

echo "[e2e] mounting repo into VM…"
multipass mount "${REPO_ROOT}" "${VM_NAME}:/repo"

echo "[e2e] running dry-run install…"
multipass exec "${VM_NAME}" -- sudo bash -c '
  set -euo pipefail
  MY_AI_BOX_DRY_RUN=1 \
  MY_AI_BOX_RUNTIME_DIR=/tmp/runtime \
  MY_AI_BOX_NONINTERACTIVE=1 \
  MY_AI_BOX_ASSISTANT=open-webui \
  MY_AI_BOX_DOMAIN=chat.example.com \
  MY_AI_BOX_EMAIL=you@example.com \
  MY_AI_BOX_PROVIDER=anthropic \
  MY_AI_BOX_API_KEY=sk-test-123 \
  MY_AI_BOX_EXTRAS=caddy \
  /repo/bin/my-ai-box install
'

echo "[e2e] asserting artifacts…"
multipass exec "${VM_NAME}" -- bash -c '
  set -e
  test -f /tmp/runtime/state.json || { echo "missing state.json" >&2; exit 1; }
  test -f /tmp/runtime/.env       || { echo "missing .env" >&2; exit 1; }
  test -f /tmp/runtime/compose.yml || { echo "missing compose.yml" >&2; exit 1; }
  test -f /tmp/runtime/compose.override.yml || { echo "missing compose.override.yml" >&2; exit 1; }
  stat -c "%a" /tmp/runtime/.env | grep -q "^600$" || { echo ".env not mode 0600" >&2; exit 1; }
  echo "[e2e] all assertions passed"
'
```

- [ ] **Step 3: Make it executable + add Makefile target**

Run: `chmod +x tests/e2e/run-in-multipass.sh`

Append to `Makefile`:

```makefile
test-e2e:
	tests/e2e/run-in-multipass.sh
```

- [ ] **Step 4: Run locally (requires Multipass installed)**

Run: `make test-e2e`
Expected: VM boots, installer runs dry-run, all assertions pass, VM is cleaned up.

- [ ] **Step 5: Commit**

```bash
git add tests/e2e/ Makefile CONTRIBUTING.md
git commit -m "test(e2e): add Multipass dry-run test for non-interactive install"
```

---

## Phase N: README content (basic)

### Task N1: Replace the README skeleton with launch-quality v0.1 content

**Files:**
- Modify: `README.md`

Full launch-quality README (logo, GIF, full features list) is Plan 4. This task writes a clean, honest v0.1 README that's correct for what Plan 1 ships.

- [ ] **Step 1: Replace `README.md`**

```markdown
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

- A fresh Linux VPS (Ubuntu 22.04+, Debian 12). 2 vCPU / 4 GB RAM / 80 GB disk minimum.
- A domain (for HTTPS), or skip and run on the VPS IP over HTTP.
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
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: write v0.1 README (install, providers, key location, curl|bash alternative, roadmap)"
```

---

## Phase O: Final verification + tag v0.1.0

### Task O1: Full local verification

- [ ] **Step 1: Run all bats tests**

Run: `make test`
Expected: 0 failures across all `.bats` files.

- [ ] **Step 2: Run shellcheck across all shell sources**

Run: `make lint`
Expected: No warnings.

- [ ] **Step 3: Run the E2E test**

Run: `make test-e2e`
Expected: Multipass test passes.

- [ ] **Step 4: Sanity-check the help output**

Run: `bin/my-ai-box --help`
Expected: Help text listing install, menu, add-extra, remove-extra, update, uninstall, status, logs, doctor.

- [ ] **Step 5: Sanity-check `--version`**

Run: `bin/my-ai-box --version`
Expected: `my-ai-box 0.1.0-dev`

---

### Task O2: Tag v0.1.0

- [ ] **Step 1: Bump version to `0.1.0`**

Edit `bin/my-ai-box`:

```bash
readonly MY_AI_BOX_VERSION="0.1.0"
```

- [ ] **Step 2: Commit and tag**

```bash
git add bin/my-ai-box
git commit -m "chore(release): v0.1.0"
git tag -a v0.1.0 -m "v0.1.0 — Open WebUI + Caddy end-to-end installer"
```

- [ ] **Step 3: (Optional, manual) Create the GitHub repo + push**

Run, once the user has supplied the GitHub handle:
```bash
gh repo create <USER>/my-ai-box --public --source=. --description "Your AI assistant on your own VPS in 90 seconds."
git push -u origin main
git push origin v0.1.0
```

- [ ] **Step 4: (Optional, manual) Register `get.my-ai-box.sh`**

Once the domain is registered, host `install.sh` at `https://get.my-ai-box.sh` (e.g., redirect to the raw GitHub URL of `install.sh` at tag `v0.1.0`).

---

## Self-Review

After writing the plan, the writing-plans skill asks for a coverage / placeholder / type-consistency check. I did this inline and found:

1. **Coverage check:** Every spec section §1–§16 is exercised by Plan 1 or explicitly deferred to Plans 2–4. Specifically:
   - §3 (target user) → README content (Phase N) + non-interactive flag for power users (Task I2).
   - §4 (assistants) → Open WebUI in Plan 1; LibreChat/AnythingLLM/Aider deferred to Plan 2 (documented in Phase L's overlay note).
   - §5 (extras) → Caddy in Plan 1; others deferred to Plan 3.
   - §7 (user flows) → install + menu + uninstall implemented (Tasks I2/I3/I4); add-extra/remove-extra/update/status/logs/doctor stubbed and deferred to Plan 2.
   - §8 (architecture) → fully realized (lib/, bin/, install.sh, repo layout, /opt/my-ai-box).
   - §9 (reverse proxy/TLS) → Caddy module + caddy_render + validate_domain.
   - §10 (secrets) → `lib/secrets.sh` with 0600 enforcement + README "Where your API keys live".
   - §11 (error handling) → distro detect, set -euo pipefail, idempotent re-run via state.json.
   - §12 (testing) → bats + shellcheck + Multipass E2E.
   - §13 (README) → v0.1 minimal README; full polish in Plan 4.
   - §15 (success criteria) → Phase O verifies all six.
   - §16 (next steps) → this whole plan + Plans 2–4 stated in the header.

2. **Placeholder scan:** No `TBD` / `TODO` / `implement later` / "add appropriate error handling" / "write tests for the above" patterns. Each step shows the actual code or command. The deliberate placeholders are explicitly flagged: `<USER>` for the GitHub handle (called out in the plan header), `<author name>` and `<author email>` in LICENSE / CODE_OF_CONDUCT (cosmetic, doesn't block execution).

3. **Type consistency:** Function signatures cross-check:
   - `detect_distro` echoes `ubuntu-24.04`-style strings (Phase C) — consistent everywhere it's referenced.
   - `prompt_choice`, `prompt_yesno`, `prompt_string`, `prompt_secret` all echo to stdout / return via exit code consistently with how the wizard uses them in `cmd_install`.
   - `write_state` / `read_state` use `key=value` pair args in tests and in `cmd_install`.
   - `compose_render <repo_root> <runtime_dir> <assistant> <extras_space_separated>` signature is consistent in test and call site.
   - `assistant_upstream` returns service:port format used by `caddy_render`'s upstream param.

4. **Scope check:** Plan is 4 phases of infrastructure (A, B, C–H libs), 1 phase of CLI (I), 1 phase of bootstrap (J), 2 phases of one assistant + one extra (K, L), 3 phases of test/docs/release (M, N, O). ~22 tasks, each 2–5 minutes per step at ~5 steps per task → ~5–10 hours of work for a skilled engineer. Self-contained: at the end you have a working `curl | bash` installer for one assistant.

No additional revisions needed.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-05-20-my-ai-box-foundation.md`. Two execution options:

**1. Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration. Best for keeping the main session clean.

**2. Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints. Best if you want to watch closely.

Which approach? (Or, if you want me to draft Plan 2 / 3 / 4 first before executing anything, say so.)
