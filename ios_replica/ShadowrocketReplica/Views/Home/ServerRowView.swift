import SwiftUI

struct ServerRowView: View {
    let node: ProxyNode
    let isSelected: Bool
    let onSelect: () -> Void
    let onInfo: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Точка выбора активного сервера (как в оригинале Shadowrocket)
                Circle()
                    .fill(isSelected ? Theme.accentOrange : Color.clear)
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(node.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                    
                    HStack(spacing: 6) {
                        Text(node.protocolType.displayName)
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Theme.secondaryCard)
                            .cornerRadius(4)
                            .foregroundColor(Theme.rocketBlue)
                        
                        Text("\(node.host):\(node.port)")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textMuted)
                    }
                }
                
                Spacer()
                
                // Бейдж пинга (реальный замер)
                if node.isTesting {
                    ProgressView()
                        .scaleEffect(0.7)
                } else if let ping = node.pingMs {
                    Text("\(ping) ms")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(pingColor(ping))
                } else {
                    Text("Timeout")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textMuted)
                }
                
                // Кнопка детальной информации
                Button(action: onInfo) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.rocketBlue)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(Theme.cardBackground)
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func pingColor(_ ping: Int) -> Color {
        if ping < 150 {
            return Theme.accentGreen
        } else if ping < 350 {
            return Theme.accentOrange
        } else {
            return Theme.accentRed
        }
    }
}
