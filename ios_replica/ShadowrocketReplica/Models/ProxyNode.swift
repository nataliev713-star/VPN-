import Foundation

public enum ProxyProtocol: String, Codable, CaseIterable {
    case vless = "vless"
    case vmess = "vmess"
    case shadowsocks = "ss"
    case trojan = "trojan"
    case socks5 = "socks5"
    case http = "http"
    
    public var displayName: String {
        switch self {
        case .vless: return "VLESS"
        case .vmess: return "VMess"
        case .shadowsocks: return "Shadowsocks"
        case .trojan: return "Trojan"
        case .socks5: return "SOCKS5"
        case .http: return "HTTP"
        }
    }
}

public struct ProxyNode: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var protocolType: ProxyProtocol
    public var host: String
    public var port: Int
    public var uuidOrPassword: String
    
    // Дополнительные параметры TLS / Reality / WS
    public var security: String
    public var sni: String
    public var flow: String
    public var fingerprint: String
    public var publicKey: String
    public var shortId: String
    public var path: String
    
    // Метрики
    public var pingMs: Int?
    public var isTesting: Bool = false
    public var lastTested: Date?
    
    public init(
        id: UUID = UUID(),
        name: String,
        protocolType: ProxyProtocol,
        host: String,
        port: Int,
        uuidOrPassword: String,
        security: String = "tls",
        sni: String = "",
        flow: String = "",
        fingerprint: String = "chrome",
        publicKey: String = "",
        shortId: String = "",
        path: String = "",
        pingMs: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.protocolType = protocolType
        self.host = host
        self.port = port
        self.uuidOrPassword = uuidOrPassword
        self.security = security
        self.sni = sni.isEmpty ? host : sni
        self.flow = flow
        self.fingerprint = fingerprint
        self.publicKey = publicKey
        self.shortId = shortId
        self.path = path
        self.pingMs = pingMs
    }
}

public struct SubscriptionGroup: Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var url: String
    public var nodes: [ProxyNode]
    public var lastUpdated: Date?
    public var isFolded: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        url: String,
        nodes: [ProxyNode] = [],
        lastUpdated: Date? = nil,
        isFolded: Bool = false
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.nodes = nodes
        self.lastUpdated = lastUpdated
        self.isFolded = isFolded
    }
}
