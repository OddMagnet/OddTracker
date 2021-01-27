//
//  AwardTests.swift
//  OddTrackerTests
//
//  Created by Michael Brünen on 22.01.21.
//

import XCTest
import CoreData
@testable import OddTracker

class AwardTests: BaseTestCase {
    let awards = Award.allAwards

    func testAwardIDMatchesName() {
        for award in awards {
            XCTAssertEqual(award.id, award.name, "Award ID should always match its name.")
        }
    }

    func testNewUserHasNoAwards() throws {
        for award in awards {
            XCTAssertFalse(dataController.hasEarned(award: award), "New users should have no earned awards.")
        }
    }

    func testAddingItems() throws {
        let values = [1, 10, 20, 50, 100, 250, 500, 1000]

        // for each possible item count value that unlocks an awards
        for (count, value) in values.enumerated() {
            // create the amount of items needed to unlock the corresponding awards
            for _ in 0 ..< value {
                _ = Item(context: managedObjectContext)
            }

            // create an array that contains all awards that have the 'item' criterion and are earned
            let matches = awards.filter { award in
                award.criterion == "items" && dataController.hasEarned(award: award)
            }

            // this should result in the filtered array having the same amount of awards that the x'th place in the array should unlock
            XCTAssertEqual(matches.count, count + 1, "Adding \(value) items should unlock \(count + 1) awards.")

            dataController.deleteAll()
        }
    }

    func testCompletedAwards() throws {
        let values = [1, 10, 20, 50, 100, 250, 500, 1000]

        // for each possible item count value that unlocks an awards
        for (count, value) in values.enumerated() {
            // create and complete the amount of items needed to unlock the corresponding awards
            for _ in 0 ..< value {
                let item = Item(context: managedObjectContext)
                item.isCompleted = true
            }

            // create an array that contains all awards that have the 'completed' criterion and are earned
            let matches = awards.filter { award in
                award.criterion == "complete" && dataController.hasEarned(award: award)
            }

            // this should result in the filtered array having the same amount of awards that the x'th place in the array should unlock
            XCTAssertEqual(matches.count, count + 1, "Completing \(value) items should unlock \(count + 1) awards.")

            dataController.deleteAll()
        }
    }
}
