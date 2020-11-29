//
//  ProjectsView.swift
//  OddTracker
//
//  Created by Michael Brünen on 16.11.20.
//

import SwiftUI

struct ProjectsView: View {
    // Tags for the TabView in `ContentView.swift`
    static let openTag: String? = "Open"
    static let closedTag: String? = "Closed"
    
    let showClosedProjects: Bool
    @FetchRequest var projects: FetchedResults<Project>

    @EnvironmentObject var dataController: DataController
    @Environment(\.managedObjectContext) var managedObjectContext

    @State private var showingSortOrder = false
    @State private var sortOrder = Item.SortOrder.optimized

    init(showClosedProjects: Bool) {
        self.showClosedProjects = showClosedProjects

        // manually create a FetchRequest, sort by creationDate
        // only fetch items where 'isClosed' == 'showClosedProjects'
        _projects = FetchRequest<Project>(entity: Project.entity(),
                                         sortDescriptors: [
                                            NSSortDescriptor(keyPath: \Project.creationDate,
                                                             ascending: false)
                                         ],
                                         predicate: NSPredicate(format: "isClosed = %d", showClosedProjects)
        )
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(projects) { project in
                    Section(header: ProjectHeaderView(for: project)) {
                        ForEach(items(for: project)) { item in
                            ItemRowView(for: item)
                        }
                        .onDelete { indexSet in
                            let allItems = project.projectItems

                            for index in indexSet {
                                let item = allItems[index]
                                dataController.delete(item)
                            }

                            dataController.save()
                        }
                        if showClosedProjects == false {
                            Button {
                                withAnimation {
                                    let item = Item(context: managedObjectContext)
                                    item.project = project
                                    item.creationDate = Date()
                                    dataController.save()
                                }
                            } label: {
                                Label("Add New Item", systemImage: "plus")
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(showClosedProjects ? "Closed Projects" : "Open Projects")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if showClosedProjects == false {
                        Button {
                            withAnimation {
                                let project = Project(context: managedObjectContext)
                                project.isClosed = false
                                project.creationDate = Date()
                                dataController.save()
                            }
                        } label: {
                            Label("Add New Project", systemImage: "plus")
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSortOrder.toggle()
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
        }
        .actionSheet(isPresented: $showingSortOrder) {
            ActionSheet(title: Text("Sort Items"), message: nil, buttons: [
                .default(Text("Optimized")) { sortOrder = .optimized },
                .default(Text("Creation Date")) { sortOrder = .creationDate },
                .default(Text("Title")) { sortOrder = .title }
            ])
        }
    }

    func items(for project: Project) -> [Item] {
        switch sortOrder {
            case .optimized:
                return project.projectItemsDefaultSorted
            case .creationDate:
                return project.projectItems.sorted { $0.itemCreationDate < $1.itemCreationDate }
            case .title:
                return project.projectItems.sorted { $0.itemTitle < $1.itemTitle }
        }
    }
}

struct ProjectsView_Previews: PreviewProvider {
    static var dataController = DataController.preview

    static var previews: some View {
        ProjectsView(showClosedProjects: false)
            .environment(\.managedObjectContext, dataController.container.viewContext)
            .environmentObject(dataController)
    }
}
