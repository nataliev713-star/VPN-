import Foundation

public struct ChatSession: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public let createdAt: Date
    public var updatedAt: Date
    public var messages: [ChatMessage]
    public var modelId: String
    public var systemPrompt: String

    public init(
        id: UUID = UUID(),
        title: String = "New Chat",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        messages: [ChatMessage] = [],
        modelId: String = "deepseek-chat",
        systemPrompt: String = "You are ChatOne Pro, an intelligent, helpful, and highly accurate AI assistant."
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messages = messages
        self.modelId = modelId
        self.systemPrompt = systemPrompt
    }
}
