import SwiftUI

public struct GrokEmblemView: View {
    var size: CGFloat = 24
    var color: Color = .white

    public init(size: CGFloat = 24, color: Color = .white) {
        self.size = size
        self.color = color
    }

    public var body: some View {
        ZStack {
            // Stylized slanted slash-circle emblem (Grok-style)
            Circle()
                .stroke(color, lineWidth: size * 0.12)
                .frame(width: size * 0.76, height: size * 0.76)

            // Dynamic diagonal slash
            Rectangle()
                .fill(color)
                .frame(width: size * 0.14, height: size * 1.05)
                .rotationEffect(.degrees(-45))
        }
        .frame(width: size, height: size)
    }
}
