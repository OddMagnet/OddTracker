//
//  DataController-IAP.swift
//  OddTracker
//
//  Created by Michael Brünen on 15.06.21.
//

import Foundation
import StoreKit

extension DataController {
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
