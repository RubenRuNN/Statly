//
//  SubscriptionManager.swift
//  Statly
//
//  Created by Ruben Marques on 25/01/2026.
//

import Foundation
import StoreKit
import Combine

class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var subscriptionStatus: SubscriptionStatus = .unknown
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Product ID - must match what's configured in App Store Connect
    private let subscriptionProductID = "com.swipeuplabs.statly.premium"
    
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        // Load initial subscription status
        Task { @MainActor in
            await checkSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Subscription Status
    
    enum SubscriptionStatus {
        case unknown
        case free
        case premium
    }
    
    var isPremium: Bool {
        subscriptionStatus == .premium
    }
    
    var isFree: Bool {
        subscriptionStatus == .free || subscriptionStatus == .unknown
    }
    
    // MARK: - Check Subscription Status
    
    @MainActor
    func checkSubscriptionStatus() async {
        isLoading = true
        errorMessage = nil
        
        // Check for active subscriptions
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == subscriptionProductID {
                    // Check if subscription is still active
                    if transaction.revocationDate == nil {
                        subscriptionStatus = .premium
                        isLoading = false
                        return
                    }
                }
            }
        }
        
        // No active subscription found
        subscriptionStatus = .free
        isLoading = false
    }
    
    // MARK: - Purchase Subscription
    
    @MainActor
    func purchaseSubscription() async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Load the product
            let products = try await Product.products(for: [subscriptionProductID])
            guard let product = products.first else {
                throw SubscriptionError.productNotFound
            }
            
            // Purchase the product
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    // Transaction is verified, grant premium access
                    subscriptionStatus = .premium
                    await transaction.finish()
                case .unverified(_, let error):
                    throw SubscriptionError.verificationFailed(error)
                }
            case .userCancelled:
                throw SubscriptionError.userCancelled
            case .pending:
                throw SubscriptionError.pending
            @unknown default:
                throw SubscriptionError.unknown
            }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Restore Purchases
    
    @MainActor
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Get Product Info
    
    @MainActor
    func getProduct() async -> Product? {
        do {
            let products = try await Product.products(for: [subscriptionProductID])
            if products.isEmpty {
                errorMessage = "Product '\(subscriptionProductID)' not found. Make sure it's configured in App Store Connect or in your StoreKit Configuration file."
                print("⚠️ StoreKit: Product '\(subscriptionProductID)' not found")
                return nil
            }
            return products.first
        } catch {
            errorMessage = "Failed to load product: \(error.localizedDescription)"
            print("❌ StoreKit Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    
                    // Verify the transaction is for our subscription
                    if transaction.productID == self.subscriptionProductID {
                        await self.updateSubscriptionStatus()
                    }
                    
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed(nil)
        case .verified(let safe):
            return safe
        }
    }
    
    @MainActor
    private func updateSubscriptionStatus() async {
        await checkSubscriptionStatus()
    }
}

// MARK: - Subscription Errors

enum SubscriptionError: LocalizedError {
    case productNotFound
    case verificationFailed(Error?)
    case userCancelled
    case pending
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Subscription product not found. Please try again later."
        case .verificationFailed(let error):
            return "Failed to verify purchase: \(error?.localizedDescription ?? "Unknown error")"
        case .userCancelled:
            return "Purchase was cancelled."
        case .pending:
            return "Purchase is pending approval."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}
