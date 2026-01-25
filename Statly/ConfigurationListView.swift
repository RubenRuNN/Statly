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
    
    var body: some View {
        NavigationView {
            ZStack {
                if configurations.isEmpty {
                    emptyStateView
                } else {
                    configurationsList
                }
            }
            .navigationTitle("Widgets")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSubscription = true }) {
                        Image(systemName: subscriptionManager.isPremium ? "crown.fill" : "crown")
                            .font(.title3)
                            .foregroundStyle(subscriptionManager.isPremium ? .yellow : .secondary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { 
                        if canAddWidget {
                            showingAddConfig = true
                        } else {
                            showingSubscription = true
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(canAddWidget ? Color.accentColor : Color.secondary)
                    }
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
            .onAppear {
                loadConfigurations()
                Task {
                    await subscriptionManager.checkSubscriptionStatus()
                }
            }
        }
    }
    
    private var configurationsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Widget limit warning for free users
                if !subscriptionManager.isPremium && configurations.count >= 2 {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Widget Limit Reached")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Free version allows up to 2 widgets. Upgrade to Premium for unlimited widgets.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Upgrade") {
                            showingSubscription = true
                        }
                        .font(.caption)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
            .padding(.horizontal)
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
            
            Button(action: { showingAddConfig = true }) {
                Label("Create Widget", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 8)
        }
    }
    
    private func loadConfigurations() {
        configurations = ConfigurationManager.shared.loadAllConfigurations()
    }
    
    private func deleteConfiguration(_ config: StatlyWidgetConfiguration) {
        ConfigurationManager.shared.deleteConfiguration(id: config.id)
        configurations.removeAll { $0.id == config.id }
    }
    
    private var canAddWidget: Bool {
        subscriptionManager.isPremium || configurations.count < 2
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
