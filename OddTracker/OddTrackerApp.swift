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

        // self.value = value is not possible here
        // this is because no property wrappers have been created before
        // so instead a property is wrapped in state by using `StateObject(wrappedValue:)`
        // the `_value = ...` is needed to assign property wrapper itself instead of assigning to the wrapped value
        _dataController = StateObject(wrappedValue: dataController)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(dataController)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification), perform: save)
        }
    }

    func save(_ notification: Notification) {
        dataController.save()
    }
}
