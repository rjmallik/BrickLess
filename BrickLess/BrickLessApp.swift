//
//  BrickLessApp.swift
//  BrickLess
//
//  Created by Rutujit Mallikarjuna on 4/21/24.
//

import SwiftUI

@main
struct BrickLessApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
