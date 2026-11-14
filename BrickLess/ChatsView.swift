import SwiftUI

/// Chats: the group chats for games the signed-in user joined, soonest
/// first. Each row opens the game's detail, which already shows the
/// group chat. Past games live in History (Events tab), so this list
/// only shows games that have not ended yet.
struct ChatsView: View {
    @ObservedObject var session: SessionStore
    @StateObject private var store = EventStore()

    /// Joined games that have not ended, soonest first.
    private var chats: [GameEvent] {
        EventStore.upcomingChats(store.myEvents, now: Date())
    }

    var body: some View {
        List {
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
        .scrollContentBackground(.hidden)
        .appBackground()
        .navigationTitle("Chats")
        .onAppear {
            store.startListeningMyEvents()
        }
        .onDisappear {
            store.stopListening()
        }
    }
}
