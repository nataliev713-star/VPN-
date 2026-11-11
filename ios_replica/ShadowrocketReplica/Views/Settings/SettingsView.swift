import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var vpnManager: VPNManager
    
    @State private var moderatedPolicy = true
    @State private var allowDetectClipboard = true
    @State private var allowThirdKeyboard = false
    @State private var autoRotate = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                List {
                    // Language
                    Section {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(Theme.rocketBlue)
                                .frame(width: 24)
                            Text("Language")
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                            Text("English")
                                .foregroundColor(Theme.textMuted)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.textMuted)
                        }
                    }
                    .listRowBackground(Theme.cardBackground)
                    
                    // Advanced
                    Section("ADVANCED") {
                        NavigationLink {
                            testMethodPicker
                        } label: {
                            HStack {
                                Image(systemName: "flag")
                                    .foregroundColor(Theme.rocketBlue)
                                    .frame(width: 24)
                                Text("Test Method")
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                                Text(vpnManager.pingMethod == .realHttp204 ? "HTTP 204" : "TCP")
                                    .foregroundColor(Theme.textMuted)
                            }
                        }
                        
                        settingsRow(icon: "antenna.radiowaves.left.and.right", title: "Today Widget")
                        settingsRow(icon: "network.badge.shield.half.filled", title: "On Demand")
                        settingsRow(icon: "wand.and.stars", title: "Shortcuts")
                        settingsRow(icon: "ladybug", title: "Diagnostics")
                        settingsRow(icon: "square.grid.2x2", title: "Colors")
                    }
                    .listRowBackground(Theme.cardBackground)
                    
                    // Tunnel
                    Section("TUNNEL") {
                        settingsRow(icon: "square.stack.3d.up", title: "Proxy")
                        settingsRow(icon: "arrow.left.arrow.right", title: "TCP")
                        settingsRow(icon: "point.3.connected.trianglepath.dotted", title: "UDP")
                    }
                    .listRowBackground(Theme.cardBackground)
                    
                    // Misc
                    Section("MISC") {
                        settingsRow(icon: "arrow.right.to.line", title: "Reminder", trailing: "Off")
                        Toggle(isOn: $moderatedPolicy) {
                            HStack {
                                Image(systemName: "arrow.triangle.swap")
                                    .foregroundColor(Theme.rocketBlue)
                                    .frame(width: 24)
                                Text("Moderated Policy Mechanism")
                                    .foregroundColor(Theme.textPrimary)
                            }
                        }
                        .tint(Theme.accentGreen)
                        
                        Toggle(isOn: $allowDetectClipboard) {
                            HStack {
                                Image(systemName: "doc.on.clipboard")
                                    .foregroundColor(Theme.rocketBlue)
                                    .frame(width: 24)
                                Text("Allow Detect Clipboard")
                                    .foregroundColor(Theme.textPrimary)
                            }
                        }
                        .tint(Theme.accentGreen)
                        
                        settingsRow(icon: "map", title: "GeoLite2 Database")
                        settingsRow(icon: "link", title: "Subscribe")
                        settingsRow(icon: "person.2", title: "User Agent")
                        settingsRow(icon: "arrow.counterclockwise", title: "Reset")
                    }
                    .listRowBackground(Theme.cardBackground)
                    
                    // About
                    Section("ABOUT") {
                        HStack {
                            RocketIconView(size: 20)
                                .frame(width: 24)
                            Text("About")
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                            Text("Replica v1.0")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.textMuted)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.textMuted)
                        }
                    }
                    .listRowBackground(Theme.cardBackground)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var testMethodPicker: some View {
        List {
            ForEach(PingMethod.allCases, id: \.self) { method in
                Button(action: {
                    vpnManager.pingMethod = method
                }) {
                    HStack {
                        Text(method.rawValue)
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        if vpnManager.pingMethod == method {
                            Image(systemName: "checkmark")
                                .foregroundColor(Theme.accentGreen)
                        }
                    }
                }
            }
        }
        .navigationTitle("Test Method")
    }
    
    private func settingsRow(icon: String, title: String, trailing: String? = nil) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Theme.rocketBlue)
                .frame(width: 24)
            Text(title)
                .foregroundColor(Theme.textPrimary)
                .font(.system(size: 15))
            Spacer()
            if let trailing = trailing {
                Text(trailing)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textMuted)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textMuted)
        }
    }
}
