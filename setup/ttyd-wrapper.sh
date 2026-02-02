#!/bin/bash
# Save inherited env vars for tmux shells to source
env | grep -E '^(CLAUDE_CODE_OAUTH_TOKEN|GH_TOKEN)=' > ~/.safeclaw-env
sed -i 's/^/export /' ~/.safeclaw-env

exec tmux -f /dev/null new -A -s main \; set status off \; set mouse on \; send-keys 'claude --dangerously-skip-permissions' Enter
