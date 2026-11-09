import SwiftUI

/// One game: details, who joined, Join/Leave, and the group chat.
/// The chat is only visible to players who joined the game.
struct EventDetailView: View {
    var event: GameEvent
    @ObservedObject var session: SessionStore
    @StateObject private var store = EventStore()
    @State private var players: [UserProfile] = []
    @State private var messageText = ""
    @State private var errorMessage: String?
    @State private var showingDeleteConfirm = false

    private var uid: String? { session.firebaseUser?.uid }

    /// The live event doc when the listener has it, else the passed-in copy.
    private var liveEvent: GameEvent { store.currentEvent ?? event }

    private var isPlayer: Bool {
        guard let uid else { return false }
        return liveEvent.hasPlayer(uid)
    }

    private var isCreator: Bool {
        guard let uid else { return false }
        return liveEvent.creatorUid == uid
    }

    /// Joined players, with blocked users hidden like everywhere else.
    private var visiblePlayers: [UserProfile] {
        players.filter { !(store.blockedUids.contains($0.id ?? "")) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(liveEvent.title).font(.title2.bold())
                Text(liveEvent.courtName).font(.headline)
                Text("\(liveEvent.startTime.formatted(date: .abbreviated, time: .shortened)) – \(liveEvent.endTime.formatted(date: .omitted, time: .shortened))")
                    .foregroundColor(.secondary)
                if !liveEvent.description.isEmpty {
                    Text(liveEvent.description)
                }
                Text("Hosted by \(liveEvent.creatorUsername)")
                    .font(.footnote).foregroundColor(.secondary)

                // Join / Leave
                if isPlayer {
                    Button("Leave game") {
                        errorMessage = nil
                        store.leaveEvent(liveEvent) { error in
                            if let error { errorMessage = error }
                        }
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.red.opacity(0.1)).cornerRadius(8)
                } else if liveEvent.isFull {
                    Text("This game is full.")
                        .foregroundColor(.secondary)
                } else {
                    Button("Join game") {
                        errorMessage = nil
                        store.joinEvent(liveEvent) { error in
                            if let error { errorMessage = error }
                        }
                    }
                    .foregroundColor(.white).frame(maxWidth: .infinity).padding()
                    .background(Color.blue).cornerRadius(8)
                }

                if let errorMessage {
                    Text(errorMessage).foregroundColor(.red)
                }

                // Players
                Text("Players (\(liveEvent.playerUids.count)/\(liveEvent.maxPlayers))")
                    .font(.headline)
                if visiblePlayers.isEmpty {
                    Text("No players yet.").foregroundColor(.secondary)
                } else {
                    ForEach(visiblePlayers) { player in
                        HStack {
                            Text(player.displayName)
                            Text("@\(player.username)")
                                .foregroundColor(.secondary).font(.footnote)
                            if player.id == liveEvent.creatorUid {
                                Text("Host")
                                    .font(.caption)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.15))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }

                // Group chat: joined players only.
                Text("Group chat").font(.headline)
                if isPlayer {
                    if store.visibleMessages.isEmpty {
                        Text("No messages yet. Say hi to the group.")
                            .foregroundColor(.secondary)
                    }
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
                    HStack {
                        TextField("Message the group…", text: $messageText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("Send") {
                            let text = messageText
                            messageText = ""
                            store.sendMessage(event: liveEvent, text: text,
                                              senderUsername: session.profile?.username ?? "") { error in
                                if let error { errorMessage = error }
                            }
                        }
                        .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } else {
                    Text("Join the game to see the group chat and text the other players.")
                        .foregroundColor(.secondary)
                }

                if isCreator {
                    Button("Delete this game", role: .destructive) {
                        showingDeleteConfirm = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                }
            }
            .padding()
        }
        .navigationTitle("Game")
        .confirmationDialog("Delete this game?", isPresented: $showingDeleteConfirm,
                            titleVisibility: .visible) {
            Button("Delete game", role: .destructive) {
                store.deleteEvent(liveEvent) { error in
                    if let error { errorMessage = error }
                }
            }
            Button("Keep it", role: .cancel) {}
        }
        .onAppear {
            guard let id = event.id else { return }
            store.startListeningEvent(eventId: id)
            // The chat listener only starts for a joined player: the
            // rules deny the read otherwise, and it would stay dead
            // after joining. The onChange below starts it on join.
            if let uid, event.hasPlayer(uid) {
                store.startListeningMessages(eventId: id)
            }
            store.startListeningBlocks()
            refreshPlayers()
        }
        .onChange(of: store.currentEvent?.playerUids) {
            refreshPlayers()
            if let id = event.id, isPlayer {
                store.startListeningMessages(eventId: id)
            }
        }
        .onDisappear {
            store.stopListening()
        }
    }

    private func refreshPlayers() {
        store.fetchPlayerProfiles(for: liveEvent) { players = $0 }
    }
}
