# dev-snippets

随手收集的几个实用小脚本，覆盖日常开发与运维里的零碎需求。
全部为原创、零依赖（仅用系统自带工具 / 标准库）。

## 脚本清单

| 脚本 | 语言 | 功能 |
|------|------|------|
| `file_tree.py` | Python | 打印目录树，显示每个条目大小与层级，可过滤 |
| `backup_snapshot.sh` | Bash | 对目录做带时间戳的增量快照备份（基于 rsync/robocopy） |

## 用法速查

```bash
# 目录树（限制深度 2 层，只显示 .py 文件）
python file_tree.py ./myproject --max-depth 2 --include "*.py"

# 做一次快照备份
bash backup_snapshot.sh /path/to/source /path/to/backups
```

每个脚本头部都有更详细的参数说明，直接 `python file_tree.py -h` 或读源码即可。
