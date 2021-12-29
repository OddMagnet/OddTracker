//
//  SharedProjectsView.swift
//  OddTracker
//
//  Created by Michael Brünen on 29.12.21.
//

import SwiftUI
import CloudKit

struct SharedProjectsView: View {
    static let tag: String? = "Community"

    @State private var projects = [SharedProject]()
    @State private var loadState = LoadState.inactive

    var body: some View {
        NavigationView {
            Group {
                switch loadState {
                    case .inactive, .loading:
                        ProgressView()
                    case .noResults:
                        Text("No Results")
                    case .success:
                        List(projects) { project in
                            NavigationLink(destination: Color.blue) {
                                VStack(alignment: .leading) {
                                    Text(project.title)
                                        .font(.headline)
                                    Text(project.owner)
                                }
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Shared Projekts")
        }
        .onAppear(perform: fetchSharedProjects)
    }
}

func fetchSharedProjects() {
    
}

struct SharedProjectsView_Previews: PreviewProvider {
    static var previews: some View {
        SharedProjectsView()
    }
}
