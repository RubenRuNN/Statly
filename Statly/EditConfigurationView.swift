//
//  EditConfigurationView.swift
//  Statly
//
//  Created by Ruben Marques on 24/01/2026.
//

import SwiftUI
import PhotosUI
import UIKit

struct EditConfigurationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var config: StatlyWidgetConfiguration
    @State private var isTestingConnection = false
    @State private var testError: String?
    @State private var availableStats: [Stat] = []
    @State private var selectedLogoItem: PhotosPickerItem?
    @State private var logoPreview: Image?
    
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
        Form {
            Section("Basic Info") {
                TextField("Widget Name", text: $config.name)
                TextField("App Name", text: $config.styling.appName)
            }
            
            Section("Endpoint") {
                TextField("Endpoint URL", text: $config.endpointURL)
                    .textInputAutocapitalization(.never)
                SecureField("API Key", text: $config.apiKey)
                
                Button(action: testConnection) {
                    HStack {
                        Text("Refresh Stats")
                        if isTestingConnection {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                
                if let error = testError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            if !availableStats.isEmpty {
                Section("Available Statistics") {
                    ForEach(Array(availableStats.enumerated()), id: \.offset) { index, stat in
                        HStack {
                            Text(stat.label)
                            Spacer()
                            Text(stat.value)
                                .foregroundColor(.secondary)
                        }
                    }
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
                WidgetPreviewView(config: config, stats: availableStats.isEmpty ? sampleStats : availableStats)
            }
        }
        .navigationTitle("Edit Widget")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveConfiguration()
                }
            }
        }
        .onAppear {
            if let data = config.styling.logoImageData,
               let uiImage = UIImage(data: data) {
                logoPreview = Image(uiImage: uiImage)
            }
            testConnection()
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
    
    private func saveConfiguration() {
        ConfigurationManager.shared.saveConfiguration(config)
        dismiss()
    }
}
