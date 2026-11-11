import SwiftUI

public struct ChatView: View {
    @ObservedObject var chatService: ChatService

    @State private var inputText: String = ""
    @State private var showHistorySheet: Bool = false
    @State private var showSettingsSheet: Bool = false

    public init(chatService: ChatService) {
        self.chatService = chatService
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let session = chatService.currentSession, !session.messages.isEmpty {
                    messagesScrollView(for: session)
                } else {
                    welcomeAndPresetsView
                }

                InputBarView(
                    text: $inputText,
                    isStreaming: chatService.isStreaming,
                    onSend: {
                        let text = inputText
                        inputText = ""
                        chatService.sendMessage(text)
                    },
                    onStop: {
                        chatService.cancelStreaming()
                    }
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showHistorySheet = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 16))
                    }
                }

                ToolbarItem(placement: .principal) {
                    modelPickerMenu
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        chatService.createNewSession()
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 16))
                    }

                    Button {
                        showSettingsSheet = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16))
                    }
                }
            }
            .sheet(isPresented: $showHistorySheet) {
                HistoryView(chatService: chatService)
            }
            .sheet(isPresented: $showSettingsSheet) {
                SettingsView(chatService: chatService)
            }
        }
    }

    private var modelPickerMenu: some View {
        Menu {
            ForEach(AIModel.defaultModels) { model in
                Button {
                    chatService.selectedModelId = model.id
                    if let curId = chatService.currentSessionId,
                       let idx = chatService.sessions.firstIndex(where: { $0.id == curId }) {
                        chatService.sessions[idx].modelId = model.id
                    }
                } label: {
                    HStack {
                        Text(model.name)
                        if chatService.selectedModelId == model.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(currentModelName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.12))
            .clipShape(Capsule())
        }
    }

    private var currentModelName: String {
        let currentId = chatService.currentSession?.modelId ?? chatService.selectedModelId
        return AIModel.defaultModels.first(where: { $0.id == currentId })?.name ?? currentId
    }

    private func messagesScrollView(for session: ChatSession) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(session.messages) { msg in
                        MessageBubbleView(message: msg) { content in
                            UIPasteboard.general.string = content
                        }
                        .id(msg.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: session.messages.last?.content) { _ in
                if let lastId = session.messages.last?.id {
                    proxy.scrollTo(lastId, anchor: .bottom)
                }
            }
            .onChange(of: session.messages.count) { _ in
                if let lastId = session.messages.last?.id {
                    withAnimation {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var welcomeAndPresetsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 20)

                // Icon / Logo
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.06))
                        .frame(width: 80, height: 80)
                    Image(systemName: "circle.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.primary)
                }

                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Text("ChatOne")
                            .font(.system(size: 26, weight: .bold))
                        Text("PRO")
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }

                    Text("Where intelligence meets simplicity.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                PromptPresetsView { prompt in
                    inputText = prompt
                }

                Spacer(minLength: 20)
            }
        }
    }
}
