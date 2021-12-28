//
//  ProjectsViewModel.swift
//  OddTracker
//
//  Created by Michael Brünen on 11.03.21.
//

import Foundation
import CoreData

extension ProjectsView {
    class ViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
        // MARK: - Properties
        @Published var showingUnlockView = false
        let showClosedProjects: Bool
        let dataController: DataController
        var sortOrder = Item.SortOrder.optimized
        // @FetchRequest doesn't work outside of views
//        @FetchRequest var projects: FetchedResults<Project>
        // Instead using NSFetchedResultsController to handle the fetching and a Project array to present to the view
        private let projectsController: NSFetchedResultsController<Project>
        @Published var projects = [Project]()

        // MARK: - Initialiser
        init(dataController: DataController, showClosedProjects: Bool) {
            self.dataController = dataController
            self.showClosedProjects = showClosedProjects

            let request: NSFetchRequest<Project> = Project.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Project.creationDate, ascending: false)]
            request.predicate = NSPredicate(format: "isClosed = %d", showClosedProjects)

            // Create the FetchedResultsController based on the request,
            // with the managedObjectContext to execute in (dataController.container.viewContext)
            // without breaking up the data or caching
            projectsController = NSFetchedResultsController(
                fetchRequest: request,
                managedObjectContext: dataController.container.viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            // set the delegate
            super.init()
            projectsController.delegate = self

            // finally, execute the request
            do {
                try projectsController.performFetch()
                projects = projectsController.fetchedObjects ?? []
            } catch {
                print("Failed to fetch projects")
            }
        }

        // MARK: - Functions
        func addProject() {
            if dataController.addProject() == false {
                showingUnlockView.toggle()
            }
        }

        func addItem(to project: Project) {
            let item = Item(context: dataController.container.viewContext)
            item.project = project
            item.creationDate = Date()
            item.isCompleted = false
            item.priority = 2
            dataController.save()
        }

        func delete(_ indexSet: IndexSet, from project: Project) {
            let allItems = project.projectItems(using: sortOrder)

            for index in indexSet {
                let item = allItems[index]
                dataController.delete(item)
            }

            dataController.save()
        }

        // MARK: - NSFetchedResultsController delegate methods
        func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            if let newProjects = controller.fetchedObjects as? [Project] {
                projects = newProjects
            }
        }

    }
}
