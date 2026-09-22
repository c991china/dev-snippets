"""Memoize decorator with TTL and a bounded cache size.

Why: functools.lru_cache never expires entries and can't be bounded by time.
For anything backed by a network or a slow query, a stale cache is worse than
no cache. This gives you both a maxsize AND a TTL, plus a way to bust it.

Tested on Python 3.9-3.12. stdlib only.

Gotchas:
  - The cache key is built from args/kwargs. Unhashable args (lists, dicts)
    will raise TypeError. That's intentional: I'd rather fail loud than guess.
  - Only positional and keyword args are considered. If you call the function
    with the same logical args in different orders, you get different keys.
  - Not thread-safe in the strictest sense. dict operations are atomic under
    the GIL in CPython, so you won't corrupt it, but you can get a redundant
    compute if two threads miss at once. Fine for my use; not a distributed lock.
  - Expired entries are evicted lazily on access, plus a sweep when the cache
    grows past maxsize. It won't grow without bound.
"""

from __future__ import annotations

import functools
import time
from collections import OrderedDict
from typing import Callable


def memoize(ttl: float = 60.0, maxsize: int = 128):
    """Cache results of a function for `ttl` seconds, at most `maxsize` entries.

    Args:
        ttl: seconds an entry stays valid. Use None-ish large value for "forever".
        maxsize: max number of cached keys. LRU eviction past this.
    """
    if maxsize < 1:
        raise ValueError("maxsize must be >= 1")

    def decorator(func: Callable):
        cache: "OrderedDict[tuple, tuple[float, object]]" = OrderedDict()

        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            key = (args, tuple(sorted(kwargs.items())))
            now = time.monotonic()

            if key in cache:
                ts, value = cache[key]
                if now - ts < ttl:
                    cache.move_to_end(key)
                    return value
                # expired: drop it and recompute
                del cache[key]

            value = func(*args, **kwargs)
            cache[key] = (now, value)
            cache.move_to_end(key)

            while len(cache) > maxsize:
                cache.popitem(last=False)  # evict least-recently-used

            return value

        def cache_clear():
            cache.clear()

        def cache_info():
            return {"size": len(cache), "maxsize": maxsize, "ttl": ttl}

        wrapper.cache_clear = cache_clear  # type: ignore[attr-defined]
        wrapper.cache_info = cache_info    # type: ignore[attr-defined]
        return wrapper

    return decorator


if __name__ == "__main__":
    calls = {"n": 0}

    @memoize(ttl=0.3, maxsize=2)
    def slow_square(x):
        calls["n"] += 1
        time.sleep(0.05)
        return x * x

    print(slow_square(3), slow_square(3))       # computed once
    print("calls:", calls["n"])                 # 1
    time.sleep(0.35)
    print(slow_square(3))                       # recomputed after TTL
    print("calls:", calls["n"])                 # 2
    print("info:", slow_square.cache_info())
