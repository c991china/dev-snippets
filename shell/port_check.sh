#!/usr/bin/env bash
# 检查本地端口是否被占用：port_check.sh 8080
set -euo pipefail
port="${1:?用法: port_check.sh <端口>}"
if command -v ss >/dev/null 2>&1; then
  if ss -ltn | awk '{print $4}' | grep -q ":$port$"; then
    echo "端口 $port 已被占用"
    exit 1
  fi
fi
echo "端口 $port 可用"
