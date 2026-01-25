//
//  SubscriptionView.swift
//  Statly
//
//  Created by Ruben Marques on 25/01/2026.
//

import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var product: Product?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: subscriptionManager.isPremium ? "checkmark.seal.fill" : "crown.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(subscriptionManager.isPremium ? .green : .yellow)
                        
                        Text(subscriptionManager.isPremium ? "Premium Active" : "Upgrade to Premium")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(subscriptionManager.isPremium 
                             ? "You have access to all premium features"
                             : "Unlock unlimited widgets and premium features")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 32)
                    
                    // Features Comparison
                    if !subscriptionManager.isPremium {
                        VStack(spacing: 20) {
                            Text("What's Included in Premium")
                                .font(.title3)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 16) {
                                PremiumFeatureRow(
                                    icon: "rectangle.grid.2x2.fill",
                                    title: "Unlimited Widgets",
                                    description: "Create as many widgets as you need for all your apps and services"
                                )
                                
                                PremiumFeatureRow(
                                    icon: "photo.fill",
                                    title: "Custom Logo",
                                    description: "Add your brand logo or app icon to personalize your widgets"
                                )
                                
                                PremiumFeatureRow(
                                    icon: "arrow.clockwise",
                                    title: "Faster Refresh Rates",
                                    description: "Update widgets every 5, 15, or 30 minutes for real-time data"
                                )
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    } else {
                        // Premium active - show features they have
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Your Premium Features")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            VStack(spacing: 12) {
                                FeatureRow(
                                    title: "Unlimited Widgets",
                                    description: "Create as many widgets as you need",
                                    isPremium: true
                                )
                                
                                FeatureRow(
                                    title: "Custom Logo",
                                    description: "Add logos to personalize widgets",
                                    isPremium: true
                                )
                                
                                FeatureRow(
                                    title: "Faster Refresh Rates",
                                    description: "5min, 15min, 30min intervals available",
                                    isPremium: true
                                )
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }
                    
                    // Current Status
                    if subscriptionManager.isPremium {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Premium subscription active")
                                    .fontWeight(.medium)
                            }
                            
                            Button("Restore Purchases") {
                                Task {
                                    await subscriptionManager.restorePurchases()
                                }
                            }
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    } else {
                        // Purchase Button
                        if let product = product {
                            VStack(spacing: 16) {
                                VStack(spacing: 8) {
                                    Text("Upgrade to Premium")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    Text(product.displayPrice)
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.secondary)
                                    
                                    if let subscriptionPeriod = product.subscription?.subscriptionPeriod {
                                        Text(periodDescription(subscriptionPeriod))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 8)
                                
                                Button(action: {
                                    Task {
                                        do {
                                            try await subscriptionManager.purchaseSubscription()
                                        } catch {
                                            // Error is handled by subscriptionManager
                                        }
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "crown.fill")
                                            .font(.headline)
                                        Text("Subscribe to Premium")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .disabled(subscriptionManager.isLoading)
                                
                                if subscriptionManager.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                                
                                Button("Restore Purchases") {
                                    Task {
                                        await subscriptionManager.restorePurchases()
                                    }
                                }
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                                .disabled(subscriptionManager.isLoading)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.accentColor.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                        } else {
                            VStack(spacing: 12) {
                                ProgressView("Loading subscription options...")
                                
                                if let errorMessage = subscriptionManager.errorMessage {
                                    Text(errorMessage)
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                } else {
                                    Text("If this takes too long, make sure you have a StoreKit Configuration file set up for testing.")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                            }
                            .padding()
                        }
                    }
                    
                    // Error Message (shown below purchase section)
                    if subscriptionManager.isPremium == false, let product = product, let errorMessage = subscriptionManager.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Terms
                    VStack(spacing: 8) {
                        Text("Subscriptions will auto-renew unless cancelled at least 24 hours before the end of the current period.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 16) {
                            Button("Terms of Service") {
                                // Open terms URL
                            }
                            .font(.caption2)
                            .foregroundStyle(.blue)
                            
                            Button("Privacy Policy") {
                                // Open privacy URL
                            }
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                if !subscriptionManager.isPremium {
                    product = await subscriptionManager.getProduct()
                }
            }
            .onChange(of: subscriptionManager.subscriptionStatus) { _, _ in
                if subscriptionManager.isPremium {
                    product = nil
                } else {
                    Task {
                        product = await subscriptionManager.getProduct()
                    }
                }
            }
        }
    }
    
    private func periodDescription(_ period: Product.SubscriptionPeriod) -> String {
        switch period.unit {
        case .day:
            return period.value == 1 ? "per day" : "every \(period.value) days"
        case .week:
            return period.value == 1 ? "per week" : "every \(period.value) weeks"
        case .month:
            return period.value == 1 ? "per month" : "every \(period.value) months"
        case .year:
            return period.value == 1 ? "per year" : "every \(period.value) years"
        @unknown default:
            return ""
        }
    }
}

struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

struct FeatureRow: View {
    let title: String
    let description: String
    let isPremium: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isPremium ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(isPremium ? .green : .gray)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    SubscriptionView()
}
