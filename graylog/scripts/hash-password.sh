#!/usr/bin/env bash
# Outputs the SHA-256 hash of the supplied password for GRAYLOG_ROOT_PASSWORD_SHA2.
set -euo pipefail

password="${1:-}"
if [[ -z "$password" ]]; then
  echo "Usage: $0 <password>" >&2
  exit 1
fi

hash=$(printf '%s' "$password" | openssl dgst -sha256 -binary | xxd -p | tr -d '\n')
echo "GRAYLOG_ROOT_PASSWORD_SHA2=${hash}"
