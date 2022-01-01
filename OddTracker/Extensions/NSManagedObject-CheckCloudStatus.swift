//
//  NSManagedObject-CheckCloudStatus.swift
//  OddTracker
//
//  Created by Michael Brünen on 01.01.22.
//

import Foundation
import CloudKit
import CoreData

extension NSManagedObject {
    /// Checks if a NSManagedObject is already in the cloud via CloudKit
    /// - Parameter completion: The closure to be run on completion, it's given the status of the objects existence in the cloud as a Boolean
    func checkCloudStatus(_ completion: @escaping (Bool) -> Void) {
        let name = objectID.uriRepresentation().absoluteString
        let id = CKRecord.ID(recordName: name)
        let operation = CKFetchRecordsOperation(recordIDs: [id])
        operation.desiredKeys = ["recordID"]

        operation.fetchRecordsCompletionBlock = { records, _ in
            if let records = records {
                // if a record exists it should always be unique because of its ID
                completion(records.count == 1)
            } else {
                completion(false)
            }
        }

        CKContainer.default().publicCloudDatabase.add(operation)
    }
}
