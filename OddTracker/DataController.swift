//
//  DataController.swift
//  OddTracker
//
//  Created by Michael Brünen on 15.11.20.
//

import CoreData
import SwiftUI
import CoreSpotlight
import UserNotifications

/// An environment singleton responsible for managing the Core Data stack, including handling saving,
/// counting fetch requests, tracking awards, and dealing with sample data.
class DataController: ObservableObject {
    /// The lone CloudKit container used to store all data.
    let container: NSPersistentCloudKitContainer

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
    /// or on permanent storage (for use in regular app runs)
    ///
    /// Defaults to permanent storage
    /// - Parameter inMemory: Whether to store this data in temporary memory or not
    init(inMemory: Bool = false) {
        // make use of the static model, so there won't be 2 models loaded when testing
        // and multiple containers can make use of the same model
        container = NSPersistentCloudKitContainer(name: "Main", managedObjectModel: Self.model)

        // For testing and previewing purposes, create a temporary,
        // in-memory database by writing to /dev/null
        // data is destroyed after the app finishes running
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        // load the actual data, crash if there is an error
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Fatal error loading store: \(error.localizedDescription)")
            }

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

    /// Deletes all items on projects
    func deleteAll() {
        let fetchAllItems: NSFetchRequest<NSFetchRequestResult> = Item.fetchRequest()
        let batchDeleteAllItems = NSBatchDeleteRequest(fetchRequest: fetchAllItems)
        _ = try? container.viewContext.execute(batchDeleteAllItems)

        let fetchAllProjects: NSFetchRequest<NSFetchRequestResult> = Project.fetchRequest()
        let batchDeleteAllProjects = NSBatchDeleteRequest(fetchRequest: fetchAllProjects)
        _ = try? container.viewContext.execute(batchDeleteAllProjects)
    }

    /// Returns the amount of items a given fetchRequest would return
    /// - Parameter fetchRequest: The fetchRequest for which to count the items
    /// - Returns: The amount of items the fetchRequest would produce
    func count<T>(for fetchRequest: NSFetchRequest<T>) -> Int {
        (try? container.viewContext.count(for: fetchRequest)) ?? 0
    }

    /// Checks if a user has earned an award
    /// - Parameter award: The award to check
    /// - Returns: True if the user has earned it, false if not
    func hasEarned(award: Award) -> Bool {
        switch award.criterion {
            case "items":
                // returns true if they added a certain number of items
                let fetchRequest: NSFetchRequest<Item> = NSFetchRequest(entityName: "Item")
                let awardCount = count(for: fetchRequest)
                return awardCount >= award.value

            case "complete":
                // returns true if they completed a certain number of items
                let fetchRequest: NSFetchRequest<Item> = NSFetchRequest(entityName: "Item")
                fetchRequest.predicate = NSPredicate(format: "isCompleted = true")
                let awardCount = count(for: fetchRequest)
                return awardCount >= award.value

            default:
                // an unknown award criterion; this should never be allowed
                // fatalError("Unknown award criterion \(award.criterion).")
                print("TODO: Implement Awards for 'Chat' criterion")
                return false
        }
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

    // MARK: - Notifications
    /// Adds a notification for the given project
    /// - Parameters:
    ///   - project: The project the notification is for
    ///   - completion: The completion handler
    func addReminders(for project: Project, completion: @escaping (Bool) -> Void) {
    }

    /// Removes a notification for the given project
    /// - Parameter project: The project to remove the notification from
    func removeReminders(for project: Project) {
        let notificationCenter = UNUserNotificationCenter.current()
        let id = project.objectID.uriRepresentation().absoluteString
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
    }

    /// Requests the permissions to show notifications from the user
    /// - Parameter completion: The completion handler
    private func requestNotifications(completion: @escaping (Bool) -> Void) {
        let notificationCenter = UNUserNotificationCenter.current()

        notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            completion(granted)
        }
    }

    /// Places a single notification for the given project
    /// - Parameters:
    ///   - project: The project to place the notification for
    ///   - completion: The completion handler
    private func placeReminders(for project: Project, completion: @escaping (Bool) -> Void) {
        // content of the notification
        let content = UNMutableNotificationContent()
        content.sound = .default
        content.title = project.projectTitle
        if !project.projectDetail.isEmpty {
            content.subtitle = project.projectDetail
        }

        // trigger for the notification
        let components = Calendar.current.dateComponents([.hour, .minute], from: project.reminderTime ?? Date())
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        // wrap up content and trigger with an id
        let id = project.objectID.uriRepresentation().absoluteString
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        // send the request off to iOS
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if error == nil {
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }

}
