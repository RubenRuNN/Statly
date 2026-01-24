//
//  ConfigurationListView.swift
//  Statly
//
//  Created by Ruben Marques on 24/01/2026.
//

import SwiftUI

struct ConfigurationListView: View {
    @State private var configurations: [StatlyWidgetConfiguration] = []
    @State private var showingAddConfig = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(configurations) { config in
                    NavigationLink(destination: EditConfigurationView(configuration: config)) {
                        ConfigurationRow(configuration: config)
                    }
                }
                .onDelete(perform: deleteConfigurations)
            }
            .navigationTitle("Statly Widgets")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddConfig = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddConfig) {
                CreateConfigurationView { newConfig in
                    configurations.append(newConfig)
                }
            }
            .onAppear {
                loadConfigurations()
            }
        }
    }
    
    private func loadConfigurations() {
        configurations = ConfigurationManager.shared.loadAllConfigurations()
    }
    
    private func deleteConfigurations(at offsets: IndexSet) {
        for index in offsets {
            ConfigurationManager.shared.deleteConfiguration(id: configurations[index].id)
        }
        configurations.remove(atOffsets: offsets)
    }
}

struct ConfigurationRow: View {
    let configuration: StatlyWidgetConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(configuration.name)
                .font(.headline)
            Text(configuration.styling.appName)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(configuration.endpointURL)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
    }
}
