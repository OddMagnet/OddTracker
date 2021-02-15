//
//  PerformanceTests.swift
//  OddTrackerTests
//
//  Created by Michael Brünen on 15.02.21.
//

import XCTest
@testable import OddTracker

class PerformanceTests: BaseTestCase {
    func testAwardCalculationPerformance() throws {
        // create a significant amount of test data
        for _ in 1...100 {
            try dataController.createSampleDate()
        }

        // simulate lots of awards to check
        let awards = Array(repeating: Award.allAwards, count: 25).joined()
        XCTAssertEqual(awards.count, 500, "This checks the awards count is constant. Needs to be changed when new awards are added.")

        // then measure them all
        measure {
            _ = awards.filter(dataController.hasEarned)
        }
    }
}
