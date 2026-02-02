#!/bin/bash
# Kill ttyd + tmux and restart the web terminal

CONTAINER_NAME="safeclaw"
SECRETS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/safeclaw/.secrets"

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Container '$CONTAINER_NAME' is not running. Use ./scripts/run.sh instead."
    exit 1
fi

echo "Restarting web terminal..."
docker exec "$CONTAINER_NAME" pkill -f ttyd
docker exec "$CONTAINER_NAME" tmux kill-server 2>/dev/null

sleep 1

# Build env var flags
ENV_FLAGS=""
if [ -f "$SECRETS_DIR/claude_oauth_token" ]; then
    ENV_FLAGS="$ENV_FLAGS -e CLAUDE_CODE_OAUTH_TOKEN=$(cat "$SECRETS_DIR/claude_oauth_token")"
fi
if [ -f "$SECRETS_DIR/gh_token" ]; then
    ENV_FLAGS="$ENV_FLAGS -e GH_TOKEN=$(cat "$SECRETS_DIR/gh_token")"
fi

docker exec $ENV_FLAGS -d "$CONTAINER_NAME" \
    ttyd -W -p 7681 /home/sclaw/ttyd-wrapper.sh

echo "SafeClaw is running at: http://localhost:7681"

if command -v open >/dev/null 2>&1; then
    open http://localhost:7681
elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open http://localhost:7681
fi
