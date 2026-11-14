import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

/// A 1-to-1 direct chat between two friends, stored in Firestore.
///
/// `directChats/{threadId}`: { participantUids: [uid, uid] (sorted),
/// participantUsernames: { uid: username }, lastMessageText, lastMessageAt,
/// createdAt }.
/// `directChats/{threadId}/messages/{msgId}`: { senderUid, senderUsername,
/// text, createdAt }.
///
/// The thread id is deterministic: the two participant UIDs, sorted and
/// joined with "_", so whichever friend starts the chat lands in the same
/// thread and the pair can never have two threads. Auth UIDs never contain
/// "_", so the join is unambiguous. The thread doc holds only UIDs,
/// usernames and the last-message preview: no emails or phone numbers,
/// per the privacy rule. Messages are visible only to the two
/// participants (firestore.rules), unlike game group chats, which are
/// visible to every joined player (see EventStore).
struct DirectChatThread: Codable, Identifiable {
    @DocumentID var id: String?
    var participantUids: [String] // sorted, exactly 2
    var participantUsernames: [String: String] // uid -> username
    var lastMessageText: String?
    var lastMessageAt: Date?
    var createdAt: Date

    /// The other participant's uid, from this user's side.
    func otherUid(myUid: String) -> String? {
        participantUids.first { $0 != myUid }
    }

    /// The other participant's username, from this user's side.
    func otherUsername(myUid: String) -> String? {
        guard let other = otherUid(myUid: myUid) else { return nil }
        return participantUsernames[other]
    }
}

/// One message in a direct chat. Same shape as EventMessage, its own
/// type so the group-chat and direct-chat paths stay separate.
struct DirectChatMessage: Codable, Identifiable {
    @DocumentID var id: String?
    var senderUid: String
    var senderUsername: String
    var text: String
    var createdAt: Date
}

class DirectChatStore: ObservableObject {
    @Published var threads: [DirectChatThread] = []
    @Published var messages: [DirectChatMessage] = []
    @Published var blockedUids: Set<String> = []
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    /// Thread id the message listener is running for, if any. The
    /// listener must not start twice for one thread.
    private var messagesThreadId: String?

    var uid: String? { Auth.auth().currentUser?.uid }

    deinit { listeners.forEach { $0.remove() } }

    func stopListening() {
        listeners.forEach { $0.remove() }
        listeners = []
        messagesThreadId = nil
    }

    // MARK: - Pure logic

    /// The thread id for a pair of users: their UIDs sorted, joined with
    /// "_". Order-independent, so either friend starting the chat lands
    /// in the same thread and the pair can never have duplicates.
    static func threadId(for uidA: String, _ uidB: String) -> String {
        [uidA, uidB].sorted().joined(separator: "_")
    }

    /// The participant list for a new thread: the two UIDs, sorted.
    static func participantUids(myUid: String, friendUid: String) -> [String] {
        [myUid, friendUid].sorted()
    }

    /// A thread is visible only to its two participants.
    static func canViewThread(_ thread: DirectChatThread, uid: String) -> Bool {
        thread.participantUids.contains(uid)
    }

    /// Threads most recent first, by last message. A thread with no
    /// messages yet sorts by when it was created: lastMessageAt is set
    /// to the creation time when the thread is made.
    static func sortedThreads(_ threads: [DirectChatThread]) -> [DirectChatThread] {
        threads.sorted { ($0.lastMessageAt ?? .distantPast) > ($1.lastMessageAt ?? .distantPast) }
    }

    /// The threads shown in the Chats tab: threads with a blocked other
    /// participant are hidden, most recent first.
    static func visibleThreads(_ threads: [DirectChatThread], myUid: String,
                               blockedUids: Set<String>) -> [DirectChatThread] {
        sortedThreads(threads).filter { thread in
            guard let other = thread.otherUid(myUid: myUid) else { return false }
            return !blockedUids.contains(other)
        }
    }

    /// The friend picker list: friends sorted by username, with blocked
    /// users removed. The signed-in user is never in their own list.
    static func pickerFriends(_ friends: [UserProfile], myUid: String?,
                              blockedUids: Set<String>) -> [UserProfile] {
        friends.filter { $0.id != myUid && !blockedUids.contains($0.id ?? "") }
            .sorted { $0.usernameLower < $1.usernameLower }
    }

