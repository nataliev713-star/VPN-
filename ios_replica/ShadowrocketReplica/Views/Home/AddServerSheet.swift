import SwiftUI

struct AddServerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vpnManager: VPNManager
    
    @State private var importText: String = ""
    @State private var serverType: ProxyProtocol = .vless
    @State private var name: String = ""
    @State private var host: String = ""
    @State private var port: String = "443"
    @State private var uuid: String = ""
    @State private var sni: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Быстрый импорт из буфера / ссылки") {
                    TextEditor(text: $importText)
                        .frame(height: 80)
                        .font(.system(size: 13, design: .monospaced))
                    
                    Button("Импортировать (vless://, ss://, sub://)") {
                        importFromText()
                    }
                    .disabled(importText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                Section("Ручная настройка узла") {
                    Picker("Тип протокола", selection: $serverType) {
                        ForEach(ProxyProtocol.allCases, id: \.self) { proto in
                            Text(proto.displayName).tag(proto)
                        }
                    }
                    
                    TextField("Имя сервера", text: $name)
                    TextField("Хост / IP", text: $host)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    TextField("Порт", text: $port)
                        .keyboardType(.numberPad)
                    TextField("UUID / Пароль", text: $uuid)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    TextField("SNI (Server Name Indication)", text: $sni)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            .navigationTitle("Add Server")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveManualServer()
                    }
                    .disabled(host.isEmpty || uuid.isEmpty)
                }
            }
        }
    }
    
    private func importFromText() {
        let trimmed = importText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            // Удаленная подписка
            Task {
                if let nodes = try? await SubscriptionParser.shared.fetchSubscription(from: trimmed) {
                    let group = SubscriptionGroup(name: "New Subscription", url: trimmed, nodes: nodes)
                    vpnManager.subscriptions.append(group)
                    vpnManager.saveState()
                    dismiss()
                }
            }
        } else {
            let nodes = SubscriptionParser.shared.parseSubscriptionContent(trimmed)
            if !nodes.isEmpty {
                vpnManager.directNodes.append(contentsOf: nodes)
                vpnManager.saveState()
                dismiss()
            }
        }
    }
    
    private func saveManualServer() {
        guard let portInt = Int(port) else { return }
        let node = ProxyNode(
            name: name.isEmpty ? "Server \(vpnManager.directNodes.count + 1)" : name,
            protocolType: serverType,
            host: host,
            port: portInt,
            uuidOrPassword: uuid,
            sni: sni
        )
        vpnManager.directNodes.append(node)
        vpnManager.saveState()
        dismiss()
    }
}
