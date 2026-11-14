import SwiftUI

/// 1-to-1 chat with one friend. Messages live in
/// `directChats/{threadId}/messages` and are visible only to the two
/// participants (firestore.rules). The message rows match the game group
/// chat in EventDetailView.
struct DirectChatView: View {
    let threadId: String
    let otherUid: String
    let otherUsername: String
    @ObservedObject var session: SessionStore
    @StateObject private var store = DirectChatStore()
    @State private var messageText = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            if store.visibleMessages.isEmpty {
                Text("No messages yet. Say hi to @\(otherUsername).")
                    .foregroundColor(.secondary)
                    .padding()
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(store.visibleMessages) { message in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(message.senderUsername).font(.footnote.bold())
                                Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Text(message.text)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(.horizontal)
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            HStack {
                TextField("Message @\(otherUsername)…", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Send") {
                    let text = messageText
                    messageText = ""
                    store.sendMessage(threadId: threadId, text: text,
                                      senderUsername: session.profile?.username ?? "") { error in
                        if let error { self.errorMessage = error }
                    }
                }
                .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("@\(otherUsername)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            store.startListeningMessages(threadId: threadId)
            store.startListeningBlocks()
        }
        .onDisappear {
            store.stopListening()
        }
    }
}
