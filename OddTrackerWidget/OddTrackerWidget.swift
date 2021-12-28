//
//  OddTrackerWidget.swift
//  OddTrackerWidget
//
//  Created by Michael Brünen on 15.06.21.
//

import WidgetKit
import SwiftUI
import Intents

// All future Widgets are reached via this entry point.
@main
struct OddTrackerWidgets: WidgetBundle {
    var body: some Widget {
        SimpleOddTrackerWidget()
        ComplexOddTrackerWidget()
    }
}
