//
//  OddTrackerTests.swift
//  OddTrackerTests
//
//  Created by Michael Brünen on 21.01.21.
//

import CoreData
import XCTest
// import all of the main project for testing, allowing access to all parts without the need to declare them `public`
@testable import OddTracker

class BaseTestCase: XCTestCase {
    var dataController: DataController!
    var managedObjectContext: NSManagedObjectContext!

    override func setUpWithError() throws {
        dataController = DataController(inMemory: true)
        managedObjectContext = dataController.container.viewContext
    }
}
