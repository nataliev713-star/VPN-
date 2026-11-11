import SwiftUI

struct ConfigView: View {
    @EnvironmentObject private var vpnManager: VPNManager
    @State private var remoteUrlInput = ""
    @State private var isImportingRemote = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                List {
                    // Верхнее меню действий (как на скриншоте 4)
                    Section {
                        configActionRow(icon: "arrow.uturn.backward", title: "Restore Default Config")
                        configActionRow(icon: "icloud.and.arrow.down", title: "Import From Cloud...")
                        configActionRow(icon: "wifi", title: "Wi-Fi Upload")
                        configActionRow(icon: "chevron.left.forwardslash.chevron.right", title: "Modules")
                        configActionRow(icon: "flask", title: "Test Rule")
                    }
                    .listRowBackground(Theme.cardBackground)
                    
                    // Локальные файлы конфигураций
                    Section("LOCAL FILES") {
                        localConfigFileRow(name: "vpn.conf", date: "2026-11-10 05:10:28", size: "20.5K", isDefault: true)
                        localConfigFileRow(name: "vpn-copy.conf", date: "2026-11-10 05:10:28", size: "20.5K", isDefault: false)
                        localConfigFileRow(name: "default.conf", date: "2026-11-10 05:09:56", size: "90.1K", isDefault: false)
                    }
                    .listRowBackground(Theme.cardBackground)
                    
                    // Удаленные подписки (Remote Files)
                    Section("REMOTE FILES") {
                        if vpnManager.subscriptions.isEmpty {
                            Text("No remote subscription files")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.textMuted)
                        } else {
                            ForEach(vpnManager.subscriptions) { sub in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(sub.name)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(Theme.textPrimary)
                                    Text(sub.url)
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.textMuted)
                                        .lineLimit(1)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listRowBackground(Theme.cardBackground)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Config Files")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image(systemName: "qrcode.viewfinder")
                        .foregroundColor(Theme.rocketBlue)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { isImportingRemote = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Theme.rocketBlue)
                    }
                }
            }
            .alert("Add Remote Subscription", isPresented: $isImportingRemote) {
                TextField("https://...", text: $remoteUrlInput)
                Button("Add") {
                    guard !remoteUrlInput.isEmpty else { return }
                    Task {
                        if let nodes = try? await SubscriptionParser.shared.fetchSubscription(from: remoteUrlInput) {
                            let newSub = SubscriptionGroup(name: "Subscription \(vpnManager.subscriptions.count + 1)", url: remoteUrlInput, nodes: nodes)
                            vpnManager.subscriptions.append(newSub)
                            vpnManager.saveState()
                            remoteUrlInput = ""
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
    
    private func configActionRow(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Theme.rocketBlue)
                .frame(width: 24)
            Text(title)
                .foregroundColor(Theme.textPrimary)
                .font(.system(size: 15))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textMuted)
        }
    }
    
    private func localConfigFileRow(name: String, date: String, size: String, isDefault: Bool) -> some View {
        HStack {
            if isDefault {
                Circle()
                    .fill(Theme.accentOrange)
                    .frame(width: 8, height: 8)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                Text("\(date) - \(size)")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textMuted)
            }
            Spacer()
            Image(systemName: "info.circle")
                .foregroundColor(Theme.rocketBlue)
        }
    }
}
