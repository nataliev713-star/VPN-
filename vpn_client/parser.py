import json
import base64
import urllib.request
import urllib.parse
from dataclasses import dataclass, asdict
from typing import List, Optional
from config import SUBSCRIPTION_URL, SERVERS_CACHE, get_or_create_hwid

@dataclass
class VlessServer:
    id: int
    name: str
    uuid: str
    host: str
    port: int
    network: str
    security: str
    flow: str
    sni: str
    fingerprint: str
    public_key: str = ""
    short_id: str = ""
    service_name: str = ""
    raw_url: str = ""

def parse_vless_url(index: int, raw_url: str) -> Optional[VlessServer]:
    if not raw_url.startswith("vless://"):
        return None
    try:
        parsed = urllib.parse.urlparse(raw_url)
        uuid_val, host_port = parsed.netloc.split("@")
        if ":" in host_port:
            host, port_str = host_port.split(":")
            port = int(port_str)
        else:
            host = host_port
            port = 443

        qs = urllib.parse.parse_qs(parsed.query)
        network = qs.get("type", ["tcp"])[0]
        security = qs.get("security", ["none"])[0]
        flow = qs.get("flow", [""])[0]
        sni = qs.get("sni", [""])[0]
        fingerprint = qs.get("fp", ["chrome"])[0]
        public_key = qs.get("pbk", [""])[0]
        short_id = qs.get("sid", [""])[0]
        service_name = qs.get("serviceName", [""])[0]

        name = urllib.parse.unquote(parsed.fragment).strip() if parsed.fragment else f"Server {index}"

        return VlessServer(
            id=index,
            name=name,
            uuid=uuid_val,
            host=host,
            port=port,
            network=network,
            security=security,
            flow=flow,
            sni=sni,
            fingerprint=fingerprint,
            public_key=public_key,
            short_id=short_id,
            service_name=service_name,
            raw_url=raw_url
        )
    except Exception:
        return None

def fetch_servers(force_refresh: bool = False) -> List[VlessServer]:
    if not force_refresh and SERVERS_CACHE.exists():
        try:
            with open(SERVERS_CACHE, "r", encoding="utf-8") as f:
                data = json.load(f)
                return [VlessServer(**s) for s in data]
        except Exception:
            pass

    hwid = get_or_create_hwid()
    req = urllib.request.Request(
        SUBSCRIPTION_URL,
        headers={
            "User-Agent": "v2rayN/6.23",
            "X-HWID": hwid
        }
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        content = resp.read().strip()

    decoded = base64.b64decode(content).decode("utf-8", errors="ignore")
    lines = [l.strip() for l in decoded.splitlines() if l.strip().startswith("vless://")]

    servers: List[VlessServer] = []
    idx = 1
    for line in lines:
        server = parse_vless_url(idx, line)
        if server and server.uuid != "00000000-0000-0000-0000-000000000000":
            servers.append(server)
            idx += 1

    with open(SERVERS_CACHE, "w", encoding="utf-8") as f:
        json.dump([asdict(s) for s in servers], f, ensure_ascii=False, indent=2)

    return servers
