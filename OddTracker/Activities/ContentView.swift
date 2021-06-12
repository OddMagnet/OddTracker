//
//  ContentView.swift
//  OddTracker
//
//  Created by Michael Brünen on 15.11.20.
//

import SwiftUI
import CoreSpotlight

struct ContentView: View {
    @SceneStorage("selectedView") var selectedView: String?
    @EnvironmentObject var dataController: DataController

    private let newProjectActivity = "io.github.oddmagnet.newProject"

    var body: some View {
        TabView(selection: $selectedView) {
            HomeView(dataController: dataController)
                .tag(HomeView.tag)
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }

            ProjectsView(dataController: dataController, showClosedProjects: false)
                .tag(ProjectsView.openTag)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Open")
                }

            ProjectsView(dataController: dataController, showClosedProjects: true)
                .tag(ProjectsView.closedTag)
                .tabItem {
                    Image(systemName: "checkmark")
                    Text("Closed")
                }

            AwardsView()
                .tag(AwardsView.tag)
                .tabItem {
                    Image(systemName: "rosette")
                    Text("Awards")
                }
        }
        .onContinueUserActivity(CSSearchableItemActionType, perform: moveToHome)
        .onContinueUserActivity(newProjectActivity, perform: createProject)
        .userActivity(newProjectActivity) { activity in
            activity.isEligibleForPrediction = true
            activity.title = "New Project"
        }
        .onOpenURL(perform: openURL)
    }

    /// Changes the selected view to the HomeView, used for when the app is opened via spotlight
    func moveToHome(_ input: Any) {
        // currently only one possible input from spotlight, so no checks on it yet
        selectedView = HomeView.tag
    }

    /// Opens a url from a quick action
    /// - Parameter url: The url to open
    func openURL(_ url: URL) {
        // currently only one url, so no need to check it yet
        selectedView = ProjectsView.openTag
        _ = dataController.addProject()
    }

    /// Creates a new project when the app receives the corresponding user activity
    /// - Parameter userActivity: The user activity that was received
    func createProject(_ userActivity: NSUserActivity) {
        selectedView = ProjectsView.openTag
        dataController.addProject()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var dataController = DataController.preview

    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, dataController.container.viewContext)
            .environmentObject(dataController)
    }
}
