//
//  DataController.swift
//  OddTracker
//
//  Created by Michael Brünen on 15.11.20.
//

import CoreData
import SwiftUI
import CoreSpotlight
import WidgetKit

/// A class for managing the Core Data stack, including loading, saving,
/// counting fetch requests, tracking awards, and dealing with sample data.
class DataController: ObservableObject {
    /// The lone CloudKit container used to store all data.
    let container: NSPersistentCloudKitContainer

    /// The UserDefaults suite where user data is saved in
    let defaults: UserDefaults

    /// Loads and saves whether the premium unlock has been purchased
    var fullVersionUnlocked: Bool {
        get {
            defaults.bool(forKey: "fullVersionUnlocked")
        }
        set {
            defaults.set(newValue, forKey: "fullVersionUnlocked")
        }
    }

    static var preview: DataController = {
        let dataController = DataController(inMemory: true)
        let viewContext = dataController.container.viewContext

        do {
            try dataController.createSampleDate()
        } catch {
            fatalError("Fatal error creating preview: \(error.localizedDescription)")
        }

        return dataController
    }()

    /// A static model used for tests, so the NSPersistentCloudKitContainer doesn't find multiple `Item` entities
    static let model: NSManagedObjectModel = {
        guard let url = Bundle.main.url(forResource: "Main", withExtension: "momd") else {
            fatalError("Failed to locate model file")
        }

        guard let managedObjectModel = NSManagedObjectModel(contentsOf: url) else {
            fatalError("Failed to load model file")
        }

        return managedObjectModel
    }()

