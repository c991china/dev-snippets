#!/usr/bin/env bash
# 社区贡献：检查端口占用（by 22178384）
port="$1"
[ -z "$port" ] && { echo "usage: community_port.sh <port>"; exit 1; }
(command -v ss >/dev/null && ss -ltnp 2>/dev/null | grep ":$port") || echo "port $port free"
