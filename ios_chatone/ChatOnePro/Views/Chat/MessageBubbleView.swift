import SwiftUI

public struct MessageBubbleView: View {
    let message: ChatMessage
    let onCopy: (String) -> Void
    @State private var isReasoningExpanded: Bool = false
    @State private var showCopiedAlert: Bool = false

    public init(message: ChatMessage, onCopy: @escaping (String) -> Void) {
        self.message = message
        self.onCopy = onCopy
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.role == .assistant {
                assistantAvatar
            } else {
                Spacer(minLength: 48)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                // Optional Model Badge
                if message.role == .assistant, let model = message.model {
                    HStack(spacing: 4) {
                        Text(model.uppercased())
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(Capsule())
                            .foregroundColor(.secondary)
                        
                        if message.isStreaming {
                            ProgressView()
                                .scaleEffect(0.6)
                        }
                    }
                }

                // Reasoning Section (DeepSeek R1 / CoT)
                if let reasoning = message.reasoningContent, !reasoning.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isReasoningExpanded.toggle()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 11))
                                Text(isReasoningExpanded ? "Hide Reasoning" : "Show Thought Process")
                                    .font(.system(size: 12, weight: .medium))
                                Image(systemName: isReasoningExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.blue)
                        }

                        if isReasoningExpanded {
                            Text(reasoning)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.secondary)
                                .padding(10)
                                .background(Color.secondary.opacity(0.08))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.bottom, 2)
                }

                // Main Message Content
                VStack(alignment: .leading, spacing: 4) {
                    if message.content.isEmpty && message.isStreaming {
                        HStack(spacing: 4) {
                            Text("Thinking")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    } else {
                        Text(LocalizedStringKey(message.content))
                            .font(.system(size: 16))
                            .foregroundColor(message.role == .user ? .white : .primary)
                            .textSelection(.enabled)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(bubbleBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                // Actions (Copy / Share) for Assistant
                if message.role == .assistant && !message.content.isEmpty && !message.isStreaming {
                    HStack(spacing: 14) {
                        Button {
                            onCopy(message.content)
                            showCopiedAlert = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                showCopiedAlert = false
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: showCopiedAlert ? "checkmark" : "doc.on.doc")
                                Text(showCopiedAlert ? "Copied" : "Copy")
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(showCopiedAlert ? .green : .secondary)
                        }

                        ShareLink(item: message.content) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.leading, 4)
                }
            }

            if message.role == .assistant {
                Spacer(minLength: 48)
            }
        }
    }

    private var assistantAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.primary.opacity(0.08))
                .frame(width: 32, height: 32)
            Image(systemName: "circle.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(.primary)
        }
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        if message.role == .user {
            LinearGradient(
                colors: [Color.blue, Color.blue.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color.secondary.opacity(0.12)
        }
    }
}
