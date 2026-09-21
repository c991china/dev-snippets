#!/usr/bin/env bash
# 给目录打带时间戳的快照（tar.gz）。
# 用法：bash backup_snapshot.sh /path/to/source [输出目录]
set -euo pipefail
SRC="${1:?用法: backup_snapshot.sh <源目录> [输出目录]}"
OUT="${2:-.}"
TS="$(date +%Y%m%d_%H%M%S)"
NAME="$(basename "$SRC")_$TS.tar.gz"
tar -czf "$OUT/$NAME" -C "$(dirname "$SRC")" "$(basename "$SRC")"
echo "已生成快照: $OUT/$NAME"
