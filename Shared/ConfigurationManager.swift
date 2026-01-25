//
//  ConfigurationManager.swift
//  Statly
//
//  Created by Ruben Marques on 24/01/2026.
//

import Foundation

class ConfigurationManager {
    static let shared = ConfigurationManager()
    
    private let configurationsKey = "widget_configurations"
    // Must match the App Group configured in both the app and widget extension entitlements.
    private let appGroupIdentifier = "group.com.swipeuplabs.statly"
    
    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    private init() {}
    
    // MARK: - Save/Load Configurations
    
    func saveConfiguration(_ config: StatlyWidgetConfiguration) {
        // Save logo image separately if it exists
        if let logoData = config.styling.logoImageData {
            saveLogoImage(logoData, for: config.id)
        } else {
            // If no logo data, delete existing logo if URL is also empty
            if config.styling.logoURL.isEmpty {
                deleteLogoImage(for: config.id)
            }
        }
        
        // Load existing configs and strip logoImageData for encoding
        guard let data = userDefaults?.data(forKey: configurationsKey),
              var configs = try? JSONDecoder().decode([StatlyWidgetConfiguration].self, from: data) else {
            // First time saving, create new array
            var configForEncoding = config
            configForEncoding.styling.logoImageData = nil
            if let encoded = try? JSONEncoder().encode([configForEncoding]) {
                userDefaults?.set(encoded, forKey: configurationsKey)
            }
            return
        }
        
        // Create a copy without logoImageData for JSON encoding
        var configForEncoding = config
        configForEncoding.styling.logoImageData = nil
        
        // Update or append the config
        if let index = configs.firstIndex(where: { $0.id == config.id }) {
            configs[index] = configForEncoding
        } else {
            configs.append(configForEncoding)
        }
        
        // Encode without logoImageData to avoid JSON size issues
        if let encoded = try? JSONEncoder().encode(configs) {
            userDefaults?.set(encoded, forKey: configurationsKey)
        }
    }
    
    func loadAllConfigurations() -> [StatlyWidgetConfiguration] {
        guard let data = userDefaults?.data(forKey: configurationsKey),
              let configs = try? JSONDecoder().decode([StatlyWidgetConfiguration].self, from: data) else {
            return []
        }
        // Load logo images separately and attach them to configurations
        return configs.map { config in
            var updatedConfig = config
            if let logoData = loadLogoImage(for: config.id) {
                updatedConfig.styling.logoImageData = logoData
            }
            return updatedConfig
        }
    }
    
    func loadConfiguration(id: UUID) -> StatlyWidgetConfiguration? {
        guard var config = loadAllConfigurations().first(where: { $0.id == id }) else {
            return nil
        }
        // Ensure logo image is loaded
        if let logoData = loadLogoImage(for: id) {
            config.styling.logoImageData = logoData
        }
        return config
    }
    
    func deleteConfiguration(id: UUID) {
        // Delete logo image
        deleteLogoImage(for: id)
        
        var configs = loadAllConfigurations()
        configs.removeAll(where: { $0.id == id })
        
        // Create configs without logoImageData for encoding
        let configsForEncoding = configs.map { config -> StatlyWidgetConfiguration in
            var configCopy = config
            configCopy.styling.logoImageData = nil
            return configCopy
        }
        
        if let encoded = try? JSONEncoder().encode(configsForEncoding) {
            userDefaults?.set(encoded, forKey: configurationsKey)
        }
    }
    
    // MARK: - Cache Stats
    
    func cacheStats(_ stats: StatsResponse, for configID: UUID) {
        let key = "cached_stats_\(configID.uuidString)"
        if let encoded = try? JSONEncoder().encode(stats) {
            userDefaults?.set(encoded, forKey: key)
        }
    }
    
    func loadCachedStats(for configID: UUID) -> StatsResponse? {
        let key = "cached_stats_\(configID.uuidString)"
        guard let data = userDefaults?.data(forKey: key),
              let stats = try? JSONDecoder().decode(StatsResponse.self, from: data) else {
            return nil
        }
        return stats
    }
    
    // MARK: - Logo Image Storage
    
    func saveLogoImage(_ imageData: Data, for configID: UUID) {
        let key = "logo_image_\(configID.uuidString)"
        userDefaults?.set(imageData, forKey: key)
    }
    
    func loadLogoImage(for configID: UUID) -> Data? {
        let key = "logo_image_\(configID.uuidString)"
        return userDefaults?.data(forKey: key)
    }
    
    func deleteLogoImage(for configID: UUID) {
        let key = "logo_image_\(configID.uuidString)"
        userDefaults?.removeObject(forKey: key)
    }
}
