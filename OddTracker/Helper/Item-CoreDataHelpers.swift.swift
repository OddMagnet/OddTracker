//
//  Item-CoreDataHelpers.swift.swift
//  OddTracker
//
//  Created by Michael Brünen on 17.11.20.
//

import Foundation

/// Remove optionality from core data properties and provide example data for previewing
extension Item {
    var itemTitle: String { title ?? "" }
    var itemDetail: String { detail ?? "" }
    var itemCreationDate: Date { creationDate ?? Date() }

    static var example: Item {
        let controller = DataController(inMemory: true)
        let viewContext = controller.container.viewContext

        let item = Item(context: viewContext)
        item.title = "Example Title"
        item.detail = "This is an example detail"
        item.priority = 3
        item.creationDate = Date()
        return item
    }
}
