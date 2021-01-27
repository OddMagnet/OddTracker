//
//  ProjectsView.swift
//  OddTracker
//
//  Created by Michael Brünen on 16.11.20.
//

import SwiftUI

/// A View that shows an overview of Projects, used for both open and closed projects
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

    // MARK: - projectsList view
    var projectsList: some View {
        List {
            ForEach(projects) { project in
                Section(header: ProjectHeaderView(for: project)) {
                    ForEach(project.projectItems(using: sortOrder)) { item in
                        ItemRowView(for: item, in: project)
                    }
                    .onDelete { indexSet in
                        delete(indexSet, from: project)
                    }
                    if showClosedProjects == false {
                        Button {
                            addItem(to: project)
                        } label: {
                            Label("Add New Item", systemImage: "plus")
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }

    // MARK: - body view
    var body: some View {
        NavigationView {
            Group {
                if projects.count == 0 {
                    Text("There's nothing to see here right now.")
                        .foregroundColor(.secondary)
                } else {
                    projectsList
                }
            }
            .navigationTitle(showClosedProjects ? "Closed Projects" : "Open Projects")
            .toolbar {
                addProjectToolbarItem
                sortOrderToolbarItem
            }

            // Show this in landscape, if no project is selected
            SelectSomethingView()
        }
        .actionSheet(isPresented: $showingSortOrder) {
            ActionSheet(title: Text("Sort Items"), message: nil, buttons: [
                .default(Text(Item.SortOrder.optimized.rawValue)) { sortOrder = .optimized },
                .default(Text(Item.SortOrder.creationDate.rawValue)) { sortOrder = .creationDate },
                .default(Text(Item.SortOrder.title.rawValue)) { sortOrder = .title }
            ])
        }
    }

    // MARK: - addProject toolbar item
    var addProjectToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if showClosedProjects == false {
                Button(action: addProject) {
                    // In iOS 14.3 VoiceOver has a bug that reads the label
                    // "Add New Project" as "Add" no matter what accessibility label
                    // is give to this button when using a label.
                    // For better accessibility, a Text view is used when VoiceOver is running
                    if UIAccessibility.isVoiceOverRunning {
                        Text("Add New Project")
                    } else {
                        Label("Add New Project", systemImage: "plus")
                    }
                }
            }
        }
    }

    // MARK: - sortOrder toolbar item
    var sortOrderToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                showingSortOrder.toggle()
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
            }
        }
    }

    // MARK: - Functions
    func addItem(to project: Project) {
        withAnimation {
            let item = Item(context: managedObjectContext)
            item.project = project
            item.creationDate = Date()
            dataController.save()
        }
    }
    func addProject() {
        withAnimation {
            let project = Project(context: managedObjectContext)
            project.isClosed = false
            project.creationDate = Date()
            dataController.save()
        }
    }
    func delete(_ indexSet: IndexSet, from project: Project) {
        let allItems = project.projectItems(using: sortOrder)

        for index in indexSet {
            let item = allItems[index]
            dataController.delete(item)
        }

        dataController.save()
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