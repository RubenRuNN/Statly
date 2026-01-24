//
//  WidgetViews.swift
//  Statly
//
//  Created by Ruben Marques on 24/01/2026.
//

import SwiftUI
import WidgetKit
import UIKit

// MARK: - Shared time formatting

private let statlyISOFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

private let statlyTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter
}()

private func updatedTimeText(from updatedAt: String?) -> String? {
    guard let updatedAt,
          let date = statlyISOFormatter.date(from: updatedAt) else {
        return nil
    }
    let time = statlyTimeFormatter.string(from: date)
    return "Updated at \(time)"
}

// MARK: - Widget Header
struct WidgetHeader: View {
    let config: StatlyWidgetConfiguration
    let date: Date
    let compact: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            // Logo
            if config.styling.showsLogo {
                if let data = config.styling.logoImageData,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: compact ? 16 : 20, height: compact ? 16 : 20)
                        .clipShape(Circle())
                } else {
                    let trimmed = config.styling.logoURL
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty, let url = URL(string: trimmed) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            case .failure(_), .empty:
                                Circle()
                                    .fill(Color(hex: config.styling.primaryTextColor).opacity(0.3))
                            @unknown default:
                                Circle()
                                    .fill(Color(hex: config.styling.primaryTextColor).opacity(0.3))
                            }
                        }
                        .frame(width: compact ? 16 : 20, height: compact ? 16 : 20)
                        .clipShape(Circle())
                    }
                }
            }
            
            // App Name
            if config.styling.showsAppName {
                Text(config.styling.appName)
                    .font(compact ? .caption : .subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: config.styling.valueTextColor))
            }
            
            Spacer()
        }
        .padding(.horizontal, compact ? 12 : 16)
        .padding(.vertical, compact ? 8 : 10)
    }
}

// MARK: - Stat Item View
struct StatItemView: View {
    let stat: Stat
    let config: StatlyWidgetConfiguration
    let compact: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 2 : 4) {
            // Label
            Text(stat.label.uppercased())
                .font(compact ? .caption2 : .caption)
                .fontWeight(.medium)
                .foregroundColor(Color(hex: config.styling.primaryTextColor))
                .lineLimit(1)
            
            // Value
            Text(stat.value)
                .font(compact ? .title3 : .title2)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: config.styling.valueTextColor))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            // Trend
            if let trend = stat.trend, let direction = stat.trendDirection {
                HStack(spacing: 4) {
                    Text(direction.icon)
                        .font(compact ? .caption2 : .caption)
                    Text(trend)
                        .font(compact ? .caption2 : .caption)
                }
                .foregroundColor(trendColor(direction, config: config))
            }
        }
    }
    
    private func trendColor(_ direction: TrendDirection, config: StatlyWidgetConfiguration) -> Color {
        switch direction {
        case .up:
            return Color(hex: config.styling.trendUpColor)
        case .down:
            return Color(hex: config.styling.trendDownColor)
        case .neutral:
            return Color(hex: config.styling.trendNeutralColor)
        }
    }
}

// MARK: - Small Widget (2x2)
struct SmallWidgetView: View {
    let config: StatlyWidgetConfiguration
    let stats: StatsResponse
    let date: Date

    private var updatedText: String? {
        updatedTimeText(from: stats.updatedAt)
    }
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                WidgetHeader(config: config, date: date, compact: true)
                
                Spacer()
                
                // Show first stat only
                if let firstStat = stats.stats.first {
                    StatItemView(stat: firstStat, config: config, compact: false)
                        .padding(.horizontal, 16)
                }

                Spacer(minLength: 4)

                if let updated = updatedText {
                    Text(updated)
                        .font(.caption2)
                        .foregroundColor(Color(hex: config.styling.primaryTextColor))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 6)
                }
            }
        }
    }
}

// MARK: - Medium Widget (4x2)
struct MediumWidgetView: View {
    let config: StatlyWidgetConfiguration
    let stats: StatsResponse
    let date: Date
    
    private var updatedText: String? {
        updatedTimeText(from: stats.updatedAt)
    }
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                WidgetHeader(config: config, date: date, compact: false)
                
