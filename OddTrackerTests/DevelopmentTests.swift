//
//  DevelopmentTests.swift
//  OddTrackerTests
//
//  Created by Michael Brünen on 27.01.21.
//

import XCTest
import CoreData
@testable import OddTracker

class DevelopmentTests: BaseTestCase {
    func testSampleDataCreationWorks() throws {
        try dataController.createSampleDate()

        XCTAssertEqual(dataController.count(for: Project.fetchRequest()), 5, "There should be 5 sample projects")
        XCTAssertEqual(dataController.count(for: Item.fetchRequest()), 50, "There should be 50 sample items")
    }

    func testDeleteAllClearsEverything() throws {
        try dataController.createSampleDate()
        dataController.deleteAll()

        XCTAssertEqual(dataController.count(for: Project.fetchRequest()), 0, "There should be no sample projects after deleteAll()")
        XCTAssertEqual(dataController.count(for: Item.fetchRequest()), 0, "There should be no sample items after deleteAll()")
    }
}
