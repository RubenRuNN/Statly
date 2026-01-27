//
//  ConfigurationListView.swift
//  Statly
//
//  Created by Ruben Marques on 24/01/2026.
//

import SwiftUI

struct ConfigurationListView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var configurations: [StatlyWidgetConfiguration] = []
    @State private var showingAddConfig = false
    @State private var showingSubscription = false
    @State private var showingLimitAlert = false
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private var isIPadOrMac: Bool {
        #if os(macOS)
        return true
        #else
        return horizontalSizeClass == .regular && UIDevice.current.userInterfaceIdiom != .phone
        #endif
    }
    
    var canCreateWidget: Bool {
        configurations.count < subscriptionManager.maxWidgets
    }
    
    var body: some View {
        NavigationView {
            Group {
                if configurations.isEmpty {
                    emptyStateView
                } else {
                    configurationsList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Widgets")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSubscription = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: subscriptionManager.subscriptionStatus.isPro ? "crown.fill" : "crown")
                                .font(.caption)
                            Text(subscriptionManager.subscriptionStatus.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(subscriptionManager.subscriptionStatus.isPro ? .yellow : .secondary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if canCreateWidget {
                            showingAddConfig = true
                        } else {
                            showingLimitAlert = true
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.tint)
                    }
                    .disabled(!canCreateWidget && !subscriptionManager.subscriptionStatus.isPro)
                }
            }
            .sheet(isPresented: $showingAddConfig) {
                CreateConfigurationView { newConfig in
                    configurations.append(newConfig)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingSubscription) {
                SubscriptionView()
            }
            .alert("Widget Limit Reached", isPresented: $showingLimitAlert) {
                Button("Upgrade to Pro", role: .none) {
                    showingSubscription = true
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Basic plan allows up to 2 widgets. Upgrade to Pro for unlimited widgets.")
            }
            .onAppear {
                loadConfigurations()
            }
            .task {
                await subscriptionManager.checkSubscriptionStatus()
            }
            .navigationViewStyle(.stack)
        }
    }
    
    private var configurationsList: some View {
        ScrollView {
            LazyVStack(spacing: isIPadOrMac ? 16 : 12) {
                // Widget count indicator
                if !subscriptionManager.subscriptionStatus.isPro {
                    HStack {
                        Text("\(configurations.count) / \(subscriptionManager.maxWidgets) widgets")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if configurations.count >= subscriptionManager.maxWidgets {
                            Button(action: { showingSubscription = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "crown.fill")
                                        .font(.caption)
                                    Text("Upgrade")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundStyle(.yellow)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                ForEach(configurations) { config in
                    NavigationLink(destination: EditConfigurationView(configuration: config)) {
                        ConfigurationRow(configuration: config)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive, action: {
                            deleteConfiguration(config)
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, isIPadOrMac ? 24 : 16)
            .padding(.top, 8)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.grid.2x2")
                .font(.system(size: 64))
                .foregroundStyle(.secondary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Widgets Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Create your first widget to display stats on your home screen")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: {
                if canCreateWidget {
                    showingAddConfig = true
                } else {
                    showingLimitAlert = true
                }
            }) {
                Label("Create Widget", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 8)
            
            if !canCreateWidget && !subscriptionManager.subscriptionStatus.isPro {
                Button(action: { showingSubscription = true }) {
                    HStack {
                        Image(systemName: "crown.fill")
                        Text("Upgrade to Pro for Unlimited Widgets")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.yellow)
                    .padding(.top, 8)
                }
            }
        }
    }
    
    private func loadConfigurations() {
        configurations = ConfigurationManager.shared.loadAllConfigurations()
    }
    
    private func deleteConfiguration(_ config: StatlyWidgetConfiguration) {
        ConfigurationManager.shared.deleteConfiguration(id: config.id)
        configurations.removeAll { $0.id == config.id }
    }
}

struct ConfigurationRow: View {
    let configuration: StatlyWidgetConfiguration
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon/Preview
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: configuration.styling.backgroundColor))
                    .frame(width: 56, height: 56)
                
                if let data = configuration.styling.logoImageData,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else if !configuration.styling.logoURL.isEmpty {
                    AsyncImage(url: URL(string: configuration.styling.logoURL)) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        } else {
                            Image(systemName: "chart.bar.fill")
                                .foregroundStyle(Color(hex: configuration.styling.valueTextColor))
                                .font(.title3)
                        }
                    }
                } else {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(Color(hex: configuration.styling.valueTextColor))
                        .font(.title3)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(configuration.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 8) {
                    Text(configuration.styling.appName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .foregroundStyle(.secondary.opacity(0.5))
                    
                    Text(configuration.refreshInterval.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
