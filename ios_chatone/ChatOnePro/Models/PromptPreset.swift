import Foundation

public struct PromptPreset: Identifiable, Sendable {
    public let id = UUID()
    public let title: String
    public let subtitle: String
    public let iconName: String
    public let prompt: String

    public static let defaults: [PromptPreset] = [
        PromptPreset(
            title: "Code Review & Fix",
            subtitle: "Analyze and optimize Swift/Python/C++ code",
            iconName: "chevron.left.forwardslash.chevron.right",
            prompt: "Please review the following code, find any bugs or security risks, and provide optimized production-ready fixes:"
        ),
        PromptPreset(
            title: "Explain Concept",
            subtitle: "Break down complex topics clearly",
            iconName: "brain.head.profile",
            prompt: "Explain how this concept works in clear, intuitive terms with a practical real-world example:"
        ),
        PromptPreset(
            title: "Professional Writing",
            subtitle: "Refine tone, clarity, and style",
            iconName: "pencil.line",
            prompt: "Please rewrite and polish the following text to sound authoritative, concise, and professional:"
        ),
        PromptPreset(
            title: "Translate & Localize",
            subtitle: "Natural multi-language adaptation",
            iconName: "globe",
            prompt: "Translate the following text into natural, idiomatic Russian while maintaining technical terminology:"
        ),
        PromptPreset(
            title: "Summarize & Extract",
            subtitle: "Key takeaways and action items",
            iconName: "list.bullet.rectangle",
            prompt: "Summarize this material into 3-5 concise bullet points and highlight critical action items:"
        )
    ]
}
