//
//  OddTrackerUITests.swift
//  OddTrackerUITests
//
//  Created by Michael Brünen on 10.03.21.
//

import XCTest

class OddTrackerUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        // UI tests must launch the application that they test.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["enable-testing"]
        app.launch()

        // In UI tests it’s important to set the initial state -such as interface orientation- required for your tests before they run. The setUp method is a good place to do this.
    }

    // MARK: - General
    func testTabbarButtonCount() throws {
        XCTAssertEqual(app.tabBars.buttons.count, 4, "There should be 4 buttons in the app's tabbar.")
    }

    // MARK: - Open Projects Tab
    func testOpenTabAddsProjects() {
        app.buttons["Open"].tap()
        XCTAssertEqual(app.tables.cells.count, 0, "There should be 0 rows in the app initially.")

        for tapCount in 1...3 {
            app.buttons["Add New Project"].tap()
            XCTAssertEqual(app.tables.cells.count, tapCount, "There should now be \(tapCount) rows in the list.")
        }
    }

    // NOTE: This is also called by other tests, but should not be problematic since there is a complete reset between tests
    func testAddingItemInsertsRows() {
        app.buttons["Open"].tap()
        XCTAssertEqual(app.tables.cells.count, 0, "There should be no list rows initially.")

        app.buttons["Add New Project"].tap()
        XCTAssertEqual(app.tables.cells.count, 1, "There should be 1 list row after adding a project.")

        // When debugging and stepping through, this test is always successfull,
        // adding a pause here seems to fix the problem of the test running "too fast"
        sleep(1)
        app.buttons["Add New Item"].tap()
        XCTAssertEqual(app.tables.cells.count, 2, "There should be 2 list rows after adding an item.")
    }

    func testEditingProjectUpdatesCorrectly() {
        // Go to Open Projects and add one project and one item.
        testAddingItemInsertsRows()

        // Test editing projects
        app.buttons["EDIT PROJECT"].tap()       // "compose" is the name of the sf-symbol used to indicate editing the project
        app.textFields["Project name"].tap()    // tap the text field

        // Type some text. NOTE: The simulator must use the software keyboard and it has to use the english keyboard
        // As further above, the UI tests seems to go "too fast" without the pause
        sleep(1)
        app.keys["space"].tap()
        app.keys["more"].tap()
        app.keys["2"].tap()
        app.buttons["Return"].tap()

        // Finally, go back and check if the name of the edited project is properly updated
        app.buttons["Open Projects"].tap()
        XCTAssertTrue(app.staticTexts["New Project 2"].exists, "The new project name should be visible in the list.")
    }

    func testEditingItemUpdatesCorrectly() {
        // Go to Open Projects and add one project and one item.
        testAddingItemInsertsRows()

        // Test editing items
        app.buttons["New Item"].tap()
        app.textFields["Item name"].tap()

        // Type some text. NOTE: The simulator must use the software keyboard and it has to use the english keyboard
        // As further above, the UI tests seems to go "too fast" without the pause
        sleep(1)
        app.keys["space"].tap()
        app.keys["more"].tap()
        app.keys["2"].tap()
        app.buttons["Return"].tap()

        // Finally, go back and check if the name of the edited item is properly updated
        app.buttons["Open Projects"].tap()
        XCTAssertTrue(app.buttons["New Item 2"].exists, "The new item name should be visible in the list.")
    }

    func testClosedProjectMovesToClosedTab() {
        // Go to Open Projects and add one project and one item.
        testAddingItemInsertsRows()

        // ensure the closed projects tab has no items, then go back
        app.buttons["Closed"].tap()
        XCTAssertEqual(app.tables.cells.count, 0, "There should be no list rows initially.")
        app.buttons["Open"].tap()

        // Close the Project and return
        app.buttons["EDIT PROJECT"].tap()            // tap the newly added project
        app.buttons["Close this project"].tap()     // close the project
        // Previously closing/opening a project would not return to the previous view, this was changed.
        // For future reference the code below remains commented out
//        app.buttons["Open Projects"].tap()          // and return with the navigation button

        // Then check the open and closed projects tabs
        XCTAssertEqual(app.tables.cells.count, 0, "There should no list rows in the open tab.")
        app.buttons["Closed"].tap()
        XCTAssertEqual(app.tables.cells.count, 1, "There should now be 1 list rows in the closed tab.")
    }

    func testSwipeToDelete() {
        // Go to Open Projects and add one project and one item.
        testAddingItemInsertsRows()

        // delete an item
        app.buttons["New Item"].swipeLeft()
        app.buttons["Delete"].tap()

        // test that only the project row is still there
        XCTAssertEqual(app.tables.cells.count, 1, "There should now be 1 list row in left")
    }

    // MARK: - Closed Projects Tab
    func testOpenedProjectMovesToOpenTab() {
        // Go to Open Projects and add one project and one item.
        testAddingItemInsertsRows()

        // close the project
        app.buttons["EDIT PROJECT"].tap()
        app.buttons["Close this project"].tap()
        // Previously closing/opening a project would not return to the previous view, this was changed.
        // For future reference the code below remains commented out
//        app.buttons["Open Projects"].tap()

        // ensure the open projects tab has no items, then go back
        app.buttons["Open"].tap()
        XCTAssertEqual(app.tables.cells.count, 0, "There should be no list rows initially.")
        app.buttons["Closed"].tap()

        // reopen the project and return
        app.buttons["EDIT PROJECT"].tap()
        app.buttons["Reopen this project"].tap()
        // Previously closing/opening a project would not return to the previous view, this was changed.
        // For future reference the code below remains commented out
//        app.buttons["Closed Projects"].tap()

        // Then check the open and closed projects tabs
        XCTAssertEqual(app.tables.cells.count, 0, "There should no list rows in the closed tab.")
        app.buttons["Open"].tap()
        XCTAssertEqual(app.tables.cells.count, 2, "There should now be 2 list rows in the closed tab.")
    }

    // MARK: - Awards
    func testAllAwardsShowLockedAlert() {
        // Go to the awards tab
        app.buttons["Awards"].tap()

        // check every award button (only checks button inside the scrollview, create array with allElementsBoundByIndex)
        for award in app.scrollViews.buttons.allElementsBoundByIndex {
            award.tap()
            XCTAssertTrue(app.alerts["Locked"].exists, "There should be a Locked alert showing for awards.")
            app.buttons["OK"].tap()
        }
    }

    func testUnlockingAwardsShowsDifferentAlert() {
        // Go to Open Projects and add one project and one item so an Award gets unlocked
        testAddingItemInsertsRows()

        // Go to the awards tab
        app.buttons["Awards"].tap()

        // check the first award button
        let award = app.scrollViews.buttons.allElementsBoundByIndex[0]
        award.tap()
        XCTAssertTrue(app.alerts["Unlocked: First Steps"].exists, "This award should be unlocked after adding one item.")
    }
}
