//
//  HomeView.swift
//  OddTracker
//
//  Created by Michael Brünen on 16.11.20.
//

import SwiftUI
import CoreData

struct HomeView: View {
    // Tag for the TabView in `ContentView.swift`
    static let tag: String? = "Home"
    
    @EnvironmentObject var dataController: DataController

    @FetchRequest(
        entity: Project.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Project.title, ascending: true)],
        predicate: NSPredicate(format: "isClosed = false")
    ) var projects: FetchedResults<Project>
    let items: FetchRequest<Item>

    var projectRows: [GridItem] {
        [GridItem(.fixed(100))]
    }

    init() {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted = false")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.priority, ascending: false)
        ]
        request.fetchLimit = 10
        items = FetchRequest(fetchRequest: request)
    }

    var body: some View {
        NavigationView {
            Group {
                if projects.count == 0 {
                    Text("There's nothing to see here right now.")
                        .foregroundColor(.secondary)
                } else {
                    ScrollView {
                        VStack(alignment: .leading) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHGrid(rows: projectRows) {
                                    ForEach(projects, content: ProjectSummaryView.init)
                                }
                                .padding([.horizontal, .top])
                                .fixedSize(horizontal: false, vertical: true)
                            }

                            VStack(alignment: .leading) {
                                ItemListView(title: "Up next", items: items.wrappedValue.prefix(3))
                                ItemListView(title: "More to explore", items: items.wrappedValue.dropFirst(3))
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .background(Color.systemGroupedBackground.ignoresSafeArea())
            .navigationTitle("Home")
        }
        .toolbar {
            Button("Add Test Data") {
                dataController.deleteAll()
                try? dataController.createSampleDate()
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
