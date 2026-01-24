//
//  CreateConfigurationView.swift
//  Statly
//
//  Created by Ruben Marques on 24/01/2026.
//

import SwiftUI
import PhotosUI
import UIKit

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
                Section("Basic Info") {
                    TextField("Widget Name", text: $config.name)
                    TextField("App Name", text: $config.styling.appName)
                }
                
                Section("Endpoint") {
                    TextField("Endpoint URL", text: $config.endpointURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    SecureField("API Key", text: $config.apiKey)
                    
                    Button(action: testConnection) {
                        HStack {
                            Text("Test Connection")
                            if isTestingConnection {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(config.endpointURL.isEmpty || config.apiKey.isEmpty || isTestingConnection)
                    
                    if let error = testError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    if testSuccess {
                        Label("Connection successful!", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                
                Section("Refresh Interval") {
                    Picker("Refresh", selection: $config.refreshInterval) {
                        ForEach(RefreshInterval.allCases, id: \.self) { interval in
                            Text(interval.displayName).tag(interval)
                        }
                    }
                }
                
                Section("Colors") {
                    ColorPickerRow(title: "Background", color: $config.styling.backgroundColor)
                    ColorPickerRow(title: "Labels", color: $config.styling.primaryTextColor)
                    ColorPickerRow(title: "Values", color: $config.styling.valueTextColor)
                }
                
                Section("Logo") {
                    Toggle("Show logo", isOn: $config.styling.showsLogo)
                    Toggle("Show app name", isOn: $config.styling.showsAppName)
                    
                    PhotosPicker("Pick logo from Photos", selection: $selectedLogoItem, matching: .images)
                        .disabled(!config.styling.showsLogo)
                    
                    TextField("Logo URL (optional)", text: $config.styling.logoURL)
                        .textInputAutocapitalization(.never)
                        .disabled(!config.styling.showsLogo)
                    
                    if let logoPreview {
                        logoPreview
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                
                Section("Preview") {
                    WidgetPreviewView(config: config, stats: testSuccess ? availableStats : sampleStats)
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
    
    private func saveConfiguration() {
        ConfigurationManager.shared.saveConfiguration(config)
        onSave(config)
        dismiss()
    }
}

struct ColorPickerRow: View {
    let title: String
    @Binding var color: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            ColorPicker("", selection: Binding(
                get: { Color(hex: color) },
                set: { color = $0.toHex() }
            ))
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
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Small Widget Preview")
                .font(.caption)
                .foregroundColor(.secondary)
            SmallWidgetView(
                config: config,
                stats: statsResponse,
                date: Date()
            )
            .frame(height: 155)
            .background(Color(hex: config.styling.backgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.vertical, 8)
    }
}
