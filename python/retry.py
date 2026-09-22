"""带指数退避的重试装饰器。"""

from __future__ import annotations

import functools
import time


def retry(times: int = 3, delay: float = 1.0):
    def deco(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            last = None
            for i in range(times):
                try:
                    return func(*args, **kwargs)
                except Exception as e:  # noqa: BLE001
                    last = e
                    if i < times - 1:
                        time.sleep(delay * (2 ** i))
            raise last
        return wrapper
    return deco


@retry(times=3)
def unstable():
    raise ValueError("boom")
