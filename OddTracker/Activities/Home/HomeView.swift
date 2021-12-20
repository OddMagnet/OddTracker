//
//  HomeView.swift
//  OddTracker
//
//  Created by Michael Brünen on 16.11.20.
//

import SwiftUI
import CoreData
import CoreSpotlight

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
                        // Check if the user opened the app by selected an item in Spotlight
                        if let item = viewModel.selectedItem {
                            // if so, create a NavigationLink to the item in EditItemView
                            // `selection` and `tag` ensures the view only triggers when the the binding changes
                            // the `.id()` modifier ensures the view is refrshed when the item changes
                            NavigationLink(
                                destination: EditItemView(item: item),
                                tag: item,
                                selection: $viewModel.selectedItem,
                                label: EmptyView.init
                            )
                            .id(item)
                        }
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
            .onContinueUserActivity(CSSearchableItemActionType, perform: loadSpotlightItem)
        }
    }

    func loadSpotlightItem(_ userActivity: NSUserActivity) {
        // check the NSUserActivity's data for a unique identifier
        if let uniqueIdentifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
            // then check if there's an item for the uniqueIdentifier and select it
            viewModel.selectItem(with: uniqueIdentifier)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(dataController: .preview)
    }
}
