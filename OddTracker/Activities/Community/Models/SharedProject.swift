//
//  SharedProjects.swift
//  OddTracker
//
//  Created by Michael Brünen on 29.12.21.
//

import Foundation

struct SharedProject: Identifiable {
    let id: String
    let title: String
    let detail: String
    let owner: String
    let isClosed: Bool

    static let example = SharedProject(
        id: "1",
        title: "Example",
        detail: "Detail",
        owner: "PLACEHOLDER",
        isClosed: false
    )
}
