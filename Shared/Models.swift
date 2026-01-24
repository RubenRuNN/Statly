//
//  Models.swift
//  Statly
//
//  Created by Ruben Marques on 24/01/2026.
//

import Foundation
import SwiftUI
import UIKit

// MARK: - API Response Models
struct StatsResponse: Codable {
    let stats: [Stat]
    let updatedAt: String?
}

struct Stat: Codable, Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let trend: String?
    let trendDirection: TrendDirection?
    
    enum CodingKeys: String, CodingKey {
        case label, value, trend, trendDirection
    }
}

enum TrendDirection: String, Codable {
    case up, down, neutral
    
    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .neutral: return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .up: return "↑"
        case .down: return "↓"
        case .neutral: return "→"
        }
    }
}

// MARK: - Widget Configuration
struct StatlyWidgetConfiguration: Codable, Identifiable {
    let id: UUID
    var name: String
    var endpointURL: String
    var apiKey: String
    var refreshInterval: RefreshInterval
    var selectedStatIndices: [Int]
    var customLabels: [Int: String] // Map stat index to custom label
    var styling: WidgetStyling
    
    init(
        id: UUID = UUID(),
        name: String = "My Widget",
        endpointURL: String = "",
        apiKey: String = "",
        refreshInterval: RefreshInterval = .fifteenMinutes,
        selectedStatIndices: [Int] = [],
        customLabels: [Int: String] = [:],
        styling: WidgetStyling = WidgetStyling()
    ) {
        self.id = id
        self.name = name
        self.endpointURL = endpointURL
        self.apiKey = apiKey
        self.refreshInterval = refreshInterval
        self.selectedStatIndices = selectedStatIndices
        self.customLabels = customLabels
        self.styling = styling
    }
}

enum RefreshInterval: Int, Codable, CaseIterable {
    case fiveMinutes = 5
    case fifteenMinutes = 15
    case thirtyMinutes = 30
    case oneHour = 60
    case twoHours = 120
    
    var displayName: String {
        switch self {
        case .fiveMinutes: return "5 minutes"
        case .fifteenMinutes: return "15 minutes"
        case .thirtyMinutes: return "30 minutes"
        case .oneHour: return "1 hour"
        case .twoHours: return "2 hours"
        }
    }
    
    var timeInterval: TimeInterval {
        return TimeInterval(self.rawValue * 60)
    }
}

struct WidgetStyling: Codable {
    var backgroundColor: String
    var primaryTextColor: String
    var valueTextColor: String
    var trendUpColor: String
    var trendDownColor: String
    var trendNeutralColor: String
    var logoURL: String
    var appName: String
    var showsLogo: Bool
    var showsAppName: Bool
    var logoImageData: Data?
    
    init(
        backgroundColor: String = "#1C1C1E",
        primaryTextColor: String = "#8E8E93",
        valueTextColor: String = "#FFFFFF",
        trendUpColor: String = "#34C759",
        trendDownColor: String = "#FF3B30",
        trendNeutralColor: String = "#8E8E93",
        logoURL: String = "",
        appName: String = "My App",
        showsLogo: Bool = true,
        showsAppName: Bool = true,
        logoImageData: Data? = nil
    ) {
        self.backgroundColor = backgroundColor
        self.primaryTextColor = primaryTextColor
        self.valueTextColor = valueTextColor
        self.trendUpColor = trendUpColor
        self.trendDownColor = trendDownColor
        self.trendNeutralColor = trendNeutralColor
        self.logoURL = logoURL
        self.appName = appName
        self.showsLogo = showsLogo
        self.showsAppName = showsAppName
        self.logoImageData = logoImageData
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else { return "#000000" }
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
