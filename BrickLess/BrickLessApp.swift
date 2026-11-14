import SwiftUI
import Firebase
import FirebaseAppCheck

@main
struct PlayMatchApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        // App Check is not used by the app, and its default DeviceCheck
        // provider crashes at launch in the 10.x SDK (FBLPromise
        // expirationDate unrecognized selector in the periodic token
        // refresh). Disable it before configuring Firebase.
        AppCheck.setAppCheckProviderFactory(nil)
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
