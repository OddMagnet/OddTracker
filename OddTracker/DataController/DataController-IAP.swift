//
//  DataController-IAP.swift
//  OddTracker
//
//  Created by Michael Brünen on 15.06.21.
//

import Foundation
import StoreKit

extension DataController {
    // MARK: - IAP
    /// Loads and saves whether the premium unlock has been purchased
    /// Uses the `defaults` property from the main DataController file
    var fullVersionUnlocked: Bool {
        get {
            defaults.bool(forKey: "fullVersionUnlocked")
        }
        set {
            defaults.set(newValue, forKey: "fullVersionUnlocked")
        }
    }

    // MARK: - On App launch
    func appLaunched() {
        guard count(for: Project.fetchRequest()) >= 5 else { return }

        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first { $0.activationState == .foregroundActive }

        if let windowScene = scene as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
