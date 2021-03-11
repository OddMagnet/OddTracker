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

    @StateObject var viewModel: ViewModel
    @State private var showingSortOrder = false

    // Initialiser passes data directly to the ViewModels init
    init(dataController: DataController, showClosedProjects: Bool) {
        let viewModel = ViewModel(dataController: dataController, showClosedProjects: showClosedProjects)
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - projectsList view
    var projectsList: some View {
        List {
            ForEach(viewModel.projects) { project in
                Section(header: ProjectHeaderView(for: project)) {
                    ForEach(project.projectItems(using: viewModel.sortOrder)) { item in
                        ItemRowView(for: item, in: project)
                    }
                    .onDelete { indexSet in
                        viewModel.delete(indexSet, from: project)
                    }
                    if viewModel.showClosedProjects == false {
                        Button {
                            withAnimation {
                                viewModel.addItem(to: project)
                            }
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
                if viewModel.projects.count == 0 {
                    Text("There's nothing to see here right now.")
                        .foregroundColor(.secondary)
                } else {
                    projectsList
                }
            }
            .navigationTitle(viewModel.showClosedProjects ? "Closed Projects" : "Open Projects")
            .toolbar {
                addProjectToolbarItem
                sortOrderToolbarItem
            }

            // Show this in landscape, if no project is selected
            SelectSomethingView()
        }
        .actionSheet(isPresented: $showingSortOrder) {
            ActionSheet(title: Text("Sort Items"), message: nil, buttons: [
                .default(Text(Item.SortOrder.optimized.rawValue)) { viewModel.sortOrder = .optimized },
                .default(Text(Item.SortOrder.creationDate.rawValue)) { viewModel.sortOrder = .creationDate },
                .default(Text(Item.SortOrder.title.rawValue)) { viewModel.sortOrder = .title }
            ])
        }
    }

    // MARK: - addProject toolbar item
    var addProjectToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if viewModel.showClosedProjects == false {
                Button {
                    withAnimation {
                        viewModel.addProject()
                    }
                } label: {
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
}

struct ProjectsView_Previews: PreviewProvider {
    static var dataController = DataController.preview

    static var previews: some View {
        ProjectsView(dataController: dataController, showClosedProjects: false)
    }
}
