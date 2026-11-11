import SwiftUI

@main
struct ChatOneApp: App {
    @StateObject private var chatService = ChatService()

    var body: some Scene {
        WindowGroup {
            ChatView(chatService: chatService)
                .preferredColorScheme(.dark) // Default to sleek modern dark theme like original ChatOne
        }
    }
}
