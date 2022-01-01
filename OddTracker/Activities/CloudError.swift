//
//  CloudError.swift
//  OddTracker
//
//  Created by Michael Brünen on 01.01.22.
//

import Foundation
import CloudKit

struct CloudError: Identifiable, ExpressibleByStringInterpolation {
    var id: String { message }
    var message: String

    init(stringLiteral value: String) {
        self.message = value
    }

    init(from initialError: Error) {
        // ensure that the error is a `CKError`, otherwise return the best possible text
        guard let error = initialError as? CKError else {
            self.message = "An unknown error occured: \(initialError.localizedDescription)"
            return
        }

        // only the most important codes are handled, others will go to default
        switch error.code {
                // these three should only happen when there are fundamental logic errors, like
                // trying to access a non-existent database, if the public database refuses to to as asked
                // or when the data sent to CloudKit was invalid
                // NONE OF THESE SHOULD HAPPEN IN PRODUCTION CODE
            case .badContainer, .badDatabase, .invalidArguments:
                self.message = "A fatal error occured: \(error.localizedDescription)"

                // Network problems
            case .networkFailure, .networkUnavailable, .serverResponseLost, .serviceUnavailable:
                self.message = "There was a problem communicating with iCloud; please check your network connection and try again."

                // User is not logged in
            case .notAuthenticated:
                self.message = "There was a problem with your iCloud account; please check that you're logged in to iCloud."

                // Too many requests
            case .requestRateLimited:
                self.message = "You've hit iCloud's rate limit; please wait a moment then try again."

                // For the very rare case of this app bringing the users storage over it's allowed quota
            case .quotaExceeded:
                self.message = "You've exceeded your iCloud quota; please clear up some space then try again."

            default:
                self.message = "An unknown error occured: \(error.localizedDescription)"
        }
    }
}
