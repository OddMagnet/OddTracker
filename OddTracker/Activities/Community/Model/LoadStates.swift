//
//  LoadStates.swift
//  OddTracker
//
//  Created by Michael Brünen on 29.12.21.
//

import Foundation

enum LoadState {
    case inactive       // No request for data has been made
    case loading        // A request for data is currently on its way
    case success        // Some data has been received, the stream might still be ongoing
    case noResults      // The request finished without any results
}
