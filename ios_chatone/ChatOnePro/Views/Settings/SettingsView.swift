import SwiftUI

public struct SettingsView: View {
    @ObservedObject var chatService: ChatService
    @Environment(\.dismiss) private var dismiss

    @State private var showApiKey: Bool = false

    public init(chatService: ChatService) {
        self.chatService = chatService
    }

    public var body: some View {
        NavigationStack {
            Form {
                // Section: Pro Status
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 44, height: 44)
                            Image(systemName: "crown.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("ChatOne Pro")
                                    .font(.headline)
                                Text("ACTIVE")
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                            Text("All Pro Models & Infinite Tokens Unlocked")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Section: AI Model
                Section("Default AI Model") {
                    Picker("Model", selection: $chatService.selectedModelId) {
                        ForEach(AIModel.defaultModels) { model in
                            HStack {
                                Text(model.name)
                                Spacer()
                                Text(model.provider)
                                    .foregroundColor(.secondary)
                            }
                            .tag(model.id)
                        }
                    }
                }

                // Section: API Configuration
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Base URL")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("https://api.deepseek.com/v1", text: $chatService.baseUrl)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .font(.system(.body, design: .monospaced))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("API Key")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button(showApiKey ? "Hide" : "Show") {
                                showApiKey.toggle()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }

                        if showApiKey {
                            TextField("sk-...", text: $chatService.apiKey)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .font(.system(.body, design: .monospaced))
                        } else {
                            SecureField("sk-...", text: $chatService.apiKey)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .font(.system(.body, design: .monospaced))
                        }
                    }

                    // Quick Endpoint Presets
                    Menu("Endpoint Presets") {
                        Button("DeepSeek Official") {
                            chatService.baseUrl = "https://api.deepseek.com/v1"
                            chatService.selectedModelId = "deepseek-chat"
                        }
                        Button("OpenAI Official") {
                            chatService.baseUrl = "https://api.openai.com/v1"
                            chatService.selectedModelId = "gpt-4o"
                        }
                        Button("OpenRouter AI") {
                            chatService.baseUrl = "https://openrouter.ai/api/v1"
                        }
                        Button("Local Bridge (http://localhost:8000/v1)") {
                            chatService.baseUrl = "http://localhost:8000/v1"
                        }
                    }
                } header: {
                    Text("API Connection")
                } footer: {
                    Text("Compatible with any OpenAI-compatible API endpoint including DeepSeek, OpenRouter, and local proxies.")
                }

                // Section: Generation Parameters
                Section("Parameters") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Temperature")
                            Spacer()
                            Text(String(format: "%.2f", chatService.temperature))
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $chatService.temperature, in: 0.0...1.5, step: 0.05)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("System Prompt")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("System prompt...", text: $chatService.globalSystemPrompt, axis: .vertical)
                            .lineLimit(2...5)
                    }
                }

                // Section: About & Updates
                Section("App Information") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (Pro Unlocked)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Update Policy")
                        Spacer()
                        Text("Autonomous / Never Prompts")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Architecture")
                        Spacer()
                        Text("iOS 16.0+ (ARM64 Native)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
