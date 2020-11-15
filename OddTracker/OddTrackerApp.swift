//
//  OddTrackerApp.swift
//  OddTracker
//
//  Created by Michael Brünen on 15.11.20.
//

import SwiftUI

@main
struct OddTrackerApp: App {
    @StateObject var dataController: DataController

    init() {
        let dataController = DataController()
        _dataController = StateObject(wrappedValue: dataController)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(dataController)
        }
    }
}
