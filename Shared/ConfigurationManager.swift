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
    private let appGroupIdentifier = "group.com.yourcompany.statly" // Change this!
    
    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    private init() {}
    
    // MARK: - Save/Load Configurations
    
    func saveConfiguration(_ config: WidgetConfiguration) {
        var configs = loadAllConfigurations()
        
        if let index = configs.firstIndex(where: { $0.id == config.id }) {
            configs[index] = config
        } else {
            configs.append(config)
        }
        
        if let encoded = try? JSONEncoder().encode(configs) {
            userDefaults?.set(encoded, forKey: configurationsKey)
        }
    }
    
    func loadAllConfigurations() -> [WidgetConfiguration] {
        guard let data = userDefaults?.data(forKey: configurationsKey),
              let configs = try? JSONDecoder().decode([WidgetConfiguration].self, from: data) else {
            return []
        }
        return configs
    }
    
    func loadConfiguration(id: UUID) -> WidgetConfiguration? {
        return loadAllConfigurations().first(where: { $0.id == id })
    }
    
    func deleteConfiguration(id: UUID) {
        var configs = loadAllConfigurations()
        configs.removeAll(where: { $0.id == id })
        
        if let encoded = try? JSONEncoder().encode(configs) {
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
}
