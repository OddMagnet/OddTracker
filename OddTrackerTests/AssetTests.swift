//
//  AssetTests.swift
//  OddTrackerTests
//
//  Created by Michael Brünen on 21.01.21.
//

import XCTest
@testable import OddTracker

class AssetTests: XCTestCase {
    func testColorsExist() {
        for color in Project.colors {
            XCTAssertNotNil(UIColor(named: color), "Failed to load \(color) from asset catalog.")
        }
    }

    func testJSONLoadsCorrectly() {
        XCTAssertTrue(Award.allAwards.isEmpty == false, "Failed to load awards from JSON.")
    }
}
