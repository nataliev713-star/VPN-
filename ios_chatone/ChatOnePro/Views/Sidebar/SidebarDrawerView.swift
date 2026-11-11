import SwiftUI

public struct SidebarDrawerView: View {
    @ObservedObject var chatService: ChatService
    @Binding var isOpen: Bool
    @Binding var showSettings: Bool

    @State private var searchText: String = ""

    public init(chatService: ChatService, isOpen: Binding<Bool>, showSettings: Binding<Bool>) {
        self.chatService = chatService
        self._isOpen = isOpen
        self._showSettings = showSettings
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Profile Header
                profileHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 18)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        // Quick Links
                        quickLinksSection

                        // Section: Закреплено (Pinned)
                        if !pinnedSessions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Закреплено")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color(white: 0.5))

                                ForEach(pinnedSessions) { session in
                                    sessionRow(session)
                                }
                            }
                        }

                        // Section: Разговоры (Conversations)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Разговоры")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(white: 0.5))

                            ForEach(unpinnedSessions) { session in
                                sessionRow(session)
                            }
                        }

                        // Bottom Spacer for floating bar
                        Spacer(minLength: 90)
                    }
                    .padding(.horizontal, 20)
                }
            }

            // Bottom Sticky Bar: Settings, Search, New Chat
            bottomActionBar
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .background(
                    LinearGradient(
                        colors: [Color.black.opacity(0), Color.black, Color.black],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }

    private var profileHeader: some View {
        HStack(spacing: 12) {
            // User Avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color.teal, Color.cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 42, height: 42)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("Alexander Skljar")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(white: 0.6))
                }
                Text("Plus")
                    .font(.system(size: 13))
                    .foregroundColor(Color(white: 0.6))
            }

            Spacer()

            // Close Drawer Button
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isOpen = false
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color(white: 0.16))
                    .clipShape(Circle())
            }
        }
    }

    private var quickLinksSection: some View {
        VStack(spacing: 16) {
            quickLinkRow(icon: "clock.arrow.2.circlepath", title: "Автоматизации")
            quickLinkRow(icon: "folder", title: "Проекты")
            quickLinkRow(icon: "circle.circle", title: "Grok Bot")
        }
    }

    private func quickLinkRow(icon: String, title: String) -> some View {
        Button {
            // Quick navigation
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                Spacer()
            }
        }
    }

    private func sessionRow(_ session: ChatSession) -> some View {
        Button {
            chatService.selectSession(id: session.id)
            withAnimation(.easeInOut(duration: 0.25)) {
                isOpen = false
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(session.id == chatService.currentSessionId ? .white : Color(white: 0.9))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if session.isPinned || session.title.contains("базаришь") || session.title.contains("Приветствие") {
                        Image(systemName: "waveform")
                            .font(.system(size: 11))
                            .foregroundColor(Color(white: 0.5))
                    }
                    Text(formatDate(session.updatedAt, title: session.title))
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.5))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
        .contextMenu {
            Button {
                chatService.togglePin(id: session.id)
            } label: {
                Label(session.isPinned ? "Открепить" : "Закрепить", systemImage: session.isPinned ? "pin.slash" : "pin")
            }

            Button(role: .destructive) {
                chatService.deleteSession(id: session.id)
            } label: {
                Label("Удалить", systemImage: "trash")
            }
        }
    }

    private var bottomActionBar: some View {
        HStack(spacing: 12) {
            // Settings Button
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color(white: 0.16))
                    .clipShape(Circle())
            }

            // Search Bar Capsule
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(white: 0.5))

                TextField("Поиск", text: $searchText)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(Color(white: 0.16))
            .clipShape(Capsule())

            // New Chat Pen Button
            Button {
                chatService.createNewSession()
                withAnimation(.easeInOut(duration: 0.25)) {
                    isOpen = false
                }
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 44, height: 44)
                    .background(Color.white)
                    .clipShape(Circle())
            }
        }
    }

    private var pinnedSessions: [ChatSession] {
        filteredSessions.filter { $0.isPinned }
    }

    private var unpinnedSessions: [ChatSession] {
        filteredSessions.filter { !$0.isPinned }
    }

    private var filteredSessions: [ChatSession] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return chatService.sessions
        }
        return chatService.sessions.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    private func formatDate(_ date: Date, title: String) -> String {
        if title.contains("Новосибирска") || title.contains("Багрове") {
            return "Вчера"
        } else if title.contains("Приветствие") || title.contains("базаришь") {
            return "вторник"
        } else if title.contains("тормозного") {
            return "воскресенье"
        } else if title.contains("вся хуйня") {
            return "четверг"
        }
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Сегодня" }
        if cal.isDateInYesterday(date) { return "Вчера" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}
