//
//  Project-CoreDataHelpers.swift
//  OddTracker
//
//  Created by Michael Brünen on 26.11.20.
//

import SwiftUI

extension Project {
    /// Returns the projects title, or an empty string if the title was nil
    var projectTitle: String { title ?? "New Project" }
    /// Returns the projects detail, or an empty string if the detail was nil
    var projectDetail: String { detail ?? "" }
    /// Returns the projects color, or 'Light Blue' as a default if the color was nil
    var projectColor: Color { Color(color ?? "Light Blue") }
    /// Returns the projects color string, or 'Light Blue' as a default if the color string was nil
    var projectColorString: String { color ?? "Light Blue" }

    /// Provides example data for previewing purposes
    static var example: Project {
        let controller = DataController(inMemory: true)
        let viewContext = controller.container.viewContext

        let project = Project(context: viewContext)
        project.title = "Example Project Title"
        project.detail = "This is a example project detail"
        project.isClosed = true
        project.creationDate = Date()
        return project
    }

    /// Provide names for the colors in the Colors.xcassets catalog
    static let colors = ["Pink", "Purple", "Red", "Orange", "Gold", "Green", "Teal", "Light Blue", "Dark Blue", "Midnight", "Dark Gray", "Gray"]

    /// Returns the projects items as an array, sorted by (in order) completion, priority and creation date
    var projectItems: [Item] {
        let itemsArray = items?.allObjects as? [Item] ?? []

        return itemsArray.sorted { first, second in
            // First attempt to sort by completion, completed items come last
            if !first.isCompleted && second.isCompleted { return true }
            if first.isCompleted && !second.isCompleted { return false }

            // next attempt to sort by priority
            if first.priority > second.priority { return true }
            if first.priority < second.priority { return false }

            // finally, sort by creation date if all else was equal
            return first.itemCreationDate < second.itemCreationDate
        }
    }

    /// Returns a completion amount for the project, if the project has no items 0 is returned
    var completionAmount: Double {
        let allItems = items?.allObjects as? [Item] ?? []
        guard allItems.isEmpty == false else { return 0 }  // no completion amount if the project has no items

        let completedItems = allItems.filter(\.isCompleted)
        return Double(completedItems.count) / Double(allItems.count)
    }
}
