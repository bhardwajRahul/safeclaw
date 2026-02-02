#!/bin/bash
# Start/reuse container, sync auth, start ttyd web terminal

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTAINER_NAME="safeclaw"
SECRETS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/safeclaw/.secrets"

# Check if image exists
if ! docker images -q safeclaw | grep -q .; then
    echo "Error: Image 'safeclaw' not found. Run ./scripts/build.sh first."
    exit 1
fi

# Check if container exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "Reusing running container: $CONTAINER_NAME"
    else
        echo "Starting existing container: $CONTAINER_NAME"
        docker start "$CONTAINER_NAME" > /dev/null
    fi
else
    echo "Creating container: $CONTAINER_NAME"
    docker run -d --ipc=host --name "$CONTAINER_NAME" -p 7681:7681 safeclaw sleep infinity > /dev/null
fi

# === Sync Claude Code auth ===
# Auth requires two files: .claude.json (account info) and .claude/.credentials.json (OAuth token)
# On fresh containers, restore from host backup. On existing containers, save to host.

SAFECLAW_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/safeclaw"
HOST_CLAUDE_JSON="$SAFECLAW_DIR/.claude.json"
HOST_CREDENTIALS="$SAFECLAW_DIR/.credentials.json"
CONTAINER_CLAUDE_JSON="/home/sclaw/.claude.json"
CONTAINER_CREDENTIALS="/home/sclaw/.claude/.credentials.json"

container_has_auth=false
docker exec "$CONTAINER_NAME" test -f "$CONTAINER_CREDENTIALS" 2>/dev/null && container_has_auth=true

if [ -f "$HOST_CREDENTIALS" ] && [ "$container_has_auth" = false ]; then
    echo "Restoring Claude Code auth into container..."
    docker cp "$HOST_CLAUDE_JSON" "$CONTAINER_NAME:$CONTAINER_CLAUDE_JSON"
    docker exec -u root "$CONTAINER_NAME" chown sclaw:sclaw "$CONTAINER_CLAUDE_JSON"
    docker cp "$HOST_CREDENTIALS" "$CONTAINER_NAME:$CONTAINER_CREDENTIALS"
    docker exec -u root "$CONTAINER_NAME" chown sclaw:sclaw "$CONTAINER_CREDENTIALS"
elif [ "$container_has_auth" = true ]; then
    echo "Saving Claude Code auth to host..."
    mkdir -p "$SAFECLAW_DIR"
    docker cp "$CONTAINER_NAME:$CONTAINER_CLAUDE_JSON" "$HOST_CLAUDE_JSON"
    docker cp "$CONTAINER_NAME:$CONTAINER_CREDENTIALS" "$HOST_CREDENTIALS"
else
    echo "No Claude Code auth found. Log in with /login through the web terminal."
fi

# === GitHub CLI token setup ===

mkdir -p "$SECRETS_DIR"

if [ ! -f "$SECRETS_DIR/gh_token" ]; then
    echo ""
    echo "=== GitHub CLI setup ==="
    echo ""
    echo "No GitHub token found. Let's set one up."
    echo ""
    echo "We recommend creating a separate GitHub account for SafeClaw"
    echo "so you can scope its permissions independently."
    echo ""
    echo "Once logged in, run this in another terminal:"
    echo ""
    echo "  gh auth token"
    echo ""
    echo "Or create a Personal Access Token at:"
    echo "  https://github.com/settings/tokens"
    echo ""
    echo "Paste the token below."
    echo ""
    read -p "Token: " gh_token

    if [ -n "$gh_token" ]; then
        echo "$gh_token" > "$SECRETS_DIR/gh_token"
        echo "Saved to $SECRETS_DIR/gh_token"
    else
        echo "No token provided, skipping. You can set it up later by re-running this script."
    fi
fi

# Build env var flags for GH_TOKEN
ENV_FLAGS=""
if [ -f "$SECRETS_DIR/gh_token" ]; then
    ENV_FLAGS="$ENV_FLAGS -e GH_TOKEN=$(cat "$SECRETS_DIR/gh_token")"
fi

# Start ttyd with wrapper that passes env vars through to tmux
docker exec $ENV_FLAGS -d "$CONTAINER_NAME" \
    ttyd -W -p 7681 /home/sclaw/ttyd-wrapper.sh

echo ""
echo "SafeClaw is running at: http://localhost:7681"
echo ""
echo "To stop: docker stop $CONTAINER_NAME"
