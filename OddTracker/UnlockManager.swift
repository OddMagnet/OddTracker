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
        case loading            // started the request, no response yet
        case loaded(SKProduct)  // successful response from Apple describing the products available for purchase
        case failed(Error?)     // something went wrong, either request for products or the attempt to purchase
        case purchased          // user has successfully purchased or restored the IAP
        case deferred           // current user can't make the purchase, e.g. a minor needs permission from his guardian
    }
    private enum StoreError: Error {
        case invalidIdentifiers, missingProduct
    }

    private let dataController: DataController
    private let request: SKProductsRequest
    private var loadedProducts = [SKProduct]()
    @Published var requestState = RequestState.loading

    // MARK: - Init / Deinit
    init(dataController: DataController) {
        // store datacontroller
        self.dataController = dataController

        // prepare to look for unlocked products
        let productIDs = Set(["io.github.oddmagnet.OddTracker.unlock"])
        request = SKProductsRequest(productIdentifiers: productIDs)

        super.init()

        // watch the payment queue
        SKPaymentQueue.default().add(self)

        // check if the full version is already unlocked, return if it is
        guard dataController.fullVersionUnlocked == false else { return }

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

    // MARK: - Functions
    /// Starts the purchase process for a product
    /// - Parameter product: The product
    func buy(product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }

    /// Restores purchased products
    func restore() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

    // MARK: - SKPaymentTransactionObserver
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        // ensure to work on main thread since a `@Published` property gets updated, which means it may trigger SwiftUI views to be updated
        DispatchQueue.main.async { [self] in
            // for every transaction (should only be one, but future-proofing here)
            for transaction in transactions {
                // check the transactions state
                switch transaction.transactionState {
                    // if it's purchased or restored
                    case .purchased, .restored:
                        // ensure the full version is unlocked, set the new requestState and finish the transaction
                        self.dataController.fullVersionUnlocked = true
                        self.requestState = .purchased
                        queue.finishTransaction(transaction)

                    // if it's failed
                    case .failed:
                        // check if there was a product and set the requestState accordingly, then finish the transaction
                        if let product = loadedProducts.first {
                            self.requestState = .loaded(product)
                        } else {
                            self.requestState = .failed(transaction.error)
                        }
                        queue.finishTransaction(transaction)

                    // if it's deferred
                    case .deferred:
                        // just update the requestState
                        self.requestState = .deferred

                    default:
                        break
                }
            }
        }
    }

    // MARK: - SKProductsRequestDelegate
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        // ensure to work on main thread since a `@Published` property gets updated, which means it may trigger SwiftUI views to be updated
        DispatchQueue.main.async {
            // store returned products
            self.loadedProducts = response.products

            // ensure a product was returned
            guard let unlock = self.loadedProducts.first else {
                self.requestState = .failed(StoreError.missingProduct)
                return
            }

            // if there were invalid product identifiers
            if response.invalidProductIdentifiers.isEmpty == false {
                print("ALERT: Received invalid product identifiers: \(response.invalidProductIdentifiers)")
                self.requestState = .failed(StoreError.invalidIdentifiers)
                return
            }

            // otherwise set the request state to the loaded product
            self.requestState = .loaded(unlock)
        }
    }
}
