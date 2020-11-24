//
//  Binding-OnChange.swift.swift
//  OddTracker
//
//  Created by Michael Brünen on 24.11.20.
//

import SwiftUI

extension Binding {
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
