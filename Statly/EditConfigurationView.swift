//
//  EditConfigurationView.swift
//  Statly
//
//  Created by Ruben Marques on 24/01/2026.
//

import SwiftUI
import PhotosUI
import UIKit
import WidgetKit

struct EditConfigurationView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var config: StatlyWidgetConfiguration
    @State private var isTestingConnection = false
    @State private var testError: String?
    @State private var availableStats: [Stat] = []
    @State private var selectedLogoItem: PhotosPickerItem?
    @State private var logoPreview: Image?
    @State private var showingSubscription = false
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private var isIPadOrMac: Bool {
        #if os(macOS)
        return true
        #else
        return horizontalSizeClass == .regular && UIDevice.current.userInterfaceIdiom != .phone
        #endif
    }
    
    private var maxContentWidth: CGFloat {
        isIPadOrMac ? 800 : .infinity
    }
    
    private var sampleStats: [Stat] {
        [
            Stat(label: "USERS", value: "1,234", trend: "+12%", trendDirection: .up),
            Stat(label: "MRR", value: "$45.2K", trend: "-5%", trendDirection: .down),
            Stat(label: "CONVERSIONS", value: "89", trend: "0%", trendDirection: .neutral)
        ]
    }
    
    init(configuration: StatlyWidgetConfiguration) {
        _config = State(initialValue: configuration)
    }
    
    var body: some View {
        HStack {
            Spacer()
            Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Widget Name", text: $config.name)
                        .textFieldStyle(.plain)
                    
                    Divider()
                    
                    TextField("App Name", text: $config.styling.appName)
                        .textFieldStyle(.plain)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Basic Info")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Endpoint URL", text: $config.endpointURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.plain)
                    
                    Divider()
                    
                    SecureField("API Key", text: $config.apiKey)
                        .textFieldStyle(.plain)
                    
                    Divider()
                    
                    Button(action: testConnection) {
                        HStack {
                            Label("Refresh Stats", systemImage: "arrow.clockwise")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            if isTestingConnection {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .foregroundStyle(Color.accentColor)
                    
                    if let error = testError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                            Text(error)
                                .font(.caption)
                        }
                        .foregroundColor(.red)
                        .padding(.top, 4)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Endpoint")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if !availableStats.isEmpty {
                Section {
                    StatSelectionView(
                        availableStats: availableStats,
                        selectedIndices: $config.selectedStatIndices
                    )
                    .padding(.vertical, 8)
                } header: {
                    Text("Select & Order Stats")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } footer: {
                    if config.selectedStatIndices.isEmpty {
                        Text("Select which stats to display on your widget. Drag selected stats to reorder them.")
                            .font(.caption)
                    } else {
                        Text("\(config.selectedStatIndices.count) stat\(config.selectedStatIndices.count == 1 ? "" : "s") selected. Drag to reorder.")
                            .font(.caption)
                    }
                }
            }
            
            Section {
                Picker("Refresh Interval", selection: $config.refreshInterval) {
                    ForEach(subscriptionManager.allowedRefreshIntervals, id: \.self) { interval in
                        Text(interval.displayName).tag(interval)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Refresh Interval")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } footer: {
                if !subscriptionManager.subscriptionStatus.isPro {
                    Button(action: { showingSubscription = true }) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                            Text("Upgrade to Pro for faster refresh intervals (5 min, 15 min, 30 min, 1 hour)")
                                .font(.caption)
                        }
                        .foregroundStyle(.yellow)
                    }
                }
            }
            
            Section {
                VStack(spacing: 12) {
                    ColorPickerRow(title: "Background", color: $config.styling.backgroundColor)
                    Divider()
                    ColorPickerRow(title: "Labels", color: $config.styling.primaryTextColor)
                    Divider()
                    ColorPickerRow(title: "Values", color: $config.styling.valueTextColor)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Colors")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Section {
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Horizontal Padding")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(config.styling.horizontalPadding)) pt")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $config.styling.horizontalPadding, in: 8...32, step: 2)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Vertical Padding")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(config.styling.verticalPadding)) pt")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $config.styling.verticalPadding, in: 4...20, step: 2)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Padding")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } footer: {
                Text("Adjust the spacing around widget content")
                    .font(.caption)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    Toggle("Show logo", isOn: $config.styling.showsLogo)
                        .disabled(!subscriptionManager.canUploadLogo)
                    Toggle("Show app name", isOn: $config.styling.showsAppName)
                    
                    if config.styling.showsLogo {
                        if subscriptionManager.canUploadLogo {
                            Divider()
                            
                            PhotosPicker(selection: $selectedLogoItem, matching: .images) {
                                Label("Pick logo from Photos", systemImage: "photo")
                                    .font(.subheadline)
                            }
                            
                            TextField("Logo URL (optional)", text: $config.styling.logoURL)
                                .textInputAutocapitalization(.never)
                                .textFieldStyle(.plain)
                            
                            if let logoPreview {
                                logoPreview
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 48)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .padding(.top, 4)
                            }
                        } else {
                            Button(action: { showingSubscription = true }) {
                                HStack {
                                    Image(systemName: "crown.fill")
                                        .font(.caption)
                                    Text("Upgrade to Pro to upload custom logos")
                                        .font(.subheadline)
                                }
                                .foregroundStyle(.yellow)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.yellow.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Logo")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } footer: {
                if !subscriptionManager.canUploadLogo {
                    Text("Logo customization is a Pro feature")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section {
                WidgetPreviewView(
                    config: config,
                    stats: availableStats.isEmpty ? sampleStats : availableStats
                )
                .padding(.vertical, 8)
            } header: {
                Text("Preview")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            }
            .frame(maxWidth: maxContentWidth)
            Spacer()
        }
        .navigationTitle("Edit Widget")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveConfiguration()
                }
                .fontWeight(.semibold)
            }
        }
        .onAppear {
            if let data = config.styling.logoImageData,
               let uiImage = UIImage(data: data) {
                logoPreview = Image(uiImage: uiImage)
            } else if !config.styling.logoURL.isEmpty {
                // Download logo if URL exists but no image data
                downloadLogoFromURL(config.styling.logoURL)
            }
            testConnection()
        }
        .onChange(of: config.styling.logoURL) { _, newURL in
            if subscriptionManager.canUploadLogo {
                downloadLogoFromURL(newURL)
            }
        }
        .onChange(of: config.styling.showsLogo) { _, newValue in
            if newValue && !subscriptionManager.canUploadLogo {
                // Reset logo if user tries to enable without Pro
                config.styling.showsLogo = false
            }
        }
        .onChange(of: selectedLogoItem) { _, newItem in
            guard let item = newItem, subscriptionManager.canUploadLogo else {
                if !subscriptionManager.canUploadLogo {
                    showingSubscription = true
                }
                return
            }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    config.styling.logoImageData = data
                    if let uiImage = UIImage(data: data) {
                        logoPreview = Image(uiImage: uiImage)
                    }
                }
            }
        }
        .sheet(isPresented: $showingSubscription) {
            SubscriptionView()
        }
        .task {
            await subscriptionManager.checkSubscriptionStatus()
            // If user doesn't have Pro and has a logo, disable it
            if !subscriptionManager.canUploadLogo && config.styling.showsLogo {
                config.styling.showsLogo = false
            }
            // If refresh interval is not allowed, set to minimum
            if !subscriptionManager.allowedRefreshIntervals.contains(config.refreshInterval) {
                config.refreshInterval = .twoHours
            }
        }
    }
    
    private func testConnection() {
        isTestingConnection = true
        testError = nil
        
        Task {
            do {
                let response = try await APIService.shared.fetchStats(config: config)
                await MainActor.run {
                    availableStats = response.stats
                    isTestingConnection = false
                }
            } catch {
                await MainActor.run {
                    testError = error.localizedDescription
                    isTestingConnection = false
                }
            }
        }
    }
    
    private func downloadLogoFromURL(_ urlString: String) {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed) else {
            // Clear preview if URL is invalid
            if trimmed.isEmpty && config.styling.logoImageData == nil {
                logoPreview = nil
            }
            return
        }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        config.styling.logoImageData = data
                        logoPreview = Image(uiImage: uiImage)
                    }
                }
            } catch {
                // If download fails, keep the URL but don't set imageData
                // The widget will try to load it via AsyncImage
                print("Failed to download logo: \(error.localizedDescription)")
            }
        }
    }
    
    private func saveConfiguration() {
        // Validate subscription limits before saving
        var configToSave = config
        
        // Remove logo if user doesn't have Pro
        if !subscriptionManager.canUploadLogo {
            configToSave.styling.showsLogo = false
            configToSave.styling.logoURL = ""
            configToSave.styling.logoImageData = nil
        }
        
        // Ensure refresh interval is allowed
        if !subscriptionManager.allowedRefreshIntervals.contains(configToSave.refreshInterval) {
            configToSave.refreshInterval = .twoHours
        }
        
        // Ensure logo is downloaded if URL is provided but not yet downloaded
        if !configToSave.styling.logoURL.isEmpty && configToSave.styling.logoImageData == nil {
            Task {
                await downloadLogoFromURLSync(configToSave.styling.logoURL)
                await MainActor.run {
                    ConfigurationManager.shared.saveConfiguration(configToSave)
                    reloadWidgets()
                    dismiss()
                }
            }
        } else {
            ConfigurationManager.shared.saveConfiguration(configToSave)
            reloadWidgets()
            dismiss()
        }
    }
    
    private func reloadWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: "StatlyWidget")
    }
    
    private func downloadLogoFromURLSync(_ urlString: String) async {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if UIImage(data: data) != nil {
                await MainActor.run {
                    config.styling.logoImageData = data
                }
            }
        } catch {
            print("Failed to download logo before save: \(error.localizedDescription)")
        }
    }
}
