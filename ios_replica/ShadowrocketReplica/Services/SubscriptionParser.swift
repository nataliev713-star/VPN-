import Foundation

public final class SubscriptionParser {
    public static let shared = SubscriptionParser()
    private init() {}
    
    /// Загрузка и парсинг удаленной подписки по URL
    public func fetchSubscription(from urlString: String) async throws -> [ProxyNode] {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        // Точный User-Agent оригинального Shadowrocket для обхода проверки провайдеров (PandaVPN и др.)
        request.setValue("Shadowrocket/2.2.63 (iPhone; iOS 18.0; Scale/3.00)", forHTTPHeaderField: "User-Agent")
        request.setValue("v2rayN/6.23", forHTTPHeaderField: "X-Client-Agent")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-HWID")
        request.timeoutInterval = 12.0
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        guard let rawText = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        return parseSubscriptionContent(rawText)
    }
    
    /// Парсер текстового контента (Base64 или построчные ссылки)
    public func parseSubscriptionContent(_ content: String) -> [ProxyNode] {
        var textToParse = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Попытка декодировать Base64
        if let base64Data = Data(base64Encoded: textToParse, options: [.ignoreUnknownCharacters]),
           let decoded = String(data: base64Data, encoding: .utf8) {
            textToParse = decoded
        }
        
        let lines = textToParse.components(separatedBy: .newlines)
        var parsedNodes: [ProxyNode] = []
        
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            
            if let node = parseNodeURL(trimmed, defaultIndex: index + 1) {
                // Игнорируем заглушки с хостом 0.0.0.0 или сообщениями об ошибках
                if node.host != "0.0.0.0" && !node.name.lowercased().contains("не поддерживается") {
                    parsedNodes.append(node)
                }
            }
        }
        
        return parsedNodes
    }
    
    /// Парсер одиночной URI ссылки узла
    public func parseNodeURL(_ urlString: String, defaultIndex: Int) -> ProxyNode? {
        if urlString.hasPrefix("vless://") {
            return parseVless(urlString, defaultIndex: defaultIndex)
        } else if urlString.hasPrefix("ss://") {
            return parseShadowsocks(urlString, defaultIndex: defaultIndex)
        } else if urlString.hasPrefix("trojan://") {
            return parseTrojan(urlString, defaultIndex: defaultIndex)
        }
        return nil
    }
    
    private func parseVless(_ urlString: String, defaultIndex: Int) -> ProxyNode? {
        guard let url = URL(string: urlString) else { return nil }
        guard let uuid = url.user, let host = url.host, let port = url.port else { return nil }
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []
        
        func param(_ name: String) -> String {
            queryItems.first(where: { $0.name.lowercased() == name.lowercased() })?.value ?? ""
        }
        
        let name = url.fragment?.removingPercentEncoding ?? "VLESS Node \(defaultIndex)"
        let security = param("security")
        let sni = param("sni")
        let flow = param("flow")
        let fp = param("fp")
        let pbk = param("pbk")
        let sid = param("sid")
        let path = param("path")
        
        return ProxyNode(
            name: name,
            protocolType: .vless,
            host: host,
            port: port,
            uuidOrPassword: uuid,
            security: security.isEmpty ? "none" : security,
            sni: sni,
            flow: flow,
            fingerprint: fp.isEmpty ? "chrome" : fp,
            publicKey: pbk,
            shortId: sid,
            path: path
        )
    }
    
    private func parseShadowsocks(_ urlString: String, defaultIndex: Int) -> ProxyNode? {
        let clean = urlString.replacingOccurrences(of: "ss://", with: "")
        let parts = clean.components(separatedBy: "#")
        let connectionPart = parts[0]
        let name = parts.count > 1 ? (parts[1].removingPercentEncoding ?? "SS Node \(defaultIndex)") : "SS Node \(defaultIndex)"
        
        if connectionPart.contains("@") {
            let atParts = connectionPart.components(separatedBy: "@")
            let userInfo = atParts[0]
            let hostPort = atParts[1].components(separatedBy: ":")
            if hostPort.count == 2, let port = Int(hostPort[1]) {
                return ProxyNode(
                    name: name,
                    protocolType: .shadowsocks,
                    host: hostPort[0],
                    port: port,
                    uuidOrPassword: userInfo
                )
            }
        }
        return nil
    }
    
    private func parseTrojan(_ urlString: String, defaultIndex: Int) -> ProxyNode? {
        guard let url = URL(string: urlString) else { return nil }
        guard let password = url.user, let host = url.host, let port = url.port else { return nil }
        let name = url.fragment?.removingPercentEncoding ?? "Trojan Node \(defaultIndex)"
        
        return ProxyNode(
            name: name,
            protocolType: .trojan,
            host: host,
            port: port,
            uuidOrPassword: password,
            security: "tls",
            sni: host
        )
    }
}
