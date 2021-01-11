//
//  Binding-OnChange.swift.swift
//  OddTracker
//
//  Created by Michael Brünen on 24.11.20.
//

import SwiftUI

extension Binding {
    /// Creates a binding that calls a given handler on every change
    /// - Parameter handler: The handler to be called on every change
    /// - Returns: The Binding of the value
    func onChange(_ handler: @escaping () -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler()
            }
        )
    }
}
