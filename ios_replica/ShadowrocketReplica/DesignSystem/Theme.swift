import SwiftUI

enum Theme {
    static let background = Color(red: 10/255, green: 10/255, blue: 12/255)
    static let cardBackground = Color(red: 24/255, green: 24/255, blue: 26/255)
    static let secondaryCard = Color(red: 34/255, green: 34/255, blue: 38/255)
    static let divider = Color(white: 0.2)
    
    // Акцентные цвета Shadowrocket
    static let rocketBlue = Color(red: 0/255, green: 168/255, blue: 255/255)
    static let rocketPurple = Color(red: 168/255, green: 85/255, blue: 247/255)
    static let accentGreen = Color(red: 52/255, green: 199/255, blue: 89/255)
    static let accentOrange = Color(red: 255/255, green: 149/255, blue: 0/255)
    static let accentRed = Color(red: 255/255, green: 69/255, blue: 58/255)
    
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.6)
    static let textMuted = Color(white: 0.4)
}

struct RocketIconView: View {
    var size: CGFloat = 28
    
    var body: some View {
        Image(systemName: "airplane")
            .rotationEffect(.degrees(-45))
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(
                LinearGradient(
                    colors: [Theme.rocketBlue, Theme.rocketPurple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}
