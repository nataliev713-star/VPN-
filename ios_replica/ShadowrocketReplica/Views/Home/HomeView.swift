import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var vpnManager: VPNManager
    @State private var showAddServer = false
    @State private var showRoutingPicker = false
    @State private var selectedNodeForInfo: ProxyNode?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // 1. Главная карточка подключения (Rocket Card)
                        connectionCard
                        
                        // 2. Секция управления маршрутизацией и тестом пинга
                        controlCard
                        
                        // 3. Быстрая кнопка добавления
                        addServerButton
                        
                        // 4. Пояснение (как в Shadowrocket)
                        Text("Tap the subscription to fold and unfold servers.\nThe DOT means the default server.")
                            .font(.system(size: 12))
                            .multilineTextAlignment(.center)
                            .foregroundColor(Theme.textMuted)
                            .padding(.vertical, 4)
                        
                        // 5. Список серверов (Подписки и прямые узлы)
                        serverListSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Shadowrocket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { /* QR Scanner */ }) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 19))
                            .foregroundColor(Theme.rocketBlue)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddServer = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundColor(Theme.rocketBlue)
                    }
                }
            }
            .sheet(isPresented: $showAddServer) {
                AddServerSheet()
            }
            .confirmationDialog("Global Routing", isPresented: $showRoutingPicker) {
                ForEach(RoutingMode.allCases, id: \.self) { mode in
                    Button(mode.rawValue) {
                        vpnManager.routingMode = mode
                    }
                }
                Button("Отмена", role: .cancel) {}
            }
        }
    }
    
    // MARK: - Subviews
    
    private var connectionCard: some View {
        HStack(spacing: 16) {
            RocketIconView(size: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(vpnManager.connectionStatusText)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                
                if let active = vpnManager.activeNode {
                    Text(active.name)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.rocketBlue)
                        .lineLimit(1)
                } else {
                    Text("No Server Selected")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textMuted)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { vpnManager.isConnected },
                set: { _ in vpnManager.toggleConnection() }
            ))
            .labelsHidden()
            .tint(Theme.accentGreen)
        }
        .padding(16)
        .background(Theme.cardBackground)
        .cornerRadius(12)
    }
    
    private var controlCard: some View {
        VStack(spacing: 0) {
            // Global Routing
            Button(action: { showRoutingPicker = true }) {
                HStack {
                    Image(systemName: "network")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.rocketBlue)
                    
                    Text("Global Routing")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.textPrimary)
                    
                    Spacer()
                    
                    Text(vpnManager.routingMode.rawValue.components(separatedBy: " ").first ?? "Proxy")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.textMuted)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textMuted)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            
            Divider()
                .background(Theme.divider)
                .padding(.leading, 48)
            
            // Connectivity Test
            Button(action: {
                Task {
                    await vpnManager.testAllNodes()
                }
            }) {
                HStack {
                    Image(systemName: "speedometer")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.rocketBlue)
                    
                    Text("Connectivity Test")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.textPrimary)
                    
                    Spacer()
                    
                    if vpnManager.isTestingAll {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
        .background(Theme.cardBackground)
        .cornerRadius(12)
    }
    
    private var addServerButton: some View {
        Button(action: { showAddServer = true }) {
            HStack {
                Text("Add Server")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Theme.cardBackground)
            .cornerRadius(12)
        }
    }
    
    private var serverListSection: some View {
        VStack(spacing: 12) {
            // Подписки
            ForEach($vpnManager.subscriptions) { $sub in
                VStack(spacing: 8) {
                    // Заголовок подписки
                    Button(action: { sub.isFolded.toggle() }) {
                        HStack {
                            Image(systemName: sub.isFolded ? "folder" : "folder.fill")
                                .foregroundColor(Theme.rocketBlue)
                            Text(sub.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                            Text("\(sub.nodes.count)")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.textMuted)
                            Image(systemName: sub.isFolded ? "chevron.right" : "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textMuted)
                        }
                        .padding(.vertical, 6)
                    }
                    
                    if !sub.isFolded {
                        ForEach(sub.nodes) { node in
                            ServerRowView(
                                node: node,
                                isSelected: vpnManager.activeNode?.id == node.id,
                                onSelect: {
                                    vpnManager.activeNode = node
                                    vpnManager.saveState()
                                },
                                onInfo: {
                                    selectedNodeForInfo = node
                                }
                            )
                        }
                    }
                }
                .padding(.bottom, 6)
            }
            
            // Прямые узлы
            ForEach(vpnManager.directNodes) { node in
                ServerRowView(
                    node: node,
                    isSelected: vpnManager.activeNode?.id == node.id,
                    onSelect: {
                        vpnManager.activeNode = node
                        vpnManager.saveState()
                    },
                    onInfo: {
                        selectedNodeForInfo = node
                    }
                )
            }
        }
    }
}
