#!/usr/bin/env bash
# Generates a 96-character random string suitable for GRAYLOG_PASSWORD_SECRET.
set -euo pipefail

secret=$(openssl rand -hex 48)
echo "GRAYLOG_PASSWORD_SECRET=${secret}"
