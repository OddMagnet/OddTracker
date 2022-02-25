//
//  DataController-Awards.swift
//  OddTracker
//
//  Created by Michael Brünen on 15.06.21.
//

import CoreData

extension DataController {
    /// Checks if a user has earned an award
    /// - Parameter award: The award to check
    /// - Returns: True if the user has earned it, false if not
    func hasEarned(award: Award) -> Bool {
        switch award.criterion {
            case "items":
                // returns true if they added a certain number of items
                let fetchRequest: NSFetchRequest<Item> = NSFetchRequest(entityName: "Item")
                let awardCount = count(for: fetchRequest)
                return awardCount >= award.value

            case "complete":
                // returns true if they completed a certain number of items
                let fetchRequest: NSFetchRequest<Item> = NSFetchRequest(entityName: "Item")
                fetchRequest.predicate = NSPredicate(format: "isCompleted = true")
                let awardCount = count(for: fetchRequest)
                return awardCount >= award.value

            case "chat":
                // returns true if they posted a certain amount of chat messages
                return UserDefaults.standard.integer(forKey: "chatCount") >= award.value

            default:
                // an unknown award criterion; this should never be allowed
                // fatalError("Unknown award criterion \(award.criterion).")
                print("TODO: Implement Awards for 'Chat' criterion")
                return false
        }
    }
}
