//
//  EditConfigurationView.swift
//  Statly
//
//  Created by Ruben Marques on 24/01/2026.
//

import SwiftUI

struct EditConfigurationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var config: WidgetConfiguration
    @State private var isTestingConnection = false
    @State private var testError: String?
    @State private var availableStats: [Stat] = []
    
    init(configuration: WidgetConfiguration) {
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
                TextField("Logo URL", text: $config.styling.logoURL)
                    .textInputAutocapitalization(.never)
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
            testConnection()
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
