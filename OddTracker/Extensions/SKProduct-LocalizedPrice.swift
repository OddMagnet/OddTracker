//
//  SKProduct-LocalizedPrice.swift
//  OddTracker
//
//  Created by Michael Brünen on 19.05.21.
//

import StoreKit

extension SKProduct {
    var localizedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(for: price)!
    }
}
