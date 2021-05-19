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
    @StateObject var unlockManager: UnlockManager

    init() {
        let dataController = DataController()
        let unlockManager = UnlockManager(dataController: dataController)

        // self.value = value is not possible here
        // this is because no property wrappers have been created before
        // so instead a property is wrapped in state by using `StateObject(wrappedValue:)`
        // the `_value = ...` is needed to assign property wrapper itself instead of assigning to the wrapped value
        _dataController = StateObject(wrappedValue: dataController)
        _unlockManager = StateObject(wrappedValue: unlockManager)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(dataController)
                .environmentObject(unlockManager)
                .onReceive(
                    // Automatically save when the app is no longer in the foreground app
                    // `onReceive` is used over `onChange(of: scenePhase`,
                    // so the app can be ported to macOS as well
                    // since scene phase won't detect the app losing focus there
                    NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification),
                    perform: save
                )
                .onAppear(perform: dataController.appLaunched)
        }
    }

    func save(_ notification: Notification) {
        dataController.save()
    }
}
