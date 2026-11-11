import Foundation
import Combine

@MainActor
public final class ChatService: ObservableObject {
    @Published public var sessions: [ChatSession] = []
    @Published public var currentSessionId: UUID?
    @Published public var isStreaming: Bool = false
    @Published public var errorMessage: String?
    
    // Settings (persisted)
    @Published public var apiKey: String {
        didSet { UserDefaults.standard.set(apiKey, forKey: "chatone_api_key") }
    }
    @Published public var baseUrl: String {
        didSet { UserDefaults.standard.set(baseUrl, forKey: "chatone_base_url") }
    }
    @Published public var selectedModelId: String {
        didSet { UserDefaults.standard.set(selectedModelId, forKey: "chatone_model_id") }
    }
    @Published public var temperature: Double {
        didSet { UserDefaults.standard.set(temperature, forKey: "chatone_temp") }
    }
    @Published public var globalSystemPrompt: String {
        didSet { UserDefaults.standard.set(globalSystemPrompt, forKey: "chatone_system_prompt") }
    }
    
    // Pro Status: Always True
    public let isProUnlocked: Bool = true
    
    private var streamTask: Task<Void, Never>?
    private let sessionsKey = "chatone_saved_sessions_v2"

    public var currentSession: ChatSession? {
        guard let id = currentSessionId else { return sessions.first }
        return sessions.first(where: { $0.id == id })
    }

    public init() {
        let storedKey = UserDefaults.standard.string(forKey: "chatone_api_key") ?? ""
        let storedUrl = UserDefaults.standard.string(forKey: "chatone_base_url") ?? "https://api.deepseek.com/v1"
        let storedModel = UserDefaults.standard.string(forKey: "chatone_model_id") ?? "deepseek-chat"
        let storedTemp = UserDefaults.standard.double(forKey: "chatone_temp")
        let storedSysPrompt = UserDefaults.standard.string(forKey: "chatone_system_prompt") ?? "You are ChatOne Pro, an exceptionally intelligent, helpful, and concise AI assistant."

        self.apiKey = storedKey
        self.baseUrl = storedUrl.isEmpty ? "https://api.deepseek.com/v1" : storedUrl
        self.selectedModelId = storedModel
        self.temperature = storedTemp == 0 ? 0.7 : storedTemp
        self.globalSystemPrompt = storedSysPrompt

        loadSessions()
        if sessions.isEmpty {
            // Seed with exact UI conversations matching user's photo
            let pinned = ChatSession(
                title: "вся хуйня",
                messages: [ChatMessage(role: .assistant, content: "Привет! Чем могу помочь?")],
                modelId: selectedModelId,
                systemPrompt: globalSystemPrompt,
                isPinned: true
            )
            let conv1 = ChatSession(
                title: "Новости Новосибирска сейчас",
                messages: [ChatMessage(role: .assistant, content: "Вот актуальные события и новости Новосибирска на сегодня...")],
                modelId: selectedModelId,
                systemPrompt: globalSystemPrompt
            )
            let conv2 = ChatSession(
                title: "Стихотворение о Даниле Багрове",
                messages: [ChatMessage(role: .assistant, content: "В чем сила, брат? В правде сила...")],
                modelId: selectedModelId,
                systemPrompt: globalSystemPrompt
            )
            let conv3 = ChatSession(
                title: "Приветствие",
                messages: [ChatMessage(role: .assistant, content: "Здравствуйте! Чем я могу быть полезен?")],
                modelId: selectedModelId,
                systemPrompt: globalSystemPrompt
            )
            let conv4 = ChatSession(
                title: "Чё не базаришь со мной?",
                messages: [ChatMessage(role: .assistant, content: "Я тут, на связи! Задавай любой вопрос.")],
                modelId: selectedModelId,
                systemPrompt: globalSystemPrompt
            )
            let conv5 = ChatSession(
                title: "Расчет размера тормозного диска авто",
                messages: [ChatMessage(role: .assistant, content: "Для правильного расчета диаметра и толщины тормозного диска необходимо учитывать массу авто, развесовку и кинетическую энергию...")],
                modelId: selectedModelId,
                systemPrompt: globalSystemPrompt
            )

            sessions = [pinned, conv1, conv2, conv3, conv4, conv5]
            currentSessionId = conv1.id
            saveSessions()
        } else {
            currentSessionId = sessions.first?.id
        }
    }

    public func createNewSession(withModel modelId: String? = nil, initialPrompt: String? = nil) {
        let model = modelId ?? selectedModelId
        var session = ChatSession(
            title: "Новый разговор",
            modelId: model,
            systemPrompt: globalSystemPrompt
        )
        if let initialPrompt = initialPrompt {
            session.messages.append(ChatMessage(role: .user, content: initialPrompt))
        }
        sessions.insert(session, at: 0)
        currentSessionId = session.id
        saveSessions()

        if initialPrompt != nil {
            Task {
                await streamResponse(for: session.id)
            }
        }
    }

    public func togglePin(id: UUID) {
        guard let idx = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[idx].isPinned.toggle()
        saveSessions()
    }

    public func deleteSession(id: UUID) {
        sessions.removeAll(where: { $0.id == id })
        if currentSessionId == id {
            currentSessionId = sessions.first?.id
        }
        if sessions.isEmpty {
            createNewSession()
        } else {
            saveSessions()
        }
    }