                Spacer()
                
                // Show up to 3 stats in a row
                HStack(alignment: .top, spacing: 16) {
                    ForEach(Array(stats.stats.prefix(3))) { stat in
                        StatItemView(stat: stat, config: config, compact: true)
                        if stat.id != stats.stats.prefix(3).last?.id {
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer(minLength: 4)
                
                if let updated = updatedText {
                    Text(updated)
                        .font(.caption2)
                        .foregroundColor(Color(hex: config.styling.primaryTextColor))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 6)
                }
            }
        }
    }
}

// MARK: - Large Widget (4x4)
struct LargeWidgetView: View {
    let config: StatlyWidgetConfiguration
    let stats: StatsResponse
    let date: Date
    
    private var updatedText: String? {
        updatedTimeText(from: stats.updatedAt)
    }
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 12) {
                WidgetHeader(config: config, date: date, compact: false)
                
                // Show up to 6 stats in a 2x3 grid
                VStack(spacing: 16) {
                    ForEach(0..<2) { row in
                        HStack(alignment: .top, spacing: 16) {
                            ForEach(0..<3) { col in
                                let index = row * 3 + col
                                if index < stats.stats.count {
                                    StatItemView(
                                        stat: stats.stats[index],
                                        config: config,
                                        compact: true
                                    )
                                    if col < 2 {
                                        Spacer()
                                    }
                                } else {
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer(minLength: 4)
                
                if let updated = updatedText {
                    Text(updated)
                        .font(.caption2)
                        .foregroundColor(Color(hex: config.styling.primaryTextColor))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
            }
        }
    }
}

// MARK: - Error View
struct ErrorView: View {
    let error: String
    let config: StatlyWidgetConfiguration?
    
    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title)
                    .foregroundColor(.orange)
                
                Text("Unable to load stats")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                Text(error)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            .padding()
            }    
        }
    }
}


// MARK: - No Config Selected View
struct NoConfigSelectedView: View {
    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                Image(systemName: "gear.badge.questionmark")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                
                Text("No Widget Configured")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("Edit widget to select a configuration.")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
        }
    }
}


// MARK: - No Config View
struct NoConfigView: View {
    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                Image(systemName: "gear.badge.questionmark")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                
                Text("No Widget Configured")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("Open the Statly app to create a widget")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
        }
    }
}

// MARK: - Previews
struct StatlyWidget_Previews: PreviewProvider {
    static var previews: some View {
        let sampleConfig = StatlyWidgetConfiguration(
            name: "Sample",
            endpointURL: "https://api.example.com",
            apiKey: "key",
            styling: WidgetStyling(
                backgroundColor: "#1C1C1E",
                primaryTextColor: "#8E8E93",
                valueTextColor: "#FFFFFF",
                appName: "MenuRápido"
            )
        )

        let sampleStats = StatsResponse(
            stats: [
                Stat(label: "REGISTOS", value: "1", trend: "+0", trendDirection: .down),
                Stat(label: "RESTAURANTES", value: "1", trend: "+0", trendDirection: .down),
                Stat(label: "SUBSCRIÇÕES", value: "0", trend: "+0", trendDirection: .neutral),
                Stat(label: "REVENUE", value: "$12.5K", trend: "+15%", trendDirection: .up),
                Stat(label: "CONVERSIONS", value: "234", trend: "+8%", trendDirection: .up),
                Stat(label: "USERS", value: "1.2K", trend: "-2%", trendDirection: .down)
            ],
            updatedAt: "2024-01-24T09:46:00Z"
        )

        Group {
            // Small Widget
            SmallWidgetView(config: sampleConfig, stats: sampleStats, date: Date())
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small")

            // Medium Widget
            MediumWidgetView(config: sampleConfig, stats: sampleStats, date: Date())
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium")

            // Large Widget
            LargeWidgetView(config: sampleConfig, stats: sampleStats, date: Date())
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .previewDisplayName("Large")

            // Error State
            ErrorView(error: "Network error", config: sampleConfig)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Error")
        }
    }
}