    /// Initializes a data controller, either in memory (for temporary use such as testing and previewing),
    /// or on permanent storage (for use in regular app runs),
    /// with either the standard UserDefaults suite for regular app runs,
    /// or with a custom instance for testing
    ///
    /// Defaults to permanent storage
    /// - Parameter inMemory: Whether to store this data in temporary memory or not
    /// - Parameter defaults: The UserDefaults suite where user data should be stored
    init(inMemory: Bool = false, defaults: UserDefaults = .standard) {
        //
        self.defaults = defaults

        // make use of the static model, so there won't be 2 models loaded when testing
        // and multiple containers can make use of the same model
        container = NSPersistentCloudKitContainer(name: "Main", managedObjectModel: Self.model)

        // For testing and previewing purposes, create a temporary,
        // in-memory database by writing to /dev/null
        // data is destroyed after the app finishes running
        // otherwise set the groupID and get the url for the App Group
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            let groupID = "group.io.github.oddmagnet.OddTracker"

            if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) {
                container.persistentStoreDescriptions.first?.url = url.appendingPathComponent("Main.sqlite")
            }
        }

        // load the actual data, crash if there is an error
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Fatal error loading store: \(error.localizedDescription)")
            }

            // automatically merge any changes from other devices
            self.container.viewContext.automaticallyMergesChangesFromParent = true

            // using `#if DEBUG` to ensure this code will never get executed in a live app
            #if DEBUG
            if CommandLine.arguments.contains("enable-testing") {
                self.deleteAll()
                UIView.setAnimationsEnabled(false)  // for faster UI testing
            }
            #endif
        }
    }

    /// Creates example projects and items for manual testing
    /// - Throws: An NSError sent from calling `save()` on the NSManagedObjectContext
    func createSampleDate() throws {
        // get the context from the container
        let viewContext = container.viewContext

        for projectCounter in 1...5 {
            // create sample projects in the containers context
            let project = Project(context: viewContext)
            project.title = "Sample-Project \(projectCounter)"
            project.items = []
            project.creationDate = Date()
            project.isClosed = Bool.random()

            for itemCounter in 1...10 {
                // add sample items to the sample project in the containers context
                let item = Item(context: viewContext)
                item.title = "Sample item \(projectCounter).\(itemCounter)"
                item.creationDate = Date()
                item.isCompleted = project.isClosed ? true : Bool.random()  // always true if project is closed, otherwise random
                item.project = project
                item.priority = Int16.random(in: 1...3)
            }
        }

        // save the sample data
        try viewContext.save()
    }

    /// Saves the Core Data context iff there are changes. This silently ignores
    /// any errors caused by saving, but this should be fine because all attributes are optional.
    func save() {
        if container.viewContext.hasChanges {
            try? container.viewContext.save()

            // ensure that widgets get updated as well
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    /// Adds a new project
    @discardableResult func addProject() -> Bool {
        let canCreate = fullVersionUnlocked || count(for: Project.fetchRequest()) < 3

        if canCreate {
            let project = Project(context: container.viewContext)
            project.isClosed = false
            project.creationDate = Date()
            save()
            return true
        } else {
            return false
        }
    }

    /// Deletes an object and it's spotlight record
    /// - Parameter object: The object to delete and remove the spotlight record of
    func delete(_ object: NSManagedObject) {
        let id = object.objectID.uriRepresentation().absoluteString

        if object is Item { // Items use Identifiers for their spotlight record
            CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [id])
        } else {            // while Projects use the DomainIdentifiers
            CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [id])
        }

        container.viewContext.delete(object)
    }

    /// Deletes objects based on a fetch request and merges the changes into the current viewContext
    /// - Parameter fetchRequest: The fetch request for all objects to be deleted
    private func delete(_ fetchRequest: NSFetchRequest<NSFetchRequestResult>) {
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        // set the batch requests result type to get back all object IDs that are being deleted
        batchDeleteRequest.resultType = .resultTypeObjectIDs

        // if the execute was successfull, take the result
        if let delete = try? container.viewContext.execute(batchDeleteRequest) as? NSBatchDeleteResult {
            // put the object IDs into a dictionary with a key of `NSDeletedObjectsKey`. Use an empty array if they can't be read
            let changes = [NSDeletedObjectsKey: delete.result as? [NSManagedObjectID] ?? []]
            // the dictionary is then used to merge the changes to the view context
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [container.viewContext])
        }
    }

    /// Deletes all items and projects
    func deleteAll() {
        let fetchAllItems: NSFetchRequest<NSFetchRequestResult> = Item.fetchRequest()
        delete(fetchAllItems)

        let fetchAllProjects: NSFetchRequest<NSFetchRequestResult> = Project.fetchRequest()
        delete(fetchAllProjects)
    }

    /// Returns the amount of items a given fetchRequest would return
    /// - Parameter fetchRequest: The fetchRequest for which to count the items
    /// - Returns: The amount of items the fetchRequest would produce
    func count<T>(for fetchRequest: NSFetchRequest<T>) -> Int {
        (try? container.viewContext.count(for: fetchRequest)) ?? 0
    }

    // MARK: - Spotlight
    /// Writes the items information to spotlight
    /// - Parameter item: The item whose information should be written to spotlight
    func update(_ item: Item) {
        // Creating a unique identifier for the item
        let itemID = item.objectID.uriRepresentation().absoluteString
        let projectID = item.project?.objectID.uriRepresentation().absoluteString

        // Set up the attributes to store in Spotlight
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
        attributeSet.title = item.itemTitle
        attributeSet.contentDescription = item.itemDetail

        // Wrap the identifier and attributes in a Spotlight record along with a domain identifier – a way to group certain pieces of data together
        let searchableItem = CSSearchableItem(
            uniqueIdentifier: itemID,
            domainIdentifier: projectID,
            attributeSet: attributeSet
        )

        // Send the record off to Spotlight for indexing
        CSSearchableIndex.default().indexSearchableItems([searchableItem])

        // ensure the changed data gets saved
        save()
    }

    func item(with uniqueIdentifier: String) -> Item? {
        // ensure the uniqueIdentifier is a valid url
        guard let url = URL(string: uniqueIdentifier) else { return nil }
        // ensure there is an object for the url
        guard let id = container.persistentStoreCoordinator.managedObjectID(forURIRepresentation: url) else { return nil }

        return try? container.viewContext.existingObject(with: id) as? Item
    }

    // MARK: - Widget
    /// Returns a NSFetchRequest for some items
    /// - Parameter count: The amount of items the request should return
    /// - Returns: The requested NSFetchRequest
    func fetchRequestForTopItems(count: Int) -> NSFetchRequest<Item> {
        let itemRequest: NSFetchRequest<Item> = Item.fetchRequest()

        let completedPredicate = NSPredicate(format: "isCompleted = false")
        let openPredicate = NSPredicate(format: "project.isClosed = false")
        let compoundPredicate = NSCompoundPredicate(type: .and, subpredicates: [completedPredicate, openPredicate])
        itemRequest.predicate = compoundPredicate

        itemRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.priority, ascending: false)
        ]

        itemRequest.fetchLimit = count
        return itemRequest
    }

    /// Returns the results of a given NSFetchRequest
    /// - Parameter fetchRequest: The request to get the results for
    /// - Returns: The results of the request
    func results<T: NSManagedObject>(for fetchRequest: NSFetchRequest<T>) -> [T] {
        return (try? container.viewContext.fetch(fetchRequest)) ?? []
    }
}
