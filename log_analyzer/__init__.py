"""Log analyzer: statistics for server CSV logs (timestamp, status_code, url)."""

from log_analyzer.analyzer import LogStats, analyze_log

__all__ = ["LogStats", "analyze_log"]
