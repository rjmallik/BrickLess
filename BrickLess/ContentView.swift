import SwiftUI

struct ContentView: View {
    @StateObject private var session = SessionStore()

    var body: some View {
        NavigationView {
            if session.isLoggedIn {
                if session.needsProfileSetup {
                    // Step 2 of account setup, before Home.
                    ProfileSetupView(session: session)
                        .navigationBarHidden(true)
                } else {
                    MainAppView(session: session)
                }
            } else {
                // The login form stays mounted while signing in:
                // LoginView shows its own inline spinner and disables
                // its button, so the typed email/password and the red
                // error message survive the attempt. The old code
                // swapped the whole form out for a bare spinner while
                // isLoading: that destroyed the typed credentials on
                // every attempt and hid the error label while signing
                // in, so a failed sign-in came back as an empty form
                // with no message.
                LoginView(session: session, errorMessage: $session.loginError)
                    .navigationBarHidden(true) // Hide navigation bar
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Use stack navigation style to handle navigation views correctly
    }
}



/// The main app screen: a bottom tab bar. Location is the map of
/// courts and fields (filtered by sport), Events is the games list,
/// Chats is the group chats for games the user joined, Friends is
/// My Guys / Add Friends, Profile is the signed-in user's profile.
struct MainAppView: View {
    @ObservedObject var session: SessionStore

    var body: some View {
        TabView {
            CourtMapView(session: session)
                .tabItem { Label("Location", systemImage: "map.fill") }
            EventsView(session: session)
                .tabItem { Label("Events", systemImage: "calendar") }
            ChatsView(session: session)
                .tabItem { Label("Chats", systemImage: "message") }
            FriendsView(session: session)
                .tabItem { Label("Friends", systemImage: "person.2") }
            ProfileView(session: session)
                .tabItem { Label("Profile", systemImage: "person.circle") }
        }
        .tint(PlayMatchColors.brand)
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
