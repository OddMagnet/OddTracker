//
//  DataController.swift
//  OddTracker
//
//  Created by Michael Brünen on 15.11.20.
//

import CoreData
import SwiftUI

class DataController: ObservableObject {
    // CloudKitContainer for easy iCloud sync
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

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Main")

        if inMemory {
            // if set to true, only create the data in memory instead of on disk
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        // load the actual data, crash if there is an error
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                fatalError("Fatal error loading store: \(error.localizedDescription)")
            }
        }
    }

    func createSampleDate() throws {
        // get the context from the container
        let viewContext = container.viewContext

        for i in 1...5 {
            // create sample projects in the containers context
            let project = Project(context: viewContext)
            project.title = "Sample-Project \(i)"
            project.items = []
            project.creationDate = Date()
            project.isClosed = Bool.random()

            for j in 1...10 {
                // add sample items to the sample project in the containers context
                let item = Item(context: viewContext)
                item.title = "Sample item \(i).\(j)"
                item.creationDate = Date()
                item.isCompleted = project.isClosed ? true : Bool.random()  // always true if project is closed, otherwise random
                item.project = project
                item.priority = Int16.random(in: 1...3)
            }
        }

        // save the sample data
        try viewContext.save()
    }

    func save() {
        if container.viewContext.hasChanges {
            try? container.viewContext.save()
        }
    }

    func delete(_ object: NSManagedObject) {
        container.viewContext.delete(object)
    }

    func deleteAll() {
        let fetchAllItems: NSFetchRequest<NSFetchRequestResult> = Item.fetchRequest()
        let batchDeleteAllItems = NSBatchDeleteRequest(fetchRequest: fetchAllItems)
        _ = try? container.viewContext.execute(batchDeleteAllItems)

        let fetchAllProjects: NSFetchRequest<NSFetchRequestResult> = Project.fetchRequest()
        let batchDeleteAllProjects = NSBatchDeleteRequest(fetchRequest: fetchAllProjects)
        _ = try? container.viewContext.execute(batchDeleteAllProjects)
    }

    func count<T>(for fetchRequest: NSFetchRequest<T>) -> Int {
        (try? container.viewContext.count(for: fetchRequest)) ?? 0
    }

    func hasEarned(award: Award) -> Bool {
        // manually creating fetchrequests for testing later on
        switch award.criterion {
            case "items":
                let fetchRequest: NSFetchRequest<Item> = NSFetchRequest(entityName: "Item")
                let awardCount = count(for: fetchRequest)
                return awardCount >= award.value

            case "complete":
                let fetchRequest: NSFetchRequest<Item> = NSFetchRequest(entityName: "Item")
                fetchRequest.predicate = NSPredicate(format: "isCompleted = true")
                let awardCount = count(for: fetchRequest)
                return awardCount >= award.value

            default:
                //fatalError("Unknown award criterion \(award.criterion).")
                return false
        }
    }
}
