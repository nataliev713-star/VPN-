import SwiftUI

public struct ChatView: View {
    @ObservedObject var chatService: ChatService

    @State private var inputText: String = ""
    @State private var isDrawerOpen: Bool = false
    @State private var showSettingsSheet: Bool = false

    public init(chatService: ChatService) {
        self.chatService = chatService
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Main Chat Screen
                VStack(spacing: 0) {
                    // Top Navigation Header (photo 1)
                    headerBar
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                        .background(Color.black)

                    // Middle View: Watermark if empty, or messages list
                    ZStack {
                        Color.black.ignoresSafeArea()

                        if let session = chatService.currentSession, !session.messages.isEmpty {
                            messagesScrollView(for: session)
                        } else {
                            // Empty State Watermark (photo 1)
                            VStack {
                                Spacer()
                                GrokEmblemView(size: 130, color: Color(white: 0.16))
                                Spacer()
                            }
                        }
                    }

                    // Bottom Input Area (photo 1)
                    InputBarView(
                        text: $inputText,
                        selectedModelId: $chatService.selectedModelId,
                        isStreaming: chatService.isStreaming,
                        onSend: {
                            let text = inputText
                            inputText = ""
                            chatService.sendMessage(text)
                        },
                        onStop: {
                            chatService.cancelStreaming()
                        },
                        onSelectSkill: { prompt in
                            inputText = ""
                            chatService.sendMessage(prompt)
                        }
                    )
                }
                .background(Color.black)
                .disabled(isDrawerOpen)

                // Dimming Overlay when Drawer is open
                if isDrawerOpen {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isDrawerOpen = false
                            }
                        }
                }

                // Sliding Left Drawer (photo 2)
                if isDrawerOpen {
                    SidebarDrawerView(
                        chatService: chatService,
                        isOpen: $isDrawerOpen,
                        showSettings: $showSettingsSheet
                    )
                    .frame(width: min(geometry.size.width * 0.88, 360))
                    .transition(.move(edge: .leading))
                    .zIndex(10)
                }
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width > 60 && !isDrawerOpen {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isDrawerOpen = true
                            }
                        } else if value.translation.width < -60 && isDrawerOpen {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isDrawerOpen = false
                            }
                        }
                    }
            )
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettingsSheet) {
            SettingsView(chatService: chatService)
        }
    }

    private var headerBar: some View {
        HStack(spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isDrawerOpen.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    GrokEmblemView(size: 24, color: .white)
                    Text("Grok")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    private func messagesScrollView(for session: ChatSession) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 18) {
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
}
