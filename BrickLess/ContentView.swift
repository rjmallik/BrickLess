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
                VStack {
                    if session.isLoading {
                        // Signing in: a spinner only. The launch splash
                        // (LoadingView, in PlayMatchApp) must not be reused
                        // here: after 2s it opens a second ContentView with
                        // a second, empty SessionStore.
                        ProgressView("Signing you in…")
                            .padding()
                    } else {
                        // Show the LoginView. It displays session.loginError
                        // itself (via the errorMessage binding), so this
                        // view must not print it again underneath.
                        LoginView(session: session, errorMessage: $session.loginError)
                    }
                }
                .appBackground()
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
