//
//  HomeViewModel.swift
//  OddTracker
//
//  Created by Michael Brünen on 13.03.21.
//

import Foundation
import CoreData

extension HomeView {
    class ViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
        // MARK: - Properties
        private let projectsController: NSFetchedResultsController<Project>
        private let itemsController: NSFetchedResultsController<Item>

        @Published var projects = [Project]()
        @Published var items = [Item]()
        @Published var selectedItem: Item?
        var dataController: DataController

        // MARK: - Computed Properties
        var upNext: ArraySlice<Item> {
            items.prefix(3)
        }

        var moreToExplore: ArraySlice<Item> {
            items.dropFirst(3)
        }

        // MARK: - Initialiser
        init(dataController: DataController) {
            self.dataController = dataController

            // fetch request for open projects
            let projectsRequest: NSFetchRequest<Project> = Project.fetchRequest()
            projectsRequest.predicate = NSPredicate(format: "isClosed = false")
            projectsRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Project.title, ascending: true)]

            // initiate controller for items based on the request,
            // with the managedObjectContext to execute in (dataController.container.viewContext)
            // without breaking up the data or caching
            projectsController = NSFetchedResultsController(
                fetchRequest: projectsRequest,
                managedObjectContext: dataController.container.viewContext,
                sectionNameKeyPath: nil, cacheName: nil
            )

            // fetch request for the 10 highest priority incomplete items
            let itemsRequest = dataController.fetchRequestForTopItems(count: 10)

            // initiate controller for items based on the request,
            // with the managedObjectContext to execute in (dataController.container.viewContext)
            // without breaking up the data or caching
            itemsController = NSFetchedResultsController(
                fetchRequest: itemsRequest,
                managedObjectContext: dataController.container.viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )

            super.init()

            // set delegates and perform the first fetches
            projectsController.delegate = self
            itemsController.delegate = self

            do {
                try projectsController.performFetch()
                try itemsController.performFetch()
                projects = projectsController.fetchedObjects ?? []
                items = itemsController.fetchedObjects ?? []
            } catch {
                print("Failed to fetch initial data")
            }
        }

        // MARK: - Functions
        func deleteData() {
            dataController.deleteAll()
        }
        func addSampleData() {
            dataController.deleteAll()
            try? dataController.createSampleDate()
        }

        func selectItem(with identifier: String) {
            selectedItem = dataController.item(with: identifier)
        }

        // MARK: - NSFetchedResultsController delegate methods
        func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            // check if the controller got new items or projects, then update the correct property
            if let newItems = controller.fetchedObjects as? [Item] {
                items = newItems
            } else if let newProjects = controller.fetchedObjects as? [Project] {
                projects = newProjects
            }
        }
    }
}
