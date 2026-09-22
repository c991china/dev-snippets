#!/usr/bin/env bash
# port_check.sh - check whether a TCP port is open, with a timeout.
#
# Why: `nc -z` isn't installed everywhere, and I wanted one script that works
# on a bare container image. Uses bash's /dev/tcp which needs no extra tools.
#
# Usage:
#   ./port_check.sh 127.0.0.1 5432
#   ./port_check.sh db.internal 6379 2      # custom timeout in seconds
#
# Exit codes:
#   0 = open, 1 = closed/timeout, 2 = bad args
#
# Gotchas:
#   - /dev/tcp is a BASH feature. This will not run under `sh` or dash.
#   - A firewall that DROPs (not rejects) looks identical to "closed" here:
#     both just time out. Use `timeout`-wrapped tcpdump if you need to tell them
#     apart.
#   - IPv6 addresses need brackets if you pass a literal: [::1]
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: $0 <host> <port> [timeout_seconds]" >&2
  exit 2
fi

host="$1"
port="$2"
timeout_s="${3:-3}"

# Validate the port is a number in range; catch typos early.
if ! [[ "$port" =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
  echo "invalid port: $port" >&2
  exit 2
fi

# `timeout` guards against a hang when packets are silently dropped.
if timeout "$timeout_s" bash -c "exec 3<>/dev/tcp/${host}/${port}" 2>/dev/null; then
  echo "OPEN   ${host}:${port}"
  exit 0
else
  echo "CLOSED ${host}:${port} (or timed out after ${timeout_s}s)"
  exit 1
fi