    /// A message's sendable text: trimmed, nil when blank.
    static func trimmedMessageText(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Chat messages with blocked senders removed, in order.
    static func filterVisibleMessages(_ messages: [DirectChatMessage],
                                      blockedUids: Set<String>) -> [DirectChatMessage] {
        messages.filter { !blockedUids.contains($0.senderUid) }
    }

    /// Chat messages with blocked senders removed.
    var visibleMessages: [DirectChatMessage] {
        Self.filterVisibleMessages(messages, blockedUids: blockedUids)
    }

    // MARK: - Firestore

    /// Live list of the signed-in user's direct threads. Sorted
    /// client-side (sortedThreads) so no composite index is needed.
    func startListeningThreads() {
        guard let uid else { return }
        listeners.append(
            db.collection("directChats")
                .whereField("participantUids", arrayContains: uid)
                .addSnapshotListener { [weak self] snapshot, _ in
                    self?.threads = snapshot?.documents.compactMap {
                        try? $0.data(as: DirectChatThread.self)
                    } ?? []
                }
        )
    }

    /// Live messages for one thread, oldest first. No-op when the
    /// listener is already running for this thread, so re-entering the
    /// chat view does not stack listeners.
    func startListeningMessages(threadId: String) {
        guard messagesThreadId != threadId else { return }
        messagesThreadId = threadId
        listeners.append(
            db.collection("directChats").document(threadId).collection("messages")
                .order(by: "createdAt")
                .addSnapshotListener { [weak self] snapshot, _ in
                    self?.messages = snapshot?.documents.compactMap {
                        try? $0.data(as: DirectChatMessage.self)
                    } ?? []
                }
        )
    }

    /// Blocked users, like FriendsStore and EventStore: their messages
    /// are hidden, and their threads are hidden from the Chats tab.
    func startListeningBlocks() {
        guard let uid else { return }
        listeners.append(
            db.collection("blocks").document(uid).collection("blocked")
                .addSnapshotListener { [weak self] snapshot, _ in
                    self?.blockedUids = Set(snapshot?.documents.map { $0.documentID } ?? [])
                }
        )
    }

    /// Creates the thread for a pair if it does not exist yet, then calls
    /// completion with the thread id. The thread is only written when it
    /// is missing, so an existing thread's last-message preview is never
    /// clobbered. Two friends creating at the same moment both write the
    /// same deterministic doc, so they still land in one thread.
    func ensureThread(with friend: UserProfile, myUsername: String,
                      completion: @escaping (String?) -> Void) {
        guard let uid, let friendUid = friend.id else {
            completion(nil)
            return
        }
        let threadId = Self.threadId(for: uid, friendUid)
        let ref = db.collection("directChats").document(threadId)
        ref.getDocument { [weak self] snapshot, _ in
            guard self != nil else {
                completion(nil)
                return
            }
            if snapshot?.exists == true {
                completion(threadId)
                return
            }
            let thread = DirectChatThread(
                participantUids: Self.participantUids(myUid: uid, friendUid: friendUid),
                participantUsernames: [uid: myUsername, friendUid: friend.username],
                lastMessageText: nil,
                lastMessageAt: Date(),
                createdAt: Date()
            )
            do {
                try ref.setData(from: thread) { error in
                    completion(error == nil ? threadId : nil)
                }
            } catch {
                completion(nil)
            }
        }
    }

    /// Sends a message in a thread, then updates the thread's preview so
    /// the Chats tab shows the latest message. Only a participant can
    /// send; the rules enforce it too.
    func sendMessage(threadId: String, text: String, senderUsername: String,
                     completion: @escaping (String?) -> Void) {
        guard let uid else {
            completion("You are not signed in.")
            return
        }
        guard let text = Self.trimmedMessageText(text) else { return }
        let message = DirectChatMessage(senderUid: uid, senderUsername: senderUsername,
                                        text: text, createdAt: Date())
        do {
            _ = try db.collection("directChats").document(threadId).collection("messages")
                .addDocument(from: message)
            db.collection("directChats").document(threadId).updateData([
                "lastMessageText": text,
                "lastMessageAt": Date(),
            ])
            completion(nil)
        } catch {
            completion(error.localizedDescription)
        }
    }
}
