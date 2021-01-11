//
//  SelectSomethingView.swift
//  OddTracker
//
//  Created by Michael Brünen on 29.11.20.
//

import SwiftUI

/// A View purely to prompt the user to select an entry in the menu, in case nothing is selected
struct SelectSomethingView: View {
    var body: some View {
        Text("Please select something from the menu to begin.")
            .italic()
            .bold()
            .foregroundColor(.secondary)
    }
}

struct SelectSomethingView_Previews: PreviewProvider {
    static var previews: some View {
        SelectSomethingView()
    }
}
