#!/usr/bin/env python3
"""打印目录树，显示每个条目大小与层级，支持深度与名称过滤。

用法:
    python file_tree.py <root> [--max-depth N] [--include GLOB] [--no-size]

仅依赖标准库，Python 3.7+ 可用。
"""
import argparse
import os
import sys


def human_size(num: int) -> str:
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if abs(num) < 1024.0:
            return f"{num:3.1f}{unit}"
        num /= 1024.0
    return f"{num:.1f}PB"


def walk(root: str, max_depth: int, include: str | None, show_size: bool) -> None:
    root = os.path.abspath(root)
    if not os.path.isdir(root):
        print(f"错误：路径不存在或不是目录: {root}", file=sys.stderr)
        sys.exit(1)

    print(root)

    def rec(path: str, depth: int) -> None:
        if max_depth is not None and depth > max_depth:
            return
        try:
            entries = sorted(os.listdir(path))
        except PermissionError:
            print("  " * depth + "  [无权限]")
            return
        for name in entries:
            if name.startswith(".git"):
                continue
            if include and not _match(name, include):
                continue
            full = os.path.join(path, name)
            is_dir = os.path.isdir(full)
            if is_dir:
                size = ""
            else:
                try:
                    sz = os.path.getsize(full)
                    size = f"  {human_size(sz)}" if show_size else ""
                except OSError:
                    size = "  ?"
            print("  " * depth + f"├─ {name}/" if is_dir else f"├─ {name}{size}")
            if is_dir:
                rec(full, depth + 1)

    rec(root, 1)


def _match(name: str, pattern: str) -> bool:
    import fnmatch

    return fnmatch.fnmatch(name, pattern)


def main() -> None:
    ap = argparse.ArgumentParser(description="打印目录树（带大小）")
    ap.add_argument("root", help="要遍历的根目录")
    ap.add_argument("--max-depth", type=int, default=None, help="最大展开深度")
    ap.add_argument("--include", default=None, help="只显示匹配该 glob 的名称，如 '*.py'")
    ap.add_argument("--no-size", action="store_true", help="不显示文件大小")
    args = ap.parse_args()
    walk(args.root, args.max_depth, args.include, not args.no_size)


if __name__ == "__main__":
    main()
