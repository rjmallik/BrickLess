import SwiftUI

/// An open 1-to-1 chat: the thread plus who it is with. Drives the
/// hidden NavigationLink below, since this tab lives in a NavigationView.
private struct ActiveDirectChat: Identifiable {
    var id: String { threadId }
    let threadId: String
    let otherUid: String
    let otherUsername: String
}

/// Chats: direct messages with friends, then the group chats for games
/// the signed-in user joined, soonest first. Each group row opens the
/// game's detail, which already shows the group chat. Past games live in
/// History (Events tab), so the group list only shows games that have
/// not ended yet. "Start a chat" opens the friend picker (My Guys) and
/// starts a 1-to-1 chat with the friend picked.
struct ChatsView: View {
    @ObservedObject var session: SessionStore
    @StateObject private var store = EventStore()
    @StateObject private var chatStore = DirectChatStore()
    @State private var showingStartChat = false
    @State private var activeChat: ActiveDirectChat?

    /// Joined games that have not ended, soonest first.
    private var chats: [GameEvent] {
        EventStore.upcomingChats(store.myEvents, now: Date())
    }

    /// Direct threads with friends, most recent first, with blocked
    /// users hidden.
    private var directThreads: [DirectChatThread] {
        guard let myUid = chatStore.uid else { return [] }
        return DirectChatStore.visibleThreads(chatStore.threads, myUid: myUid,
                                              blockedUids: chatStore.blockedUids)
    }

    var body: some View {
        List {
            Section("Direct messages") {
                if directThreads.isEmpty {
                    Text("No direct messages yet. Start a chat with a friend.")
                        .foregroundColor(.secondary)
                }
                ForEach(directThreads) { thread in
                    if let myUid = chatStore.uid,
                       let otherUid = thread.otherUid(myUid: myUid),
                       let otherUsername = thread.otherUsername(myUid: myUid) {
                        Button {
                            activeChat = ActiveDirectChat(
                                threadId: DirectChatStore.threadId(for: myUid, otherUid),
                                otherUid: otherUid,
                                otherUsername: otherUsername)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("@\(otherUsername)").font(.headline)
                                if let preview = thread.lastMessageText {
                                    Text(preview)
                                        .font(.subheadline).foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
            }

            Section("Group chats") {
                if chats.isEmpty {
                    Text("No chats yet. Join a game to chat with the group.")
                        .foregroundColor(.secondary)
                }
                ForEach(chats) { event in
                    NavigationLink(destination: EventDetailView(event: event, session: session)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.title).font(.headline)
                            Text(event.courtName).font(.subheadline)
                            Text("\(event.startTime.formatted(date: .abbreviated, time: .shortened)) – \(event.endTime.formatted(date: .omitted, time: .shortened))")
                                .font(.subheadline).foregroundColor(.secondary)
                            Text(SportTabs.label(forTag: event.sport))
                                .font(.footnote).foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .appBackground()
        .navigationTitle("Chats")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingStartChat = true
                } label: {
                    Label("Start a chat", systemImage: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showingStartChat) {
            StartChatView { friend in
                showingStartChat = false
                startChat(with: friend)
            }
        }
        .background(
            NavigationLink(
                destination: Group {
                    if let chat = activeChat {
                        DirectChatView(threadId: chat.threadId, otherUid: chat.otherUid,
                                       otherUsername: chat.otherUsername, session: session)
                    }
                },
                isActive: Binding(
                    get: { activeChat != nil },
                    set: { if !$0 { activeChat = nil } }
                )
            ) { EmptyView() }
        )
        .onAppear {
            store.startListeningMyEvents()
            chatStore.startListeningThreads()
            chatStore.startListeningBlocks()
        }
        .onDisappear {
            store.stopListening()
            chatStore.stopListening()
        }
    }

    /// Opens the 1-to-1 chat with a friend, creating the thread first
    /// when the pair has never chatted.
    private func startChat(with friend: UserProfile) {
        guard let friendUid = friend.id else { return }
        chatStore.ensureThread(with: friend,
                               myUsername: session.profile?.username ?? "") { threadId in
            guard let threadId else { return }
            activeChat = ActiveDirectChat(threadId: threadId, otherUid: friendUid,
                                          otherUsername: friend.username)
        }
    }
}
