#!/usr/bin/env bash
# 对目录做带时间戳的快照备份（增量，依赖 rsync；Windows 上回退到 robocopy）。
#
# 用法:
#   backup_snapshot.sh <源目录> <备份根目录>
#
# 行为:
#   - 在 <备份根目录> 下创建 YYYYMMDD-HHMMSS 命名的子目录作为本次快照。
#   - 优先使用 rsync（增量、保留属性）；不存在则尝试 robocopy（Windows）。
#   - 已存在快照时，rsync 会做硬链接/增量，节省空间。

set -euo pipefail

usage() {
  echo "用法: $0 <源目录> <备份根目录>" >&2
  exit 1
}

[ $# -eq 2 ] || usage
SRC="$1"
DST_ROOT="$2"

[ -d "$SRC" ] || { echo "源目录不存在: $SRC" >&2; exit 1; }
mkdir -p "$DST_ROOT"

STAMP=$(date +%Y%m%d-%H%M%S)
SNAP="$DST_ROOT/$STAMP"

if command -v rsync >/dev/null 2>&1; then
  echo "使用 rsync 创建快照: $SNAP"
  # 找上一个快照做增量基准（可选）
  PREV=$(ls -1 "$DST_ROOT" 2>/dev/null | grep -E '^[0-9]{8}-[0-9]{6}$' | tail -1 || true)
  if [ -n "$PREV" ] && [ -d "$DST_ROOT/$PREV" ]; then
    rsync -aH --delete --link-dest="$DST_ROOT/$PREV" "$SRC/" "$SNAP/"
  else
    rsync -aH "$SRC/" "$SNAP/"
  fi
elif command -v robocopy >/dev/null 2>&1; then
  echo "使用 robocopy 创建快照: $SNAP"
  mkdir -p "$SNAP"
  # /MIR 镜像源；/R:1 /W:1 失败快速跳过
  robocopy "$SRC" "$SNAP" /MIR /R:1 /W:1 /NFL /NDL /NP >/dev/null || true
else
  echo "未找到 rsync 或 robocopy，无法备份。" >&2
  exit 1
fi

echo "快照完成: $SNAP"
