# SafeClaw

Safety-first personal AI assistant. All execution happens in Docker - no host access.

## Quick start

```bash
# Build image (once, or after changes)
./scripts/build.sh

# Run and enter interactively
./scripts/run.sh
```

On first run, `run.sh` will prompt you to set up authentication tokens for Claude Code and GitHub CLI.

## What's included

- Ubuntu 24.04
- Node.js 24 (LTS)
- Claude Code 2.1.19
- GitHub CLI
- Playwright MCP with Chromium
- DX plugin, status line, aliases

## Authentication

Tokens are stored on the host in `~/.config/safeclaw/.secrets/` and injected as env vars on each `docker exec`. Nothing is copied into the container.

| Token file | Env var | How to generate |
|------------|---------|-----------------|
| `claude_oauth_token` | `CLAUDE_CODE_OAUTH_TOKEN` | `claude setup-token` (valid 1 year) |
| `gh_token` | `GH_TOKEN` | `gh auth token` or create a PAT at github.com/settings/tokens |

For cloud deployment, pass the same env vars directly:

```bash
docker run -e CLAUDE_CODE_OAUTH_TOKEN=... -e GH_TOKEN=... safeclaw
```

## Scripts

| Script | Description |
|--------|-------------|
| `scripts/build.sh` | Build the Docker image and remove old container |
| `scripts/run.sh` | Start/reuse container, set up auth tokens, enter interactively |
