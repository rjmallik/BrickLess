import SwiftUI

@main
struct BrickLessApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            // Start with LoadingView, not ContentView
            LoadingView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
