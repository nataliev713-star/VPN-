"""Tests for log_analyzer.analyzer (TDD, written before implementation)."""

from __future__ import annotations

import textwrap
from pathlib import Path

import pytest

from log_analyzer.analyzer import LogStats, analyze_log


def make_csv(tmp_path: Path, rows: list[str], header: str = "timestamp,status_code,url") -> Path:
    content = "\n".join([header, *rows]) + "\n"
    file = tmp_path / "server.log.csv"
    file.write_text(content, encoding="utf-8")
    return file


class TestNormalWork:
    def test_counts_errors_and_success(self, tmp_path: Path) -> None:
        file = make_csv(
            tmp_path,
            [
                "2026-11-11T10:00:00,200,/home",
                "2026-11-11T10:00:01,500,/api",
                "2026-11-11T10:00:02,200,/api",
            ],
        )
        stats = analyze_log(file)
        assert stats.success_200 == 2
        assert stats.errors_500 == 1
        assert stats.total_requests == 3
        assert stats.malformed_rows == 0

    def test_most_popular_url(self, tmp_path: Path) -> None:
        file = make_csv(
            tmp_path,
            [
                "2026-11-11T10:00:00,200,/home",
                "2026-11-11T10:00:01,500,/api",
                "2026-11-11T10:00:02,200,/api",
                "2026-11-11T10:00:03,200,/other",
            ],
        )
        stats = analyze_log(file)
        assert stats.top_url == "/api"
        assert stats.top_url_count == 2

    def test_unknown_status_counts_in_total_only(self, tmp_path: Path) -> None:
        file = make_csv(tmp_path, ["2026-11-11T10:00:00,404,/home"])
        stats = analyze_log(file)
        assert stats.total_requests == 1
        assert stats.success_200 == 0
        assert stats.errors_500 == 0
        assert stats.top_url == "/home"


class TestEmptyFile:
    def test_empty_file_returns_zero_stats(self, tmp_path: Path) -> None:
        file = make_csv(tmp_path, [])
        stats = analyze_log(file)
        assert stats == LogStats(
            total_requests=0,
            errors_500=0,
            success_200=0,
            top_url=None,
            top_url_count=0,
            malformed_rows=0,
        )

    def test_header_only(self, tmp_path: Path) -> None:
        file = make_csv(tmp_path, [])
        stats = analyze_log(file)
        assert stats.total_requests == 0
        assert stats.top_url is None


class TestMalformedRows:
    def test_malformed_rows_are_counted_and_skipped(self, tmp_path: Path) -> None:
        file = make_csv(
            tmp_path,
            [
                "2026-11-11T10:00:00,200,/home",
                "not a valid row",
                "2026-11-11T10:00:02,abc,/bad-status",
                "short,row",
                "2026-11-11T10:00:03,500,/api",
            ],
        )
        stats = analyze_log(file)
        assert stats.malformed_rows == 3
        assert stats.total_requests == 2
        assert stats.success_200 == 1
        assert stats.errors_500 == 1
        assert stats.top_url is None or stats.top_url in ("/home", "/api")

    def test_quoted_url_with_comma(self, tmp_path: Path) -> None:
        file = make_csv(tmp_path, ['2026-11-11T10:00:00,200,"/search?q=a,b"'])
        stats = analyze_log(file)
        assert stats.malformed_rows == 0
        assert stats.total_requests == 1
        assert stats.top_url == "/search?q=a,b"

    def test_result_is_immutable(self, tmp_path: Path) -> None:
        file = make_csv(tmp_path, ["2026-11-11T10:00:00,200,/home"])
        stats = analyze_log(file)
        with pytest.raises(AttributeError):
            stats.errors_500 = 100  # type: ignore[misc]


class TestErrors:
    def test_missing_file_raises(self, tmp_path: Path) -> None:
        with pytest.raises(FileNotFoundError):
            analyze_log(tmp_path / "no_such_file.csv")
