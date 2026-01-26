//
//  SubscriptionManager.swift
//  Statly
//
//  Created by Ruben Marques on 25/01/2026.
//

import Foundation
import StoreKit
import Combine

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var subscriptionStatus: SubscriptionStatus = .basic
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let productID = "com.swipeuplabs.pro.monthly"
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        // Load initial subscription status
        Task {
            await checkSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Subscription Status
    
    enum SubscriptionStatus {
        case basic
        case pro
        
        var isPro: Bool {
            switch self {
            case .basic: return false
            case .pro: return true
            }
        }
        
        var displayName: String {
            switch self {
            case .basic: return "Basic"
            case .pro: return "Pro"
            }
        }
    }
    
    // MARK: - Limits
    
    var maxWidgets: Int {
        subscriptionStatus.isPro ? Int.max : 2
    }
    
    var allowedRefreshIntervals: [RefreshInterval] {
        if subscriptionStatus.isPro {
            return RefreshInterval.allCases
        } else {
            // Basic plan: only 2 hours minimum
            return RefreshInterval.allCases.filter { $0.rawValue >= 120 }
        }
    }
    
    var canUploadLogo: Bool {
        subscriptionStatus.isPro
    }
    
    // MARK: - StoreKit Methods
    
    func checkSubscriptionStatus() async {
        isLoading = true
        errorMessage = nil
        
        // Check for active subscriptions
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == productID {
                    // Check if subscription is still active
                    if transaction.revocationDate == nil {
                        subscriptionStatus = .pro
                        isLoading = false
                        return
                    }
                }
            }
        }
        
        // No active subscription found
        subscriptionStatus = .basic
        isLoading = false
    }
    
    func purchaseSubscription() async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load products
            let products = try await Product.products(for: [productID])
            
            if products.isEmpty {
                let errorMsg = "Product '\(productID)' not found. Make sure the StoreKit configuration file is selected in your Xcode scheme (Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration)."
                print("StoreKit Error: \(errorMsg)")
                throw SubscriptionError.productNotFound
            }
            
            guard let product = products.first else {
                throw SubscriptionError.productNotFound
            }
            
            // Purchase the product
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    // Transaction is verified, grant access
                    subscriptionStatus = .pro
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
        
        isLoading = false
    }
    
    func restorePurchases() async throws {
        isLoading = true
        errorMessage = nil
        
        try await AppStore.sync()
        await checkSubscriptionStatus()
        
        isLoading = false
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try Self.checkVerified(result)
                    await self.updateSubscriptionStatus(transaction: transaction)
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    private nonisolated static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed(nil)
        case .verified(let safe):
            return safe
        }
    }
    
    private func updateSubscriptionStatus(transaction: Transaction) async {
        if transaction.productID == productID {
            if transaction.revocationDate == nil {
                await MainActor.run {
                    subscriptionStatus = .pro
                }
            } else {
                await MainActor.run {
                    subscriptionStatus = .basic
                }
            }
        }
    }
    
    // MARK: - Product Info
    
    func getProductInfo() async throws -> Product? {
        let products = try await Product.products(for: [productID])
        
        if products.isEmpty {
            print("StoreKit Warning: Product '\(productID)' not found. Make sure the StoreKit configuration file is selected in your Xcode scheme.")
        }
        
        return products.first
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
            return "Subscription product not found.\n\nFor testing: Make sure 'Products.storekit' is selected in your Xcode scheme:\n1. Product → Scheme → Edit Scheme\n2. Select 'Run' → 'Options' tab\n3. Under 'StoreKit Configuration', select 'Products.storekit'\n4. Run the app again"
        case .verificationFailed:
            return "Failed to verify purchase. Please contact support."
        case .userCancelled:
            return "Purchase was cancelled."
        case .pending:
            return "Purchase is pending approval."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}
