#!/bin/bash
# Set up a custom environment variable for SafeClaw

SECRETS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/safeclaw/.secrets"

echo ""
echo "=== Custom Environment Variable ==="
echo ""
echo "Example: OPENAI_API_KEY"
echo ""
read -p "Name: " var_name

if [ -z "$var_name" ]; then
    echo "No name provided. Aborting."
    exit 1
fi

if ! [[ "$var_name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
    echo "Invalid name. Use letters, numbers, and underscores only."
    exit 1
fi

echo ""
read -p "Value: " var_value

if [ -z "$var_value" ]; then
    echo "No value provided. Aborting."
    exit 1
fi

mkdir -p "$SECRETS_DIR"
echo -n "$var_value" > "$SECRETS_DIR/$var_name"
chmod 600 "$SECRETS_DIR/$var_name"

echo ""
echo "Saved to $SECRETS_DIR/$var_name"
echo "Restart SafeClaw to use: ./scripts/run.sh"
