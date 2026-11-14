import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

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

    /// A game is done once its end time has passed. Derived from
    /// endTime only — there is no status field to drift out of sync.
    /// A finished game lives in History and nowhere else.
    var isEnded: Bool { endTime <= Date() }

    func hasPlayer(_ uid: String) -> Bool { playerUids.contains(uid) }

    /// Join decision for one user against this snapshot. The check is
    /// snapshot-based: two users deciding against the same snapshot can
    /// both see an open last spot, which is why the Firestore rules
    /// also cap playerUids at maxPlayers.
    enum JoinStatus: Equatable {
        case alreadyJoined
        case full
        case canJoin
    }

    func joinStatus(for uid: String) -> JoinStatus {
        if hasPlayer(uid) { return .alreadyJoined }
        if isFull { return .full }
        return .canJoin
    }
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

    /// The create-event field checks, in the order createEvent reports
    /// them. Pure: callers pass the already-trimmed title and court
    /// name, and `now` is injected so tests can pin it. A game needs
    /// 2-30 players, matching the setup stepper.
    static func validateEvent(title: String, courtName: String, start: Date, end: Date,
                              maxPlayers: Int, now: Date) -> String? {
        guard !title.isEmpty else { return "Give the game a title." }
        guard !courtName.isEmpty else { return "Pick a court or type a court name." }
        guard end > start else { return "End time must be after the start time." }
        guard start > now else { return "Pick a time in the future." }
        guard maxPlayers >= 2 else { return "A game needs at least 2 players." }
        guard maxPlayers <= 30 else { return "A game can have at most 30 players." }
        return nil
    }

    /// Chat is visible only to players joined to this event.
    static func canViewChat(event: GameEvent, uid: String) -> Bool {
        event.hasPlayer(uid)
    }

    /// Chat messages with blocked senders removed, in order.
    static func filterVisibleMessages(_ messages: [EventMessage], blockedUids: Set<String>) -> [EventMessage] {
        messages.filter { !blockedUids.contains($0.senderUid) }
    }

    /// Future events, soonest first. Pure version of the upcoming
    /// listener's filter + sort, so the ordering rule is unit-tested.
    static func upcomingEvents(_ events: [GameEvent], now: Date) -> [GameEvent] {
        events.filter { $0.startTime > now }.sorted { $0.startTime < $1.startTime }
    }

    /// Games that have ended, most recently ended first. Pure version
    /// of the History list's filter + sort, so the rule is unit-tested.
    /// History is built from the signed-in user's own games (myEvents),
    /// so callers pass that list, not every event: a finished game
    /// appears only in History, never in Upcoming or My games.
    static func pastEvents(_ events: [GameEvent], now: Date) -> [GameEvent] {
        events.filter { $0.endTime <= now }.sorted { $0.endTime > $1.endTime }
    }

    /// Max writes in one Firestore batch. Deleting a game's chat has
    /// to stay under it, so big chats are deleted in batches of this
    /// size (see deleteEvent).
    static let maxBatchWrites = 500

    /// Splits message document IDs into batches of at most
    /// `maxBatchWrites`, in order. Pure, so the chunking rule is
    /// unit-tested without touching Firestore.
    static func messageDeletionBatches(_ messageIds: [String]) -> [[String]] {
        guard !messageIds.isEmpty else { return [] }
        return stride(from: 0, to: messageIds.count, by: maxBatchWrites)
            .map { Array(messageIds[$0..<min($0 + maxBatchWrites, messageIds.count)]) }
    }

    /// One step of deleting a game. Message batches always come before
    /// the event doc: the messages rule only lets the creator delete
    /// while the parent event still exists, so the chat has to go first.
    enum GameDeletionStep: Equatable {
        case deleteMessageBatch(batchIndex: Int)
        case deleteEventDocument
    }

    /// The steps of deleting a game, in order: one step per batch of
    /// chat messages, then the event doc itself. Pure description of
    /// the flow deleteEvent runs, so the ordering rule is unit-tested.
    static func deletionSteps(messageCount: Int) -> [GameDeletionStep] {
        let batchCount = (messageCount + maxBatchWrites - 1) / maxBatchWrites
        return (0..<batchCount).map { .deleteMessageBatch(batchIndex: $0) }
            + [.deleteEventDocument]
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
                    let decoded = snapshot?.documents.compactMap {
                        try? $0.data(as: GameEvent.self)
                    } ?? []
                    self?.upcomingEvents = Self.upcomingEvents(decoded, now: now)
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
        Self.filterVisibleMessages(messages, blockedUids: blockedUids)
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
        if let error = Self.validateEvent(title: title, courtName: courtName, start: start, end: end,
                                          maxPlayers: maxPlayers, now: Date()) {
            completion(error)
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
            switch current.joinStatus(for: uid) {
            case .alreadyJoined:
                completion(nil)
                return
            case .full:
                completion("That game is full.")
                return
            case .canJoin:
                break
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

    /// Only the creator can delete (enforced in the rules too). The
    /// chat messages go first, in batches of at most 500 (the
    /// Firestore batch limit), then the event doc: deleting the event
    /// alone used to orphan the chat, leaving messages readable only
    /// by players of a game that no longer exists. The messages rule
    /// only lets the creator delete while the parent event still
    /// exists, so the order matters. If any step fails, completion
    /// fires once with a friendly error and the event doc is left
    /// in place (a failed message batch stops the delete entirely).
    func deleteEvent(_ event: GameEvent, completion: @escaping (String?) -> Void) {
        guard let id = event.id else {
            completion("That game no longer exists.")
            return
        }
        deleteMessages(eventId: id) { [weak self] error in
            guard let self else { return }
            if let error {
                completion(SessionStore.friendlyError(error))
                return
            }
            self.db.collection("events").document(id).delete { error in
                completion(error.map(SessionStore.friendlyError))
            }
        }
    }

    /// Deletes every message in `events/{eventId}/messages`, one batch
    /// at a time. Each round fetches up to `maxBatchWrites` messages
    /// and deletes them in a single batch, then repeats until a fetch
    /// comes back empty — so a chat of any size is fully deleted, and
    /// a message posted mid-delete is caught by the next round instead
    /// of being orphaned. Completion fires exactly once, with the first
    /// error if any step fails. Static so Delete Account can reuse it
    /// when it deletes a creator's events (LoginSession).
    static func deleteAllMessages(db: Firestore, eventId: String, completion: @escaping (Error?) -> Void) {
        db.collection("events").document(eventId).collection("messages")
            .limit(to: Self.maxBatchWrites)
            .getDocuments { snapshot, error in
                if let error {
                    completion(error)
                    return
                }
                let docs = snapshot?.documents ?? []
                guard !docs.isEmpty else {
                    completion(nil)
                    return
                }
                let batch = db.batch()
                docs.forEach { batch.deleteDocument($0.reference) }
                batch.commit { error in
                    if let error {
                        completion(error)
                        return
                    }
                    Self.deleteAllMessages(db: db, eventId: eventId, completion: completion)
                }
            }
    }

    private func deleteMessages(eventId: String, completion: @escaping (Error?) -> Void) {
        Self.deleteAllMessages(db: db, eventId: eventId, completion: completion)
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
        guard Self.canViewChat(event: event, uid: uid) else {
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
