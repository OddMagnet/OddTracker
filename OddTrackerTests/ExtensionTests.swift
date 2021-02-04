//
//  ExtensionTests.swift
//  OddTrackerTests
//
//  Created by Michael Brünen on 04.02.21.
//

import SwiftUI
import XCTest
@testable import OddTracker

class ExtensionTests: XCTestCase {
    func testSequenceKeyPathSortingSelf() {
        // Given (setup)
        let items = [5, 3, 1, 2, 4]
        // When (work to evalute)
        let sortedItems = items.sorted(by: \.self)
        // Then (assertion)
        XCTAssertEqual(sortedItems, [1, 2, 3, 4, 5], "The sorted numbers must be ascending.")
    }

    func testSequenceKeyPathSortingCustom() {
        // Given
        struct Custom: Equatable {
            let value: String
        }
        let cu1 = Custom(value: "a")
        let cu2 = Custom(value: "b")
        let cu3 = Custom(value: "c")
        let cu4 = Custom(value: "d")
        let cu5 = Custom(value: "e")
        let items = [cu1, cu2, cu3, cu4, cu5]

        // When
        let sortedItems = items.sorted(by: \.value) {
            $0 > $1
        }

        // Then
        XCTAssertEqual(sortedItems, [cu5, cu4, cu3, cu2, cu1], "Reverse sorting should yield e, d, c, b, a.")
    }

    func testBundleDecodingAwards() {
        // Given when
        let awards = Bundle.main.decode([Award].self, from: "Awards.json")
        // Then
        XCTAssertFalse(awards.isEmpty, "Awards.json should decode to a non-empty array.")
    }

    func testDecodingString() {
        // Given
        let bundle = Bundle(for: ExtensionTests.self)
        // When
        let data = bundle.decode(String.self, from: "DecodableString.json")
        // Then
        XCTAssertEqual(data, "The rain in Spain falls mainly on the Spaniards.", "The string must match the content of DecodableString.json.")
    }

    func testDecodingDictionary() {
        // Given
        let bundle = Bundle(for: ExtensionTests.self)
        // When
        let data = bundle.decode([String: Int].self, from: "DecodableDictionary.json")
        // Then
        XCTAssertFalse(data.isEmpty, "DecodableDictionary.json should decode to a non-empty array.")
        XCTAssertEqual(data["One"], 1, "The dictionary should contain Int to String mappings.")
    }

    func testBindingOnChangeCallsFunction() {
        // Given
        var onChangeFunctionDidRun = false

        func exampleFunctionToCall() {
            onChangeFunctionDidRun = true
        }

        var bindingValue = ""
        let binding = Binding(
            get: { bindingValue },
            set: { bindingValue = $0 }
        )

        let changedBinding = binding.onChange(exampleFunctionToCall)

        // When
        changedBinding.wrappedValue = "Test"

        // Then
        XCTAssertTrue(onChangeFunctionDidRun, "The onChange() function was not run.")
    }
}
