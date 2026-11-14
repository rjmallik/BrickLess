import SwiftUI

/// Friend picker for starting a direct chat: the user's My Guys list.
/// Tapping a friend hands them to the caller, which opens the 1-to-1
/// chat. With no friends yet, it says so and points to the Friends tab
/// to add some.
struct StartChatView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var friendsStore = FriendsStore()
    var onPick: (UserProfile) -> Void

    private var friends: [UserProfile] {
        DirectChatStore.pickerFriends(friendsStore.friends, myUid: friendsStore.uid,
                                      blockedUids: friendsStore.blockedUids)
    }

    var body: some View {
        NavigationView {
            Group {
                if friends.isEmpty {
                    VStack(spacing: 12) {
                        Text("No friends yet.")
                            .font(.headline)
                        Text("Add friends from the Friends tab, then come back here to start chatting.")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List(friends) { friend in
                        Button {
                            onPick(friend)
                        } label: {
                            HStack {
                                ProfileAvatarView(displayName: friend.displayName,
                                                  photoURL: friend.photoURL, size: 40)
                                VStack(alignment: .leading) {
                                    Text(friend.displayName).font(.headline)
                                    Text("@\(friend.username) · \(friend.position)")
                                        .font(.subheadline).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .appBackground()
            .navigationTitle("Start a chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                friendsStore.startListening()
            }
        }
    }
}
