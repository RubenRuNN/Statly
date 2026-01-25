//
//  CreateConfigurationView.swift
//  Statly
//
//  Created by Ruben Marques on 24/01/2026.
//

import SwiftUI
import PhotosUI
import UIKit
import WidgetKit

struct CreateConfigurationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var config = StatlyWidgetConfiguration()
    @State private var isTestingConnection = false
    @State private var testError: String?
    @State private var testSuccess = false
    @State private var selectedLogoItem: PhotosPickerItem?
    @State private var logoPreview: Image?
    @State private var availableStats: [Stat] = []
    
    let onSave: (StatlyWidgetConfiguration) -> Void
    
    private var sampleStats: [Stat] {
        [
            Stat(label: "USERS", value: "1,234", trend: "+12%", trendDirection: .up),
            Stat(label: "MRR", value: "$45.2K", trend: "-5%", trendDirection: .down),
            Stat(label: "CONVERSIONS", value: "89", trend: "0%", trendDirection: .neutral)
        ]
    }
    
    var body: some View {
        NavigationView {
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
                                Label("Test Connection", systemImage: "network")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                if isTestingConnection {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }
                        }
                        .disabled(config.endpointURL.isEmpty || config.apiKey.isEmpty || isTestingConnection)
                        .foregroundStyle(isValid ? Color.accentColor : Color.secondary)
                        
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
                        
                        if testSuccess {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                Text("Connection successful!")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.green)
                            .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Endpoint")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if testSuccess && !availableStats.isEmpty {
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
                        ForEach(RefreshInterval.allCases, id: \.self) { interval in
                            Text(interval.displayName).tag(interval)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Refresh Interval")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
                        Toggle("Show app name", isOn: $config.styling.showsAppName)
                        
                        if config.styling.showsLogo {
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
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Logo")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Section {
                    WidgetPreviewView(
                        config: config,
                        stats: testSuccess ? availableStats : sampleStats
                    )
                    .padding(.vertical, 8)
                } header: {
                    Text("Preview")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New Widget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveConfiguration()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
        }
        .onChange(of: selectedLogoItem) { _, newItem in
            guard let item = newItem else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    config.styling.logoImageData = data
                    if let uiImage = UIImage(data: data) {
                        logoPreview = Image(uiImage: uiImage)
                    }
                }
            }
        }
        .onChange(of: config.styling.logoURL) { _, newURL in
            downloadLogoFromURL(newURL)
        }
    }
    
    private var isValid: Bool {
        !config.name.isEmpty &&
        !config.endpointURL.isEmpty &&
        !config.apiKey.isEmpty &&
        testSuccess
    }
    
    private func testConnection() {
        isTestingConnection = true
        testError = nil
        testSuccess = false
        
        Task {
            do {
                let response = try await APIService.shared.testEndpoint(
                    url: config.endpointURL,
                    apiKey: config.apiKey
                )
                await MainActor.run {
                    testSuccess = true
                    isTestingConnection = false
                    availableStats = response.stats
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
            if trimmed.isEmpty {
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
        // Ensure logo is downloaded if URL is provided but not yet downloaded
        if !config.styling.logoURL.isEmpty && config.styling.logoImageData == nil {
            Task {
                await downloadLogoFromURLSync(config.styling.logoURL)
                await MainActor.run {
                    ConfigurationManager.shared.saveConfiguration(config)
                    onSave(config)
                    reloadWidgets()
                    dismiss()
                }
            }
        } else {
            ConfigurationManager.shared.saveConfiguration(config)
            onSave(config)
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

struct ColorPickerRow: View {
    let title: String
    @Binding var color: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.subheadline)
            Spacer()
            ColorPicker("", selection: Binding(
                get: { Color(hex: color) },
                set: { color = $0.toHex() }
            ))
            .labelsHidden()
        }
    }
}

// MARK: - Widget Preview
struct WidgetPreviewView: View {
    let config: StatlyWidgetConfiguration
    let stats: [Stat]
    
    private var statsResponse: StatsResponse {
        StatsResponse(
            stats: stats,
            updatedAt: Date().ISO8601Format()
        )
    }
    
    private var displayStats: [Stat] {
        config.getSelectedStats(from: stats)
    }
    
    // iOS widget dimensions (approximate)
    private let widgetSize: CGFloat = 155 // Small widget is ~155x155 points
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Small Widget Preview")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if !config.selectedStatIndices.isEmpty {
                    Text("\(config.selectedStatIndices.count) selected")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            
            // Exact widget preview matching iOS widget appearance
            ZStack {
                // Background color - must match widget's containerBackground
                Color(hex: config.styling.backgroundColor)
                    .ignoresSafeArea()
                
                // Actual widget view content
                SmallWidgetView(
                    config: config,
                    stats: StatsResponse(
                        stats: displayStats.isEmpty ? stats : displayStats,
                        updatedAt: statsResponse.updatedAt
                    ),
                    date: Date()
                )
            }
            .frame(width: widgetSize, height: widgetSize)
            .clipShape(RoundedRectangle(cornerRadius: 22)) // iOS widget corner radius (~22pt for small)
            .overlay(
                // Subtle border to show widget boundaries in preview
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
            )
        }
    }
}
