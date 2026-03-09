#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "╔══════════════════════════════════╗"
echo "║       Secure Tunnel Manager      ║"
echo "╚══════════════════════════════════╝"
echo ""

printf "Enter access key: "
read -r KEY
KEY="$(echo "$KEY" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"

if [ "$KEY" != "tunnelmaster" ]; then
  echo ""
  echo "Invalid key."
  echo "Contact administrator."
  exit 1
fi

echo ""
echo "Access granted. Downloading manager..."

script_file="$(mktemp)"
cleanup(){ rm -f "$script_file"; }
trap cleanup EXIT

if curl -fsSL -o "$script_file" "$WORKER_URL/manager.sh"; then
  bash "$script_file"
else
  echo "Download failed."
  exit 1
fi
