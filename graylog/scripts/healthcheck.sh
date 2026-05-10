#!/usr/bin/env bash
# Checks whether each service in the stack is reachable and healthy.
# Usage: ./healthcheck.sh [graylog-host]
set -euo pipefail

HOST="${1:-127.0.0.1}"
PASS=0
FAIL=0

check() {
  local label="$1"
  local url="$2"
  local expected="$3"

  if curl -sf --max-time 5 "$url" | grep -q "$expected" 2>/dev/null; then
    echo "  [OK]  $label"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $label  ($url)"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Graylog CEF Lab — Health Check ==="
echo

check "OpenSearch cluster" \
  "http://${HOST}:9200/_cluster/health" \
  '"status"'

check "Graylog API" \
  "http://${HOST}:9000/api/system/lbstatus" \
  "ALIVE"

check "Graylog UI" \
  "http://${HOST}:9000/" \
  "Graylog"

echo
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ $FAIL -eq 0 ]]
