# SafeClaw architecture

## Overview

SafeClaw runs Claude Code inside a sandboxed Docker container, accessible via a web terminal. A lightweight Node server handles session management and notifications.

## Web terminal

The user interacts with Claude Code through a browser, not a local terminal. This gives full access to the native Claude Code UI rather than building a custom one on top of the Agent SDK.

### Current approach: ttyd + tmux

- **ttyd** serves a web terminal over HTTP/WebSocket on port 7681
- **tmux** manages the Claude Code session inside the container
- One port, one ttyd process, one tmux session per container
- Full Claude Code UI - status line, colors, interactive prompts, everything
- No custom UI code needed

### Future: xterm.js + WebSocket

If we need per-session URLs (`/session/abc123`) or tighter integration with the Node server, we can swap ttyd for xterm.js served from the Node server. This would require:

- node-pty (native addon, needs build tools in the container)
- ~50-100 lines of WebSocket + HTML code
- The tmux sessions stay the same regardless

Not needed yet. ttyd is simpler and sufficient for now.

## Notifications: Discord

Notifications go through a Discord bot. The Node server posts to a Discord channel when something needs attention (task done, error, needs input).

### Why Discord over WhatsApp

- Discord has an official, stable bot SDK
- WhatsApp has no official bot API for personal use. The main library (`@whiskeysockets/baileys`) is an unofficial reverse-engineered implementation - security risk

### How it works

- Bot token + your Discord user ID stored alongside other secrets
- Node server uses discord.js to post messages
- Notifications only - all actual interaction happens through the web terminal

## Node server

A lightweight Node.js server running inside the container. Responsibilities:

- Start and manage ttyd + tmux
- Track Claude Code session IDs (for resume)
- Send Discord notifications
- Expose a simple HTTP API for health checks

The server does not replace Claude Code's UI or manage conversations directly. It's just the orchestrator.

## Authentication

Tokens are stored in `~/.config/safeclaw/.secrets/` on the host. `run.sh` reads them and injects as env vars on each `docker exec`.

| File | Env var | How to generate |
|------|---------|-----------------|
| `claude_oauth_token` | `CLAUDE_CODE_OAUTH_TOKEN` | `claude setup-token` (valid 1 year, uses Claude subscription) |
| `gh_token` | `GH_TOKEN` | Create a separate GitHub account for SafeClaw, log in with `gh auth login`, then `gh auth token` |

### How it works (in `scripts/run.sh`)

1. Check `~/.config/safeclaw/.secrets/` for each token file
2. If missing, walk the user through generating it interactively, save to host
3. On every run, inject as env vars when entering the container:
   `docker exec -e CLAUDE_CODE_OAUTH_TOKEN=$(cat ...) -e GH_TOKEN=$(cat ...) -it safeclaw /bin/bash`

Tokens only live on the host filesystem. Nothing is copied into the container.

## Implementation status

### Done

- Token-based auth (run.sh interactive setup, env var injection)
- All container setup baked into Dockerfile (DX plugin, Playwright MCP, aliases, status line)

### To do

- Add ttyd to Dockerfile
- Update run.sh to map port 7681 and start ttyd inside the container
- Node server for session management and Discord notifications
