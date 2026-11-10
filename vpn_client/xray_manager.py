import os
import json
import time
import atexit
import socket
import urllib.request
import subprocess
from typing import Optional, Dict, Any, Tuple
from config import XRAY_EXE, CONFIG_FILE, SOCKS_PORT, HTTP_PORT, BIN_DIR
from parser import VlessServer
from system_proxy import disable_system_proxy

class XrayManager:
    def __init__(self):
        self.process: Optional[subprocess.Popen] = None
        self.current_server: Optional[VlessServer] = None
        atexit.register(self.stop)

    def is_binary_ready(self) -> bool:
        return XRAY_EXE.exists() and os.access(XRAY_EXE, os.X_OK)

    def generate_config(self, server: VlessServer) -> Dict[str, Any]:
        outbound: Dict[str, Any] = {
            "tag": "proxy",
            "protocol": "vless",
            "settings": {
                "vnext": [
                    {
                        "address": server.host,
                        "port": server.port,
                        "users": [
                            {
                                "id": server.uuid,
                                "encryption": "none"
                            }
                        ]
                    }
                ]
            },
            "streamSettings": {
                "network": server.network
            }
        }

        if server.flow:
            outbound["settings"]["vnext"][0]["users"][0]["flow"] = server.flow

        stream = outbound["streamSettings"]
        if server.security == "reality":
            stream["security"] = "reality"
            stream["realitySettings"] = {
                "serverName": server.sni,
                "fingerprint": server.fingerprint or "chrome",
                "show": False,
                "publicKey": server.public_key,
                "shortId": server.short_id,
                "spiderX": ""
            }
        elif server.security == "tls":
            stream["security"] = "tls"
            stream["tlsSettings"] = {
                "serverName": server.sni,
                "fingerprint": server.fingerprint or "chrome",
                "alpn": ["h2", "http/1.1"]
            }

        if server.network == "grpc":
            stream["grpcSettings"] = {
                "serviceName": server.service_name or "gun",
                "multiMode": False
            }

        config = {
            "log": {
                "loglevel": "warning"
            },
            "inbounds": [
                {
                    "tag": "socks-in",
                    "port": SOCKS_PORT,
                    "listen": "127.0.0.1",
                    "protocol": "socks",
                    "settings": {
                        "auth": "noauth",
                        "udp": True
                    }
                },
                {
                    "tag": "http-in",
                    "port": HTTP_PORT,
                    "listen": "127.0.0.1",
                    "protocol": "http"
                }
            ],
            "outbounds": [
                outbound,
                {
                    "tag": "direct",
                    "protocol": "freedom"
                }
            ],
            "routing": {
                "domainStrategy": "IPIfNonMatch",
                "rules": [
                    {
                        "type": "field",
                        "ip": ["geoip:private"],
                        "outboundTag": "direct"
                    }
                ]
            }
        }
        return config

    def start(self, server: VlessServer) -> Tuple[bool, str]:
        if not self.is_binary_ready():
            return False, f"Файл Xray не найден: {XRAY_EXE}"

        self.stop()

        cfg = self.generate_config(server)
        with open(CONFIG_FILE, "w", encoding="utf-8") as f:
            json.dump(cfg, f, ensure_ascii=False, indent=2)

        test_res = subprocess.run(
            [str(XRAY_EXE), "-test", "-config", str(CONFIG_FILE)],
            capture_output=True,
            text=True
        )
        if test_res.returncode != 0:
            return False, f"Ошибка конфигурации Xray: {test_res.stderr or test_res.stdout}"

        try:
            self.process = subprocess.Popen(
                [str(XRAY_EXE), "-config", str(CONFIG_FILE)],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
            )
            time.sleep(1.0)
            if self.process.poll() is not None:
                return False, "Процесс Xray аварийно завершился сразу после запуска."

            self.current_server = server
            return True, f"Подключено к: {server.name}"
        except Exception as e:
            return False, str(e)

    def stop(self) -> bool:
        disable_system_proxy()
        if self.process:
            try:
                self.process.terminate()
                self.process.wait(timeout=2)
            except Exception:
                try:
                    self.process.kill()
                except Exception:
                    pass
            self.process = None
            self.current_server = None
            return True
        return False

    def is_running(self) -> bool:
        return self.process is not None and self.process.poll() is None

    def check_ip_info(self) -> Dict[str, Any]:
        if not self.is_running():
            return {"error": "VPN не запущен"}
        try:
            proxy_handler = urllib.request.ProxyHandler({
                "http": f"http://127.0.0.1:{HTTP_PORT}",
                "https": f"http://127.0.0.1:{HTTP_PORT}"
            })
            opener = urllib.request.build_opener(proxy_handler)
            req = urllib.request.Request("https://ipinfo.io/json", headers={"User-Agent": "curl/8.0.0"})
            with opener.open(req, timeout=6) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except Exception as e:
            return {"error": str(e)}

    @staticmethod
    def test_tcp_ping(host: str, port: int, timeout: float = 2.5) -> Optional[int]:
        t0 = time.time()
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(timeout)
            sock.connect((host, port))
            sock.close()
            return int((time.time() - t0) * 1000)
        except Exception:
            return None
