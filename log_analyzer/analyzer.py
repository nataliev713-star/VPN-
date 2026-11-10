"""Statistics for server CSV logs (columns: timestamp, status_code, url)."""

from __future__ import annotations

import csv
from collections import Counter
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class LogStats:
    """Aggregate statistics for one log file."""

    total_requests: int
    errors_500: int
    success_200: int
    top_url: str | None
    top_url_count: int
    malformed_rows: int


def _is_valid_status(raw: str) -> bool:
    """A status code must be exactly three digits."""
    return len(raw) == 3 and raw.isdigit()


def analyze_log(path: str | Path) -> LogStats:
    """Analyze a CSV log file and return aggregate statistics.

    Rows that do not have exactly ``timestamp, status_code, url`` columns or
    a three-digit status code are skipped and counted as malformed.

    Raises:
        FileNotFoundError: if ``path`` does not exist.
    """
    total_requests = 0
    errors_500 = 0
    success_200 = 0
    malformed_rows = 0
    url_counts: Counter[str] = Counter()

    with Path(path).open(encoding="utf-8-sig", newline="") as file:
        for row in csv.DictReader(file):
            status = (row.get("status_code") or "").strip()
            url = (row.get("url") or "").strip()
            if not _is_valid_status(status) or not url:
                malformed_rows += 1
                continue

            total_requests += 1
            url_counts[url] += 1
            if status == "500":
                errors_500 += 1
            elif status == "200":
                success_200 += 1

    top_url, top_url_count = url_counts.most_common(1)[0] if url_counts else (None, 0)

    return LogStats(
        total_requests=total_requests,
        errors_500=errors_500,
        success_200=success_200,
        top_url=top_url,
        top_url_count=top_url_count,
        malformed_rows=malformed_rows,
    )