    public func selectSession(id: UUID) {
        currentSessionId = id
    }

    public func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let currentId = currentSessionId,
              let index = sessions.firstIndex(where: { $0.id == currentId }) else { return }

        let userMsg = ChatMessage(role: .user, content: text)
        sessions[index].messages.append(userMsg)
        sessions[index].updatedAt = Date()

        if sessions[index].title == "Новый разговор" || sessions[index].title == "New Chat" {
            let prefix = String(text.prefix(32)).trimmingCharacters(in: .whitespacesAndNewlines)
            sessions[index].title = prefix.isEmpty ? "Разговор" : prefix
        }

        saveSessions()

        Task {
            await streamResponse(for: currentId)
        }
    }

    public func cancelStreaming() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
        if let currentId = currentSessionId,
           let sessionIndex = sessions.firstIndex(where: { $0.id == currentId }) {
            if let lastIndex = sessions[sessionIndex].messages.indices.last {
                sessions[sessionIndex].messages[lastIndex].isStreaming = false
            }
        }
        saveSessions()
    }

    private func streamResponse(for sessionId: UUID) async {
        guard let sessionIndex = sessions.firstIndex(where: { $0.id == sessionId }) else { return }
        
        let session = sessions[sessionIndex]
        let model = session.modelId.isEmpty ? selectedModelId : session.modelId
        let assistantMsgId = UUID()
        let assistantMsg = ChatMessage(
            id: assistantMsgId,
            role: .assistant,
            content: "",
            reasoningContent: nil,
            model: model,
            isStreaming: true
        )
        sessions[sessionIndex].messages.append(assistantMsg)
        isStreaming = true
        errorMessage = nil

        streamTask = Task {
            do {
                try await performStreamRequest(sessionId: sessionId, assistantMsgId: assistantMsgId, model: model)
            } catch {
                if !Task.isCancelled {
                    self.errorMessage = error.localizedDescription
                    if let sIdx = self.sessions.firstIndex(where: { $0.id == sessionId }),
                       let mIdx = self.sessions[sIdx].messages.firstIndex(where: { $0.id == assistantMsgId }) {
                        if self.sessions[sIdx].messages[mIdx].content.isEmpty {
                            self.sessions[sIdx].messages[mIdx].content = "⚠️ Ошибка подключения: \(error.localizedDescription)\n\nПожалуйста, проверьте API-ключ и Base URL в Настройках."
                        }
                        self.sessions[sIdx].messages[mIdx].isStreaming = false
                    }
                }
            }
            self.isStreaming = false
            self.saveSessions()
        }
    }

    private func performStreamRequest(sessionId: UUID, assistantMsgId: UUID, model: String) async throws {
        var cleanBaseUrl = baseUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanBaseUrl.hasSuffix("/") {
            cleanBaseUrl.removeLast()
        }
        guard let url = URL(string: "\(cleanBaseUrl)/chat/completions") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            request.setValue("Bearer \(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))", forHTTPHeaderField: "Authorization")
        }

        guard let sessionIndex = sessions.firstIndex(where: { $0.id == sessionId }) else { return }
        let currentMessages = sessions[sessionIndex].messages.filter { $0.id != assistantMsgId }

        var payloadMessages: [[String: String]] = [
            ["role": "system", "content": sessions[sessionIndex].systemPrompt]
        ]
        for msg in currentMessages {
            payloadMessages.append(["role": msg.role.rawValue, "content": msg.content])
        }

        let body: [String: Any] = [
            "model": model,
            "messages": payloadMessages,
            "stream": true,
            "temperature": temperature
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "ChatOne", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Сервер вернул код \(httpResponse.statusCode)"])
        }

        for try await line in bytes.lines {
            if Task.isCancelled { break }
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.hasPrefix("data: ") else { continue }
            let dataPayload = String(trimmed.dropFirst(6))
            if dataPayload == "[DONE]" { break }

            guard let jsonData = dataPayload.data(using: .utf8),
                  let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                  let choices = jsonObject["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let delta = firstChoice["delta"] as? [String: Any] else {
                continue
            }

            let deltaContent = delta["content"] as? String ?? ""
            let reasoning = delta["reasoning_content"] as? String

            if let sIdx = self.sessions.firstIndex(where: { $0.id == sessionId }),
               let mIdx = self.sessions[sIdx].messages.firstIndex(where: { $0.id == assistantMsgId }) {
                if !deltaContent.isEmpty {
                    self.sessions[sIdx].messages[mIdx].content += deltaContent
                }
                if let r = reasoning, !r.isEmpty {
                    var currentR = self.sessions[sIdx].messages[mIdx].reasoningContent ?? ""
                    currentR += r
                    self.sessions[sIdx].messages[mIdx].reasoningContent = currentR
                }
            }
        }

        if let sIdx = self.sessions.firstIndex(where: { $0.id == sessionId }),
           let mIdx = self.sessions[sIdx].messages.firstIndex(where: { $0.id == assistantMsgId }) {
            self.sessions[sIdx].messages[mIdx].isStreaming = false
        }
    }

    private func saveSessions() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: sessionsKey)
        }
    }

    private func loadSessions() {
        guard let data = UserDefaults.standard.data(forKey: sessionsKey),
              let decoded = try? JSONDecoder().decode([ChatSession].self, from: data) else {
            return
        }
        self.sessions = decoded
    }
}
