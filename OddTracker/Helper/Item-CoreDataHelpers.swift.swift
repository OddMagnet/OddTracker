//
//  Item-CoreDataHelpers.swift.swift
//  OddTracker
//
//  Created by Michael Brünen on 17.11.20.
//

import SwiftUI

extension Item {
    /// Returns the items title, or an empty string if the title was nil
    var itemTitle: String { title ?? "New Item" }
    /// Returns the items detail, or an empty string if the detail was nil
    var itemDetail: String { detail ?? "" }
    /// Returns the items creationDate, or the current date if the creationDate was nil
    var itemCreationDate: Date { creationDate ?? Date() }
    /// Returns the items project, should realistically never return nil
    var itemProject: Project { project! }

    /// Sorting Orders for Items
    /// Optimized: Uses completion, priority and date
    /// Title: Only sorts by title
    /// CreationDate: Only sorts by creation date
    enum SortOrder: String {
        case optimized = "Optimized"
        case title = "Title"
        case creationDate = "Creation Date"
    }

    /// Provides example data for previewing purposes
    static var example: Item {
        let controller = DataController(inMemory: true)
        let viewContext = controller.container.viewContext

        let item = Item(context: viewContext)
        item.title = "Example Item Title"
        item.detail = "This is a example item detail"
        item.priority = 3
        item.project = Project.example
        item.creationDate = Date()
        return item
    }
}
