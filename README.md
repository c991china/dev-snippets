# dev-snippets

Small, tested code and shell snippets I copy between projects. No framework, no
install, no dependencies beyond the standard library (Python 3.9+) and bash.

I got tired of re-writing the same retry loop and the same "find big files"
one-liner every few months. So they live here now, with the edge cases already
baked in.

## Index

### Python (`python/`)
| File | What it does |
|------|--------------|
| [retry.py](python/retry.py) | decorator: retry with exponential backoff + jitter, only on listed exceptions |
| [cache_decorator.py](python/cache_decorator.py) | `@memoize` with TTL and an LRU bound, keyed on args |
| [parallel_map.py](python/parallel_map.py) | bounded thread-pool map that keeps input order |

### Shell (`shell/`)
| File | What it does |
|------|--------------|
| [port_check.sh](shell/port_check.sh) | is a TCP port open locally/remotely, with a timeout |
| [backup_rotate.sh](shell/backup_rotate.sh) | tar a dir, keep the N newest, delete the rest |
| [find_large_files.sh](shell/find_large_files.sh) | top N largest files under a path |

### Git (`git/`)
| File | What it does |
|------|--------------|
| [aliases.sh](git/aliases.sh) | the git aliases I actually use, as a setup script |
| [clean-merged.sh](git/clean-merged.sh) | delete local branches already merged into main |

### SQL (`sql/`)
| File | What it does |
|------|--------------|
| [useful_queries.sql](sql/useful_queries.sql) | Postgres: sizes, locks, slow queries, indexes |

### Build
| File | What it does |
|------|--------------|
| [Makefile](Makefile) | `make check` runs the bash linter + py_compile; a few helpers |

## Usage

Python snippets are self-contained modules. Copy the file, or:

```bash
cp python/retry.py /your/project/
```

Shell scripts are standalone. `chmod +x` and run, or source them:

```bash
chmod +x shell/*.sh
./shell/find_large_files.sh /var 20
```

## Conventions

- Python: stdlib only. Type hints where they help, not everywhere.
- Shell: `#!/usr/bin/env bash` and `set -euo pipefail` on every script.
- Every snippet documents its own gotchas in a comment block at the top. I write
  those down because I've been burned by them.

## Caveats

- Bash scripts are tested on Linux and macOS. Some use GNU-only flags
  (`find -printf`, `stat -c`) that won't work on macOS/BSD without `gdate`,
  `gstat` from coreutils. I note this per-script.
- Nothing here is a library. There's no versioning promise. Copy it, own it.

## License

MIT. See LICENSE.
