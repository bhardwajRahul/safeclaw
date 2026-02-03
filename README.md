# SafeClaw

The easiest way to run Claude Code in a Docker container. Secure, cloud-ready, with sensible defaults.

See [architecture.md](architecture.md) for design details.

## Why a container?

- **Isolated** - Claude Code runs with bypass permissions, but can't touch your host machine. A lightweight alternative to a full VM.
- **Portable** - Works on any machine with Docker (or Podman). Same environment everywhere.
- **Cloud-ready** - Auth via environment variables. Deploy anywhere by setting `CLAUDE_CODE_OAUTH_TOKEN` and `GH_TOKEN`.

## Quick start

```bash
# Build image (once, or after changes)
./scripts/build.sh

# Start container and web terminal
./scripts/run.sh

# To mount a local project (host_path:container_path)
./scripts/run.sh -v ~/myproject:/home/sclaw/myproject

# Run multiple sessions with -s
./scripts/run.sh -s work        # safeclaw-work on next available port
./scripts/run.sh -s research    # safeclaw-research on next available port
```

On first run, `run.sh` will prompt you to set up authentication tokens. It then starts a web terminal at http://localhost:7681 and opens it in your browser.

## Dashboard

Manage all sessions from a web dashboard:

```bash
node dashboard/server.js
```

Opens at http://localhost:7680 with:
- All sessions listed with start/stop/delete controls
- Live iframe views of active sessions
- Real-time updates via Docker events

## What's included

- Ubuntu 24.04
- Node.js 24 (LTS)
- Claude Code 2.1.19 (pinned, with [optimized system prompt](https://github.com/ykdojo/claude-code-tips#tip-15-slim-down-the-system-prompt) - ~45KB smaller)
- GitHub CLI with auto-configured git user
- Playwright MCP with Chromium
- Gemini CLI 0.26.0 (optional - requires API key)
- Slack read-only skill and tool (optional - requires token)
- [DX plugin](https://github.com/ykdojo/claude-code-tips#tip-44-install-the-dx-plugin), [custom status line](https://github.com/ykdojo/claude-code-tips#tip-0-customize-your-status-line), shell aliases
- ttyd web terminal + tmux

## Authentication

Tokens are stored in `~/.config/safeclaw/.secrets/` and injected as env vars on each run. The filename becomes the env var name.

| File | How to generate |
|------|-----------------|
| `CLAUDE_CODE_OAUTH_TOKEN` | `claude setup-token` (valid 1 year) |
| `GH_TOKEN` | `gh auth token` or create a PAT at github.com/settings/tokens |

You can add any additional secrets by creating files in the `.secrets/` directory. For example, `SLACK_TOKEN` becomes the `SLACK_TOKEN` env var.

## Optional integrations

- `./scripts/setup-gemini.sh` - Add Gemini CLI access
- `./scripts/setup-slack.sh` - Add Slack read access

## Scripts

| Script | Description |
|--------|-------------|
| `scripts/build.sh` | Build the Docker image and remove old container |
| `scripts/run.sh` | Start/reuse container, inject auth, start ttyd. Use `-s name` for named sessions, `-v` for volumes, `-n` to skip opening browser. |
| `scripts/restart.sh` | Kill and restart the web terminal (ttyd + tmux). Use `-s name` for named sessions. |
| `scripts/setup-gemini.sh` | Set up Gemini CLI (optional) |
| `scripts/setup-slack.sh` | Set up Slack integration (optional) |
| `dashboard/server.js` | Web dashboard for managing multiple sessions |
