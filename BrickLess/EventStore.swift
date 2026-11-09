import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

/// A pickup game posted at a court, stored in Firestore.
///
/// `events/{id}`: { courtId, courtName, creatorUid, creatorUsername,
/// title, startTime, endTime, maxPlayers, playerUids, description,
/// createdAt }.
///
/// Events are NOT facility reservations: they do not block the court and
/// overlapping events at the same court are fine. They exist so a group
/// can form around a time and place, then coordinate in the group chat.
/// Messages live in `events/{eventId}/messages/{msgId}`.
struct GameEvent: Codable, Identifiable {
    @DocumentID var id: String?
    var courtId: String
    var courtName: String
    var creatorUid: String
    var creatorUsername: String
    var title: String
    var startTime: Date
    var endTime: Date
    var maxPlayers: Int
    var playerUids: [String]
    var description: String
    var createdAt: Date

    var isFull: Bool { playerUids.count >= maxPlayers }

    func hasPlayer(_ uid: String) -> Bool { playerUids.contains(uid) }
}

/// One message in an event's group chat.
struct EventMessage: Codable, Identifiable {
    @DocumentID var id: String?
    var senderUid: String
    var senderUsername: String
    var text: String
    var createdAt: Date
}

class EventStore: ObservableObject {
    @Published var upcomingEvents: [GameEvent] = []
    @Published var myEvents: [GameEvent] = []
    @Published var currentEvent: GameEvent?
    @Published var messages: [EventMessage] = []
    @Published var blockedUids: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    /// Event id the chat listener is running for, if any. The chat
    /// listener must not start twice for one event, and must not start
    /// at all for a non-player (the rules would deny the read).
    private var messagesEventId: String?

    var uid: String? { Auth.auth().currentUser?.uid }

    deinit { listeners.forEach { $0.remove() } }

    func stopListening() {
        listeners.forEach { $0.remove() }
        listeners = []
        messagesEventId = nil
    }

    /// Live list of future events, soonest first, capped at 50.
    func startListeningUpcoming() {
        listeners.append(
            db.collection("events")
                .whereField("startTime", isGreaterThan: Date())
                .order(by: "startTime")
                .limit(to: 50)
                .addSnapshotListener { [weak self] snapshot, _ in
                    let now = Date()
                    self?.upcomingEvents = snapshot?.documents.compactMap {
                        try? $0.data(as: GameEvent.self)
                    }.filter { $0.startTime > now } ?? []
                }
        )
    }

    /// Live list of events the signed-in user joined.
    func startListeningMyEvents() {
        guard let uid else { return }
        listeners.append(
            db.collection("events")
                .whereField("playerUids", arrayContains: uid)
                .order(by: "startTime")
                .addSnapshotListener { [weak self] snapshot, _ in
                    self?.myEvents = snapshot?.documents.compactMap {
                        try? $0.data(as: GameEvent.self)
                    } ?? []
                }
        )
    }

    /// Live updates for one event, so the player list and Join/Leave
    /// state stay current while the detail view is open.
    func startListeningEvent(eventId: String) {
        listeners.append(
            db.collection("events").document(eventId)
                .addSnapshotListener { [weak self] snapshot, _ in
                    guard let snapshot, snapshot.exists else { return }
                    self?.currentEvent = try? snapshot.data(as: GameEvent.self)
                }
        )
    }

    /// Live group chat for one event, oldest first. No-op when the
    /// listener is already running for this event, so joining from the
    /// detail view (which re-triggers it) does not stack listeners.
    func startListeningMessages(eventId: String) {
        guard messagesEventId != eventId else { return }
        messagesEventId = eventId
        listeners.append(
            db.collection("events").document(eventId).collection("messages")
                .order(by: "createdAt")
                .addSnapshotListener { [weak self] snapshot, _ in
                    self?.messages = snapshot?.documents.compactMap {
                        try? $0.data(as: EventMessage.self)
                    } ?? []
                }
        )
    }

    /// Blocked users, like FriendsStore: their chat messages are hidden.
    func startListeningBlocks() {
        guard let uid else { return }
        listeners.append(
            db.collection("blocks").document(uid).collection("blocked")
                .addSnapshotListener { [weak self] snapshot, _ in
                    self?.blockedUids = Set(snapshot?.documents.map { $0.documentID } ?? [])
                }
        )
    }

    /// Chat messages with blocked senders removed.
    var visibleMessages: [EventMessage] {
        messages.filter { !blockedUids.contains($0.senderUid) }
    }

    // MARK: - Create / join / leave / delete

