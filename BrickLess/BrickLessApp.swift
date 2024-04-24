import SwiftUI
import Firebase

@main
struct BrickLessApp: App {
    let persistenceController = PersistenceController.shared

    init() {
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
