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
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    if subscriptionManager.subscriptionStatus.isPro {
                        proActiveView
                    } else {
                        paywallView
                    }
                }
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(subscriptionManager.errorMessage ?? "An error occurred. Please try again.")
            }
            .task {
                do {
                    product = try await subscriptionManager.getProductInfo()
                } catch {
                    print("Failed to load product info: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Pro Active View
    
    private var proActiveView: some View {
        VStack(spacing: 24) {
            // Success Header
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                }
                
                VStack(spacing: 8) {
                    Text("Pro Plan Active")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("You have access to all Pro features")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, 40)
            .padding(.bottom, 8)
            
            // Feature List
            VStack(alignment: .leading, spacing: 20) {
                Text("Your Pro Benefits")
                    .font(.headline)
                    .padding(.horizontal)
                
                VStack(spacing: 0) {
                    ProFeatureRow(
                        icon: "rectangle.grid.2x2.fill",
                        title: "Unlimited Widgets",
                        description: "Create as many widgets as you need"
                    )
                    
                    Divider()
                        .padding(.leading, 56)
                    
                    ProFeatureRow(
                        icon: "clock.fill",
                        title: "All Refresh Intervals",
                        description: "From 5 minutes to 2 hours"
                    )
                    
                    Divider()
                        .padding(.leading, 56)
                    
                    ProFeatureRow(
                        icon: "photo.fill",
                        title: "Custom Logos",
                        description: "Upload and customize widget logos"
                    )
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.bottom, 32)
    }
    
    // MARK: - Paywall View
    
    private var paywallView: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Text("Choose Your Plan")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Unlock the full potential of Statly")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 32)
            .padding(.bottom, 32)
            
            // Plan Comparison
            HStack(spacing: 12) {
                // Basic Plan
                PlanCard(
                    title: "Basic",
                    subtitle: "Free",
                    price: "Free",
                    isRecommended: false,
                    isPro: false,
                    features: [
                        PlanFeature(icon: "checkmark", text: "2 widgets", isAvailable: true),
                        PlanFeature(icon: "clock", text: "2 hours minimum refresh", isAvailable: true),
                        PlanFeature(icon: "xmark", text: "No logo customization", isAvailable: false)
                    ]
                )
                
                // Pro Plan
                PlanCard(
                    title: "Pro",
                    subtitle: "Recommended",
                    price: product?.displayPrice ?? "$1.99",
                    pricePeriod: "/month",
                    isRecommended: true,
                    isPro: true,
                    features: [
                        PlanFeature(icon: "checkmark", text: "Unlimited widgets", isAvailable: true),
                        PlanFeature(icon: "checkmark", text: "All refresh intervals", isAvailable: true),
                        PlanFeature(icon: "checkmark", text: "Custom logo upload", isAvailable: true)
                    ]
                )
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
            
            // CTA Button
            VStack(spacing: 12) {
                Button(action: {
                    Task {
                        do {
                            try await subscriptionManager.purchaseSubscription()
                        } catch {
                            showingError = true
                        }
                    }
                }) {
                    HStack {
                        if subscriptionManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "crown.fill")
                            Text("Upgrade to Pro")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(subscriptionManager.isLoading)
                
                Button(action: {
                    Task {
                        do {
                            try await subscriptionManager.restorePurchases()
                        } catch {
                            showingError = true
                        }
                    }
                }) {
                    Text("Restore Purchases")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .disabled(subscriptionManager.isLoading)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Plan Card

struct PlanCard: View {
    let title: String
    let subtitle: String
    let price: String
    var pricePeriod: String = ""
    let isRecommended: Bool
    let isPro: Bool
    let features: [PlanFeature]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                if isRecommended {
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                        Text(subtitle)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.yellow)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.15))
                    .clipShape(Capsule())
                } else {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(price)
                        .font(.title)
                        .fontWeight(.bold)
                    if !pricePeriod.isEmpty {
                        Text(pricePeriod)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            
            Divider()
            
            // Features
            VStack(alignment: .leading, spacing: 16) {
                ForEach(features, id: \.text) { feature in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: feature.icon)
                            .font(.subheadline)
                            .foregroundStyle(feature.isAvailable ? (isPro ? .green : .blue) : .gray)
                            .frame(width: 20)
                        
                        Text(feature.text)
                            .font(.subheadline)
                            .foregroundStyle(feature.isAvailable ? .primary : .secondary)
                            .strikethrough(!feature.isAvailable)
                    }
                }
            }
            .padding()
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isRecommended ? Color.accentColor.opacity(0.05) : Color(.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isRecommended ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct PlanFeature {
    let icon: String
    let text: String
    let isAvailable: Bool
}

// MARK: - Pro Feature Row

struct ProFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.green)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    SubscriptionView()
}