    /// Posts a game. Anyone signed in can post one at any court; the
    /// creator is automatically the first player.
    func createEvent(court: Court?, courtName: String, title: String,
                     start: Date, end: Date, maxPlayers: Int, description: String,
                     creatorUsername: String, completion: @escaping (String?) -> Void) {
        guard let uid else {
            completion("You are not signed in.")
            return
        }
        let title = title.trimmingCharacters(in: .whitespaces)
        let courtName = court?.name ?? courtName.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else {
            completion("Give the game a title.")
            return
        }
        guard !courtName.isEmpty else {
            completion("Pick a court or type a court name.")
            return
        }
        guard end > start else {
            completion("End time must be after the start time.")
            return
        }
        guard start > Date() else {
            completion("Pick a time in the future.")
            return
        }
        guard maxPlayers >= 2 else {
            completion("A game needs at least 2 players.")
            return
        }

        let event = GameEvent(
            courtId: court?.id ?? "custom",
            courtName: courtName,
            creatorUid: uid,
            creatorUsername: creatorUsername,
            title: title,
            startTime: start, endTime: end,
            maxPlayers: maxPlayers,
            playerUids: [uid],
            description: description.trimmingCharacters(in: .whitespaces),
            createdAt: Date()
        )
        do {
            _ = try db.collection("events").addDocument(from: event)
            completion(nil)
        } catch {
            completion(error.localizedDescription)
        }
    }

    /// Joins an event. The player cap is checked on the latest doc first;
    /// two people grabbing the last spot at the exact same second can both
    /// get through, the same known race as the booking overlap check.
    /// Rare, fine for v1; the rules also cap playerUids at maxPlayers.
    func joinEvent(_ event: GameEvent, completion: @escaping (String?) -> Void) {
        guard let uid, let id = event.id else {
            completion("You are not signed in.")
            return
        }
        db.collection("events").document(id).getDocument { [weak self] snapshot, _ in
            guard let self else { return }
            guard let snapshot, let current = try? snapshot.data(as: GameEvent.self) else {
                completion("That game no longer exists.")
                return
            }
            guard !current.hasPlayer(uid) else {
                completion(nil)
                return
            }
            guard !current.isFull else {
                completion("That game is full.")
                return
            }
            self.db.collection("events").document(id).updateData([
                "playerUids": FieldValue.arrayUnion([uid])
            ]) { error in
                completion(error.map(SessionStore.friendlyError))
            }
        }
    }

    func leaveEvent(_ event: GameEvent, completion: @escaping (String?) -> Void) {
        guard let uid, let id = event.id else {
            completion("You are not signed in.")
            return
        }
        db.collection("events").document(id).updateData([
            "playerUids": FieldValue.arrayRemove([uid])
        ]) { error in
            completion(error.map(SessionStore.friendlyError))
        }
    }

    /// Only the creator can delete (enforced in the rules too). The chat
    /// messages under the event are left behind; they are only readable
    /// by players of an event that no longer exists.
    func deleteEvent(_ event: GameEvent, completion: @escaping (String?) -> Void) {
        guard let id = event.id else {
            completion("That game no longer exists.")
            return
        }
        db.collection("events").document(id).delete { error in
            completion(error.map(SessionStore.friendlyError))
        }
    }

    // MARK: - Players and chat

    /// Resolves the joined UIDs to profiles, for the players list.
    func fetchPlayerProfiles(for event: GameEvent,
                             completion: @escaping ([UserProfile]) -> Void) {
        let uids = Array(event.playerUids.prefix(30))
        guard !uids.isEmpty else {
            completion([])
            return
        }
        db.collection("users").whereField(FieldPath.documentID(), in: uids)
            .getDocuments { snapshot, _ in
                let profiles = snapshot?.documents.compactMap {
                    try? $0.data(as: UserProfile.self)
                } ?? []
                completion(profiles.sorted { $0.usernameLower < $1.usernameLower })
            }
    }

    /// Sends a chat message. Only joined players can send; the view hides
    /// the chat entirely from non-players, and the rules enforce it too.
    func sendMessage(event: GameEvent, text: String, senderUsername: String,
                     completion: @escaping (String?) -> Void) {
        guard let uid, let id = event.id else {
            completion("You are not signed in.")
            return
        }
        let text = text.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        guard event.hasPlayer(uid) else {
            completion("Join the game to chat with the group.")
            return
        }
        let message = EventMessage(senderUid: uid, senderUsername: senderUsername,
                                   text: text, createdAt: Date())
        do {
            _ = try db.collection("events").document(id).collection("messages")
                .addDocument(from: message)
            completion(nil)
        } catch {
            completion(error.localizedDescription)
        }
    }
}
