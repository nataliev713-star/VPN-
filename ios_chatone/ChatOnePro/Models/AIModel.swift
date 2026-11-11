import Foundation

public struct AIModel: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let name: String
    public let provider: String
    public let description: String
    public let isPro: Bool

    public init(id: String, name: String, provider: String, description: String, isPro: Bool = true) {
        self.id = id
        self.name = name
        self.provider = provider
        self.description = description
        self.isPro = isPro
    }

    public static let defaultModels: [AIModel] = [
        AIModel(
            id: "deepseek-chat",
            name: "DeepSeek V3",
            provider: "DeepSeek",
            description: "Advanced general reasoning, coding, and multilingual knowledge.",
            isPro: true
        ),
        AIModel(
            id: "deepseek-reasoner",
            name: "DeepSeek R1",
            provider: "DeepSeek",
            description: "Deep thinking chain-of-thought model for complex logic, math, and code.",
            isPro: true
        ),
        AIModel(
            id: "gpt-4o",
            name: "GPT-4o",
            provider: "OpenAI",
            description: "Flagship omni model with high intelligence and fast response.",
            isPro: true
        ),
        AIModel(
            id: "gpt-4o-mini",
            name: "GPT-4o Mini",
            provider: "OpenAI",
            description: "Fast, cost-efficient model for everyday chat and summaries.",
            isPro: false
        ),
        AIModel(
            id: "claude-3-5-sonnet-20241022",
            name: "Claude 3.5 Sonnet",
            provider: "Anthropic",
            description: "State-of-the-art coding and nuanced writing capabilities.",
            isPro: true
        )
    ]
}
