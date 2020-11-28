//
//  HomeView.swift
//  OddTracker
//
//  Created by Michael Brünen on 16.11.20.
//

import SwiftUI

struct HomeView: View {
    // Tag for the TabView in `ContentView.swift`
    static let tag: String? = "Home"
    
    @EnvironmentObject var dataController: DataController

    var body: some View {
        NavigationView {
            VStack {
                Button("Add Data") {
                    dataController.deleteAll()
                    try? dataController.createSampleDate()
                }
            }
            .navigationTitle("Home")
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
