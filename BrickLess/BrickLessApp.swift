import SwiftUI
import Firebase

@main
struct PlayMatchApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        // App Check is not linked at all: the app never uses it, and
        // its DeviceCheck provider crashed at launch in the 10.x SDK
        // (FBLPromise expirationDate unrecognized selector in the
        // periodic token refresh), killing the CI test runs before any
        // test could start. Removing the framework from the target
        // keeps its code out of the app entirely.
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            // Start with LoadingView, not ContentView
            LoadingView() // No need to provide a duration
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
