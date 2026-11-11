import SwiftUI

struct DataView: View {
    @EnvironmentObject private var vpnManager: VPNManager
    @State private var overwriteServer = true
    @State private var autoDeleteLogs = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                List {
                    // iCloud
                    Section {
                        HStack {
                            Image(systemName: "icloud")
                                .foregroundColor(Theme.rocketBlue)
                                .frame(width: 24)
                            Text("iCloud")
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.textMuted)
                        }
                    } footer: {
                        Text("Use iCloud backup configuration and config files.")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textMuted)
                    }
                    .listRowBackground(Theme.cardBackground)
                    
                    // Servers
                    Section("SERVERS") {
                        Toggle(isOn: $overwriteServer) {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(Theme.rocketBlue)
                                    .frame(width: 24)
                                Text("Overwrite Server")
                                    .foregroundColor(Theme.textPrimary)
                            }
                        }
                        .tint(Theme.accentGreen)
                        
                        dataActionRow(icon: "arrow.down.doc", title: "Import Servers...")
                        dataActionRow(icon: "arrow.up.doc", title: "Export Servers...")
                        
                        Button(action: {
                            vpnManager.directNodes.removeAll()
                            vpnManager.saveState()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(Theme.accentRed)
                                    .frame(width: 24)
                                Text("Delete Local Servers")
                                    .foregroundColor(Theme.accentRed)
                            }
                        }
                    }
                    .listRowBackground(Theme.cardBackground)
                    
                    // Statistics
                    Section("STATISTICS") {
                        dataActionRow(icon: "waveform.path.ecg", title: "Statistics")
                    }
                    .listRowBackground(Theme.cardBackground)
                    
                    // Logs
                    Section("LOGS") {
                        Toggle(isOn: $autoDeleteLogs) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(Theme.rocketBlue)
                                    .frame(width: 24)
                                Text("Auto Delete")
                                    .foregroundColor(Theme.textPrimary)
                            }
                        }
                        .tint(Theme.accentGreen)
                        
                        dataActionRow(icon: "square.stack.3d.up", title: "Proxy Logs")
                        dataActionRow(icon: "flag", title: "DNS Logs")
                    }
                    .listRowBackground(Theme.cardBackground)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Data")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func dataActionRow(icon: String, title: String) -> some View {
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
}
