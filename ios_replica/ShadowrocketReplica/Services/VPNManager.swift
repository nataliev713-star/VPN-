import Foundation
import NetworkExtension
import Combine

public enum RoutingMode: String, CaseIterable, Codable {
    case smart = "Smart (Auto Bypass)"
    case config = "Config (Rule Based)"
    case proxy = "Proxy (Global All)"
    case direct = "Direct (Bypass All)"
}

@MainActor
public final class VPNManager: ObservableObject {
    public static let shared = VPNManager()
    
    public static let appGroupIdentifier = "group.com.shadowrocket.replica"
    private let vpnBundleId = "com.shadowrocket.replica.PacketTunnel"
    
    @Published public var isConnected: Bool = false
    @Published public var connectionStatusText: String = "Not Connected"
    @Published public var routingMode: RoutingMode = .smart
    @Published public var activeNode: ProxyNode?
    @Published public var subscriptions: [SubscriptionGroup] = []
    @Published public var directNodes: [ProxyNode] = []
    
    @Published public var isTestingAll: Bool = false
    @Published public var pingMethod: PingMethod = .realHttp204
    
    private var vpnManager: NETunnelProviderManager?
    private var statusObserver: AnyCancellable?
    
    private init() {
        loadSavedData()
        setupVPNManager()
    }
    
    // MARK: - Persistence
    
    private var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: Self.appGroupIdentifier) ?? UserDefaults.standard
    }
    
    private func loadSavedData() {
        if let data = sharedDefaults.data(forKey: "saved_subscriptions"),
           let decoded = try? JSONDecoder().decode([SubscriptionGroup].self, from: data) {
            self.subscriptions = decoded
        }
        
        if let data = sharedDefaults.data(forKey: "saved_direct_nodes"),
           let decoded = try? JSONDecoder().decode([ProxyNode].self, from: data) {
            self.directNodes = decoded
        }
        
        if let data = sharedDefaults.data(forKey: "saved_active_node"),
           let decoded = try? JSONDecoder().decode(ProxyNode.self, from: data) {
            self.activeNode = decoded
        }
    }
    
    public func saveState() {
        if let data = try? JSONEncoder().encode(subscriptions) {
            sharedDefaults.set(data, forKey: "saved_subscriptions")
        }
        if let data = try? JSONEncoder().encode(directNodes) {
            sharedDefaults.set(data, forKey: "saved_direct_nodes")
        }
        if let active = activeNode, let data = try? JSONEncoder().encode(active) {
            sharedDefaults.set(data, forKey: "saved_active_node")
        }
    }
    
    // MARK: - VPN Setup
    
    private func setupVPNManager() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            guard let self = self else { return }
            if let existingManager = managers?.first {
                self.vpnManager = existingManager
            } else {
                let newManager = NETunnelProviderManager()
                let config = NETunnelProviderProtocol()
                config.providerBundleIdentifier = self.vpnBundleId
                config.serverAddress = "Shadowrocket Core"
                newManager.protocolConfiguration = config
                newManager.localizedDescription = "Shadowrocket Replica"
                newManager.isEnabled = true
                self.vpnManager = newManager
            }
            self.observeVPNStatus()
        }
    }
    
    private func observeVPNStatus() {
        NotificationCenter.default.publisher(for: .NEVPNStatusDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatus()
            }
            .store(in: &cancellables)
        
        updateStatus()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func updateStatus() {
        guard let manager = vpnManager else { return }
        switch manager.connection.status {
        case .connected:
            self.isConnected = true
            self.connectionStatusText = "Connected"
        case .connecting:
            self.isConnected = false
            self.connectionStatusText = "Connecting..."
        case .disconnecting:
            self.isConnected = false
            self.connectionStatusText = "Disconnecting..."
        default:
            self.isConnected = false
            self.connectionStatusText = "Not Connected"
        }
    }
    
    // MARK: - Actions
    
    public func toggleConnection() {
        guard let manager = vpnManager else { return }
        
        if isConnected {
            manager.connection.stopVPNTunnel()
        } else {
            guard let active = activeNode else {
                self.connectionStatusText = "Select a Server First"
                return
            }
            
            // Сохраняем активный сервер в sharedDefaults для PacketTunnelProvider
            saveState()
            
            var options: [String: NSObject] = [:]
            options["active_node_host"] = active.host as NSString
            options["active_node_port"] = NSNumber(value: active.port)
            options["active_node_uuid"] = active.uuidOrPassword as NSString
            options["routing_mode"] = routingMode.rawValue as NSString
            
            manager.saveToPreferences { [weak self] error in
                guard error == nil else {
                    self?.connectionStatusText = "Save Config Error"
                    return
                }
                manager.loadFromPreferences { _ in
                    do {
                        try manager.connection.startVPNTunnel(options: options)
                    } catch {
                        self?.connectionStatusText = "Start Error: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    public func testAllNodes() async {
        guard !isTestingAll else { return }
        isTestingAll = true
        
        // Тестируем серверы из подписок
        for subIndex in subscriptions.indices {
            for nodeIndex in subscriptions[subIndex].nodes.indices {
                subscriptions[subIndex].nodes[nodeIndex].isTesting = true
                let latency = await PingService.shared.measureLatency(
                    for: subscriptions[subIndex].nodes[nodeIndex],
                    method: pingMethod
                )
                subscriptions[subIndex].nodes[nodeIndex].pingMs = latency
                subscriptions[subIndex].nodes[nodeIndex].isTesting = false
            }
        }
        
        // Тестируем одиночные серверы
        for i in directNodes.indices {
            directNodes[i].isTesting = true
            let latency = await PingService.shared.measureLatency(for: directNodes[i], method: pingMethod)
            directNodes[i].pingMs = latency
            directNodes[i].isTesting = false
        }
        
        isTestingAll = false
        saveState()
    }
}
