# SafeClaw

Sandboxed Docker container running Claude Code, accessible via a web terminal.

See [architecture.md](architecture.md) for full design details.

## Testing end to end

After making changes, rebuild and test:

```bash
./scripts/build.sh
./scripts/run.sh
```

This opens http://localhost:7681 in the browser. Verify:
1. Claude Code launches automatically with bypass permissions
2. Confirm it shows the correct model (Opus 4.5) and doesn't ask for login
3. Send a message and confirm it gets a response

If the web terminal is frozen, run `./scripts/restart.sh`.

## Multiple sessions

Run multiple isolated sessions with `-s`:

```bash
./scripts/run.sh                    # default on port 7681
./scripts/run.sh -s work            # safeclaw-work on next available port
./scripts/run.sh -s research        # safeclaw-research on next available port
```

## Dashboard

Start the dashboard to manage all sessions:

```bash
node dashboard/server.js
```

Opens at http://localhost:7680. Shows all sessions with:
- Start/stop/delete buttons
- Live iframes of active sessions
- Auto-refreshes via Docker events (SSE)

## Starting and stopping containers

Always use these methods (they handle ttyd startup):
- `./scripts/run.sh -s name` - create or start a session
- Dashboard "start" button - start a stopped session
- `./scripts/restart.sh -s name` - restart ttyd in a running session

**Don't use raw `docker start`** - it won't start ttyd inside the container.

## Sending commands to the container via tmux

When sending commands to the container's tmux session with `tmux send-keys`, the message may not go through on the first Enter. If `tmux capture-pane` shows the prompt is still empty (the `❯` line has no text after it, or the text is there but hasn't been submitted), send additional Enter keys:

```bash
docker exec safeclaw tmux send-keys -t main Enter
```

For named sessions, use the container name:

```bash
docker exec safeclaw-work tmux send-keys -t main 'your command' Enter
docker exec safeclaw-work tmux send-keys -t main Enter
docker exec safeclaw-work tmux capture-pane -t main -p
```

Always verify with `tmux capture-pane -t main -p` that the command was actually submitted.
