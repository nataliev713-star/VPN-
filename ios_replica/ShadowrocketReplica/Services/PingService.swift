import Foundation
import Network

public enum PingMethod: String, CaseIterable, Codable {
    case realHttp204 = "HTTP 204 (Real Internet)"
    case tcpHandshake = "TCP Connect (Port Only)"
}

public final class PingService {
    public static let shared = PingService()
    
    // Cloudflare и Google 204 генераторы для проверки честной проходимости трафика
    private let httpCheckURLs = [
        URL(string: "http://cp.cloudflare.com/generate_204")!,
        URL(string: "http://www.google.com/generate_204")!
    ]
    
    private init() {}
    
    /// Честный пинг через выполнение сетевого запроса и замер времени полного ответа
    public func measureLatency(for node: ProxyNode, method: PingMethod = .realHttp204) async -> Int? {
        switch method {
        case .realHttp204:
            return await measureRealHttpLatency(for: node)
        case .tcpHandshake:
            return await measureTcpLatency(host: node.host, port: node.port)
        }
    }
    
    private func measureRealHttpLatency(for node: ProxyNode) async -> Int? {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Формируем легковесный HEAD запрос
        var request = URLRequest(url: httpCheckURLs[0])
        request.httpMethod = "HEAD"
        request.timeoutInterval = 3.5
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...204).contains(httpResponse.statusCode) {
                let durationMs = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)
                return max(1, durationMs)
            }
        } catch {
            // Резервная попытка через Google endpoint
            do {
                var backupReq = URLRequest(url: httpCheckURLs[1])
                backupReq.httpMethod = "HEAD"
                backupReq.timeoutInterval = 3.5
                let (_, response) = try await URLSession.shared.data(for: backupReq)
                if let httpResponse = response as? HTTPURLResponse, (200...204).contains(httpResponse.statusCode) {
                    let durationMs = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)
                    return max(1, durationMs)
                }
            } catch {
                return nil
            }
        }
        return nil
    }
    
    private func measureTcpLatency(host: String, port: Int) async -> Int? {
        guard let nwPort = NWEndpoint.Port(rawValue: UInt16(port)) else { return nil }
        let endpoint = NWEndpoint.Host(host)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let parameters = NWParameters.tcp
        let connection = NWConnection(host: endpoint, port: nwPort, using: parameters)
        
        return await withCheckedContinuation { continuation in
            var hasResponded = false
            
            connection.stateUpdateHandler = { state in
                guard !hasResponded else { return }
                switch state {
                case .ready:
                    hasResponded = true
                    let durationMs = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)
                    connection.cancel()
                    continuation.resume(returning: max(1, durationMs))
                case .failed, .cancelled:
                    hasResponded = true
                    connection.cancel()
                    continuation.resume(returning: nil)
                default:
                    break
                }
            }
            
            let queue = DispatchQueue(label: "com.shadowrocket.ping")
            connection.start(queue: queue)
            
            queue.asyncAfter(deadline: .now() + 3.0) {
                if !hasResponded {
                    hasResponded = true
                    connection.cancel()
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
