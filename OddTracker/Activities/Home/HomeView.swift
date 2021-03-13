//
//  HomeView.swift
//  OddTracker
//
//  Created by Michael Brünen on 16.11.20.
//

import SwiftUI
import CoreData

/// A View that shows Home Screen
struct HomeView: View {
    // Tag for the TabView in `ContentView.swift`
    static let tag: String? = "Home"

    @StateObject var viewModel: ViewModel

    var projectRows: [GridItem] {
        [GridItem(.fixed(100))]
    }

    init(dataController: DataController) {
        let viewModel = ViewModel(dataController: dataController)
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            Group {
                if viewModel.projects.count == 0 {
                    Text("There's nothing to see here right now.")
                        .foregroundColor(.secondary)
                } else {
                    ScrollView {
                        VStack(alignment: .leading) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHGrid(rows: projectRows) {
                                    ForEach(viewModel.projects, content: ProjectSummaryView.init)
                                }
                                .padding([.horizontal, .top])
                                .fixedSize(horizontal: false, vertical: true)
                            }

                            VStack(alignment: .leading) {
                                ItemListView(title: "Up next", items: viewModel.upNext)
                                ItemListView(title: "More to explore", items: viewModel.moreToExplore)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .background(Color.systemGroupedBackground.ignoresSafeArea())
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Delete Data", action: viewModel.deleteData)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Test Data", action: viewModel.addSampleData)
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(dataController: .preview)
    }
}
