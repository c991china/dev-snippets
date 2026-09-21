#!/usr/bin/env python3
"""打印目录树。用法：python file_tree.py <目录> [最大深度]"""
import os
import sys


def tree(root, max_depth=3, prefix=""):
    if max_depth <= 0:
        return
    try:
        entries = sorted(os.listdir(root))
    except PermissionError:
        return
    for i, name in enumerate(entries):
        last = i == len(entries) - 1
        conn = "└── " if last else "├── "
        full = os.path.join(root, name)
        print(f"{prefix}{conn}{name}")
        if os.path.isdir(full):
            tree(full, max_depth - 1, prefix + ("    " if last else "│   "))


if __name__ == "__main__":
    root = sys.argv[1] if len(sys.argv) > 1 else "."
    depth = int(sys.argv[2]) if len(sys.argv) > 2 else 3
    tree(root, depth)
