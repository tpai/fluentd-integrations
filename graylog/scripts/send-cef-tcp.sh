#!/usr/bin/env bash
# Sends sample CEF events to Graylog over TCP.
# Usage: ./send-cef-tcp.sh [host] [port]
set -euo pipefail

HOST="${1:-127.0.0.1}"
PORT="${2:-5514}"
SAMPLES_FILE="$(dirname "$0")/../samples/cef-events.txt"

if ! command -v nc &>/dev/null; then
  echo "Error: nc (netcat) is required. Install with: brew install netcat  OR  apt-get install netcat-openbsd" >&2
  exit 1
fi

if [[ ! -f "$SAMPLES_FILE" ]]; then
  echo "Error: $SAMPLES_FILE not found" >&2
  exit 1
fi

echo "Sending CEF events to TCP ${HOST}:${PORT} ..."
echo

count=0
while IFS= read -r line || [[ -n "$line" ]]; do
  # Skip blank lines and comment lines
  [[ -z "$line" || "$line" == \#* ]] && continue

  echo "  → ${line:0:100}..."
  printf '%s\n' "$line" | nc -q 1 "$HOST" "$PORT"
  count=$((count + 1))
  sleep 0.2
done < "$SAMPLES_FILE"

echo
echo "Sent ${count} event(s). Check Graylog Search at http://${HOST}:9000/search"
