//
//  ChatMessage.swift
//  OddTracker
//
//  Created by Michael Brünen on 30.12.21.
//

import Foundation
import CloudKit

struct ChatMesssage: Identifiable {
    let id: String
    let from: String
    let text: String
    let date: Date
}

// Initializer in an extension as to not loose the synthesized memberwise initializer
extension ChatMesssage {
    init(from record: CKRecord) {
        id = record.recordID.recordName
        from = record["from"] as? String ?? "No author"
        text = record["text"] as? String ?? "No text"
        date = record.creationDate ?? Date()
    }
}
