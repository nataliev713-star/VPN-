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
                GrokEmblemView(size: 22, color: .white)
                    .padding(.top, 4)
            } else {
                Spacer(minLength: 40)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                // Model indicator if assistant
                if message.role == .assistant, let model = message.model {
                    HStack(spacing: 4) {
                        Text(model.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(white: 0.18))
                            .clipShape(Capsule())
                            .foregroundColor(Color(white: 0.6))
                        
                        if message.isStreaming {
                            ProgressView()
                                .tint(.white)
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
                                Text(isReasoningExpanded ? "Скрыть ход мыслей" : "Показать размышления")
                                    .font(.system(size: 12, weight: .medium))
                                Image(systemName: isReasoningExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(Color.cyan)
                        }

                        if isReasoningExpanded {
                            Text(reasoning)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(Color(white: 0.7))
                                .padding(10)
                                .background(Color(white: 0.1))
                                .cornerRadius(8)
                        }
                    }
                }

                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    if message.content.isEmpty && message.isStreaming {
                        HStack(spacing: 4) {
                            Text("Печатает...")
                                .font(.system(size: 15))
                                .foregroundColor(Color(white: 0.6))
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.7)
                        }
                    } else {
                        Text(LocalizedStringKey(message.content))
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .textSelection(.enabled)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(bubbleBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                // Actions (Copy / Share)
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
                                Text(showCopiedAlert ? "Скопировано" : "Копировать")
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(showCopiedAlert ? .green : Color(white: 0.5))
                        }

                        ShareLink(item: message.content) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 12))
                                .foregroundColor(Color(white: 0.5))
                        }
                    }
                    .padding(.leading, 4)
                }
            }

            if message.role == .assistant {
                Spacer(minLength: 40)
            }
        }
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        if message.role == .user {
            Color(white: 0.18)
        } else {
            Color.clear
        }
    }
}
