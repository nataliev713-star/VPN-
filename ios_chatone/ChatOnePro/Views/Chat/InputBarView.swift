import SwiftUI

public struct InputBarView: View {
    @Binding var text: String
    @Binding var selectedModelId: String
    let isStreaming: Bool
    let onSend: () -> Void
    let onStop: () -> Void
    let onSelectSkill: (String) -> Void

    @FocusState private var isFocused: Bool

    public init(
        text: Binding<String>,
        selectedModelId: Binding<String>,
        isStreaming: Bool,
        onSend: @escaping () -> Void,
        onStop: @escaping () -> Void,
        onSelectSkill: @escaping (String) -> Void
    ) {
        self._text = text
        self._selectedModelId = selectedModelId
        self.isStreaming = isStreaming
        self.onSend = onSend
        self.onStop = onStop
        self.onSelectSkill = onSelectSkill
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Suggestion / Skills Pills above input (photo 1)
            HStack(spacing: 10) {
                Button {
                    onSelectSkill("Попробуй навыки: покажи свои расширенные возможности и функции анализа")
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 14))
                        Text("Попробуй навыки")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(white: 0.14))
                    .clipShape(Capsule())
                }

                Button {
                    onSelectSkill("Создай подробный сценарий для короткого видеоролика")
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12))
                        Text("Создать видео")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(white: 0.14))
                    .clipShape(Capsule())
                }

                Spacer()
            }
            .padding(.horizontal, 16)

            // Main Unified Input Card (photo 1)
            VStack(alignment: .leading, spacing: 10) {
                // Top: Text Field
                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("Спрашивай что угодно")
                            .font(.system(size: 17))
                            .foregroundColor(Color(white: 0.45))
                            .padding(.top, 2)
                    }

                    TextField("", text: $text, axis: .vertical)
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                        .lineLimit(1...6)
                        .focused($isFocused)
                }
                .padding(.horizontal, 6)
                .padding(.top, 4)

                // Bottom: Action Controls inside the card
                HStack(alignment: .center, spacing: 8) {
                    // Plus Action Button
                    Button {
                        // Attach action
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 34, height: 34)
                            .background(Color(white: 0.22))
                            .clipShape(Circle())
                    }

                    // Model Selector Pill (🚀 Авто)
                    Menu {
                        ForEach(AIModel.defaultModels) { model in
                            Button {
                                selectedModelId = model.id
                            } label: {
                                HStack {
                                    Text(model.name)
                                    if selectedModelId == model.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 12))
                            Text(modelShortName)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color(white: 0.22))
                        .clipShape(Capsule())
                    }

                    Spacer()

                    // Microphone Icon
                    Button {
                        // Mic trigger
                    } label: {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(white: 0.7))
                            .frame(width: 32, height: 32)
                    }

                    // Right Button: Voice Pill or Send Arrow or Stop
                    if isStreaming {
                        Button(action: onStop) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 38, height: 38)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                    } else if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button(action: onSend) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                                .frame(width: 38, height: 38)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                    } else {
                        // Voice Mode Pill ([||| Голосовой...])
                        Button {
                            // Voice chat activation
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "waveform")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Голосовой...")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(Color.white)
                            .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(12)
            .background(Color(white: 0.12))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
        }
        .background(Color.black)
    }

    private var modelShortName: String {
        if selectedModelId == "deepseek-chat" { return "Авто" }
        if selectedModelId == "deepseek-reasoner" { return "R1 Мышление" }
        if selectedModelId.contains("gpt-4o") { return "GPT-4o" }
        if selectedModelId.contains("claude") { return "Claude" }
        return "Авто"
    }
}
