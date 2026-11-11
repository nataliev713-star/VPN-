import SwiftUI

public struct HistoryView: View {
    @ObservedObject var chatService: ChatService
    @Environment(\.dismiss) private var dismiss

    public init(chatService: ChatService) {
        self.chatService = chatService
    }

    public var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        chatService.createNewSession()
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.blue)
                            Text("New Chat")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Recent Conversations") {
                    ForEach(chatService.sessions) { session in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.title)
                                    .font(.system(size: 15, weight: session.id == chatService.currentSessionId ? .bold : .regular))
                                    .lineLimit(1)

                                HStack(spacing: 6) {
                                    Text(session.modelId)
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundColor(.secondary)
                                    Text("•")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                    Text(session.updatedAt, style: .date)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            if session.id == chatService.currentSessionId {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            chatService.selectSession(id: session.id)
                            dismiss()
                        }
                    }
                    .onDelete { indexSet in
                        for idx in indexSet {
                            let s = chatService.sessions[idx]
                            chatService.deleteSession(id: s.id)
                        }
                    }
                }
            }
            .navigationTitle("History")
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
