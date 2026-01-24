//
//  CreateConfigurationView.swift
//  Statly
//
//  Created by Ruben Marques on 24/01/2026.
//

import SwiftUI

struct CreateConfigurationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var config = WidgetConfiguration()
    @State private var isTestingConnection = false
    @State private var testError: String?
    @State private var testSuccess = false
    
    let onSave: (WidgetConfiguration) -> Void
    
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
                    TextField("Logo URL", text: $config.styling.logoURL)
                        .textInputAutocapitalization(.never)
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
                _ = try await APIService.shared.testEndpoint(
                    url: config.endpointURL,
                    apiKey: config.apiKey
                )
                await MainActor.run {
                    testSuccess = true
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
