//
//  UnlockManager.swift
//  OddTracker
//
//  Created by Michael Brünen on 17.05.21.
//

import Foundation
import Combine
import StoreKit

class UnlockManager: NSObject, ObservableObject, SKPaymentTransactionObserver, SKProductsRequestDelegate {
    enum RequestState {
        case loading    // started the request, no response yet
        case loaded     // successful response from Apple describing the products available for purchase
        case failed     // something went wrong, either request for products or the attempt to purchase
        case purchased  // user has successfully purchased or restored the IAP
        case deferred   // current user can't make the purchase, e.g. a minor needs permission from his guardian
    }

    private let dataController: DataController
    private let request: SKProductsRequest
    private var loadedProducts = [SKProduct]()
    @Published var requestState = RequestState.loading

    init(dataController: DataController) {
        // store datacontroller
        self.dataController = dataController

        // prepare to look for unlocked products
        let productIDs = Set(["io.github.oddmagnet.OddTracker.unlock"])
        request = SKProductsRequest(productIdentifiers: productIDs)

        super.init()

        // watch the payment queue
        SKPaymentQueue.default().add(self)

        // set the delegate for when the product request completes
        request.delegate = self

        // start the request
        request.start()
    }

    deinit {
        // remove the delegate object (self) from the payment queue when the app is terminated
        // to avoid potential problems where iOS thinks the app has been notified about a purchase
        SKPaymentQueue.default().remove(self)
    }

    // MARK: - SKPaymentTransactionObserver
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {

    }

    // MARK: - SKProductsRequestDelegate
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {

    }
}
