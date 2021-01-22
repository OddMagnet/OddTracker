//
//  ProjectTests.swift
//  OddTrackerTests
//
//  Created by Michael Brünen on 22.01.21.
//

import XCTest
import CoreData
@testable import OddTracker

class ProjectTests: BaseTestCase {
    func testCreatingProjectsAndItems() {
        let targetCount = 10

        for _ in 0 ..< targetCount {
            let project = Project(context: managedObjectContext)

            for _ in 0 ..< targetCount {
                let item = Item(context: managedObjectContext)
                item.project = project
            }
        }

        XCTAssertEqual(dataController.count(for: Project.fetchRequest()), targetCount)
        XCTAssertEqual(dataController.count(for: Item.fetchRequest()), targetCount * targetCount)
    }

    func testDeletingProjectCascadeDeletesItems() throws {
        try dataController.createSampleDate()

        let request = NSFetchRequest<Project>(entityName: "Project")
        let projects = try managedObjectContext.fetch(request)

        let correctProjectCount = projects.count - 1
        let correctItemCount = correctProjectCount * 10

        dataController.delete(projects[0])

        XCTAssertEqual(dataController.count(for: Project.fetchRequest()), correctProjectCount)
        XCTAssertEqual(dataController.count(for: Item.fetchRequest()), correctItemCount)
    }
}
