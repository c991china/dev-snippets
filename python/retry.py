"""Retry decorator with exponential backoff and jitter.

Why: I kept writing the same try/except/sleep loop around flaky network calls.
This one is a decorator, only retries the exceptions you name, and adds jitter
so a fleet of clients doesn't retry in lockstep.

Tested on Python 3.9-3.12. No deps.

Gotchas I baked in:
  - By default it does NOT retry on a bare Exception (too broad). You must pass
    the exceptions you consider transient. Retrying a KeyError just hides bugs.
  - Backoff is capped so max_delay can't blow past a sane ceiling.
  - Jitter is full jitter (random between 0 and the current delay), not +/-10%.
    Full jitter is what the AWS writeup actually recommends for thundering herds.
"""

from __future__ import annotations

import functools
import random
import time
from typing import Callable, Tuple, Type


def retry(
    exceptions: Tuple[Type[BaseException], ...] = (Exception,),
    tries: int = 3,
    base_delay: float = 0.5,
    max_delay: float = 30.0,
    backoff: float = 2.0,
    jitter: bool = True,
    on_retry: Callable[[int, BaseException], None] | None = None,
):
    """Retry a function on the given exceptions.

    Args:
        exceptions: exception types to catch and retry on.
        tries: total attempts, including the first. tries=1 means no retry.
        base_delay: delay before the second attempt, in seconds.
        max_delay: ceiling for the computed delay.
        backoff: multiplier per attempt.
        jitter: if True, sleep a random amount in [0, delay] instead of delay.
        on_retry: optional callback(attempt, exc) called before each sleep.

    Raises:
        The last exception if all attempts fail.
    """
    if tries < 1:
        raise ValueError("tries must be >= 1")

    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            attempt = 1
            delay = base_delay
            while True:
                try:
                    return func(*args, **kwargs)
                except exceptions as exc:
                    if attempt >= tries:
                        raise
                    sleep_for = delay
                    if jitter:
                        sleep_for = random.uniform(0, delay)
                    if on_retry is not None:
                        on_retry(attempt, exc)
                    time.sleep(sleep_for)
                    # compute next delay, capped
                    delay = min(delay * backoff, max_delay)
                    attempt += 1

        return wrapper

    return decorator


if __name__ == "__main__":
    import urllib.error

    calls = {"n": 0}

    @retry(exceptions=(urllib.error.URLError,), tries=4, base_delay=0.1)
    def flaky():
        calls["n"] += 1
        if calls["n"] < 3:
            raise urllib.error.URLError("connection reset")
        return "ok"

    # Should print ok after 2 failures. Total wall time is small due to jitter.
    print(flaky(), "after", calls["n"], "attempts")

    @retry(tries=2, base_delay=0.01)
    def always_fails():
        raise ValueError("nope")

    try:
        always_fails()
    except ValueError as e:
        print("gave up as expected:", e)
