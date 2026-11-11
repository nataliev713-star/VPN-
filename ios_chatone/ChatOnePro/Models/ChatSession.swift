import Foundation

public struct ChatSession: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public let createdAt: Date
    public var updatedAt: Date
    public var messages: [ChatMessage]
    public var modelId: String
    public var systemPrompt: String
    public var isPinned: Bool

    public init(
        id: UUID = UUID(),
        title: String = "Новый разговор",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        messages: [ChatMessage] = [],
        modelId: String = "deepseek-chat",
        systemPrompt: String = "You are ChatOne Pro, an intelligent, helpful, and highly accurate AI assistant.",
        isPinned: Bool = false
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messages = messages
        self.modelId = modelId
        self.systemPrompt = systemPrompt
        self.isPinned = isPinned
    }
}
