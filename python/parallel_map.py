"""parallel_map: bounded thread pool map that preserves input order.

Why: concurrent.futures.ThreadPoolExecutor.map is fine, but it returns a lazy
iterator and exceptions surface at iteration time, which is awkward. This
returns a plain list, keeps the order of the input, and lets you choose whether
one failure aborts everything or comes back as an exception object.

Threads (not processes) because the stuff I parallelize is I/O-bound: HTTP,
disk, DB. For CPU-bound work use ProcessPoolExecutor; threads won't help.

Tested on Python 3.9-3.12. stdlib only.

Gotchas:
  - If fail_fast=True, the FIRST exception is raised and in-flight tasks are
    still allowed to finish (we don't try to kill running threads; you can't
    safely). We just stop submitting new work.
  - Order is preserved: results[i] corresponds to items[i], regardless of
    completion order.
"""

from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Callable, Iterable, List


def parallel_map(
    func: Callable,
    items: Iterable,
    workers: int = 8,
    fail_fast: bool = True,
):
    """Run func(item) for each item using up to `workers` threads.

    Args:
        func: callable taking one item.
        items: any iterable of work items.
        workers: max concurrent threads.
        fail_fast: if True, raise the first exception; else return the exception
                   object in place of that item's result.

    Returns:
        list of results in the same order as `items`.
    """
    items = list(items)
    if workers < 1:
        raise ValueError("workers must be >= 1")

    results: List[object] = [None] * len(items)
    first_error: BaseException | None = None

    with ThreadPoolExecutor(max_workers=workers) as pool:
        future_to_idx = {
            pool.submit(func, item): idx for idx, item in enumerate(items)
        }
        for fut in as_completed(future_to_idx):
            idx = future_to_idx[fut]
            try:
                results[idx] = fut.result()
            except BaseException as exc:  # noqa: BLE001 - we re-raise below
                if fail_fast:
                    first_error = first_error or exc
                    # cancel anything not yet started
                    for other in future_to_idx:
                        other.cancel()
                else:
                    results[idx] = exc

    if first_error is not None:
        raise first_error
    return results


if __name__ == "__main__":
    import time

    def fetch(n):
        time.sleep(0.1)  # pretend network
        return n * 2

    start = time.monotonic()
    out = parallel_map(fetch, range(10), workers=5)
    print(out)  # [0, 2, 4, ..., 18] in order
    print("elapsed %.2fs" % (time.monotonic() - start))  # ~0.2s, not 1.0s

    def boom(n):
        if n == 3:
            raise RuntimeError("failed on 3")
        return n

    # collect errors instead of raising
    mixed = parallel_map(boom, range(5), workers=2, fail_fast=False)
    print([type(x).__name__ if isinstance(x, Exception) else x for x in mixed])
