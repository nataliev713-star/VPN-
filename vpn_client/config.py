import os
import uuid
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
BIN_DIR = BASE_DIR / "bin"
XRAY_EXE = BIN_DIR / "xray.exe"
CONFIG_FILE = BASE_DIR / "active_config.json"
SERVERS_CACHE = BASE_DIR / "servers.json"
HWID_FILE = BASE_DIR / ".hwid"

SUBSCRIPTION_URL = "https://keys.pink-service.ru/MYgedW1mjLzX6PYb"

SOCKS_PORT = 20808
HTTP_PORT = 20809

def get_or_create_hwid() -> str:
    """Возвращает сохраненный или генерирует уникальный аппаратный идентификатор (HWID)."""
    if HWID_FILE.exists():
        hwid = HWID_FILE.read_text(encoding="utf-8").strip()
        if hwid:
            return hwid
    new_hwid = str(uuid.uuid4())
    HWID_FILE.write_text(new_hwid, encoding="utf-8")
    return new_hwid
