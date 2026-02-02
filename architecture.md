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

### Claude Code

Token from `claude setup-token` is stored in `~/.config/safeclaw/.secrets/claude_oauth_token` on the host. `run.sh` injects it as `CLAUDE_CODE_OAUTH_TOKEN` via `docker exec -e`. The ttyd wrapper script writes it to a file that `.bashrc` sources, so tmux shells pick it up.

The Dockerfile sets `hasCompletedOnboarding: true` in `.claude.json` to skip the onboarding flow. Without this, interactive mode ignores the token and shows the login screen ([known issue](https://github.com/anthropics/claude-code/issues/8938)). Known limitation: the token from `setup-token` has limited scopes (`user:inference` only), so `/usage` doesn't work and the status bar shows "Claude API" instead of the subscription name ([#11985](https://github.com/anthropics/claude-code/issues/11985)). Chat works fine.

### GitHub CLI

`GH_TOKEN` is stored in `~/.config/safeclaw/.secrets/gh_token` on the host. `run.sh` injects it as an env var via `docker exec -e`. The ttyd wrapper script writes it to a file that `.bashrc` sources, so tmux shells pick it up.

We recommend creating a separate GitHub account for SafeClaw so you can scope its permissions independently.

## Implementation status

### Done

- All container setup baked into Dockerfile (DX plugin, Playwright MCP, aliases, status line)
- ttyd + tmux web terminal (port 7681)
- Claude Code auth via .claude.json sync from host
- GitHub auth via GH_TOKEN env var

### To do

- Node server for session management and Discord notifications
