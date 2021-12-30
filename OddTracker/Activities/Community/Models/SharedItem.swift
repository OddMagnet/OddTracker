//
//  SharedItem.swift
//  OddTracker
//
//  Created by Michael Brünen on 29.12.21.
//

import Foundation

struct SharedItem: Identifiable {
    let id: String
    let title: String
    let detail: String
    let isCompleted: Bool
}
