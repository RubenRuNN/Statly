import WidgetKit
import SwiftUI

// MARK: - Widget Entry
struct StatlyEntry: TimelineEntry {
    let date: Date
    let configuration: StatlyWidgetConfiguration?
    let stats: StatsResponse?
    let error: String?
}

// MARK: - Widget Provider
struct StatlyWidgetProvider: AppIntentTimelineProvider {
    typealias Entry = StatlyEntry

    func placeholder(in context: Context) -> StatlyEntry {
        StatlyEntry(
            date: Date(),
            configuration: createSampleConfig(),
            stats: createSampleStats(),
            error: nil
        )
    }

    func snapshot(for configurationIntent: StatlyWidgetConfigurationIntent, in context: Context) async -> StatlyEntry {
        StatlyEntry(
            date: Date(),
            configuration: createSampleConfig(),
            stats: createSampleStats(),
            error: nil
        )
    }

    func timeline(for configurationIntent: StatlyWidgetConfigurationIntent, in context: Context) async -> Timeline<StatlyEntry> {
        let configurations = ConfigurationManager.shared.loadAllConfigurations()

        // No configurations saved at all → show "No Widget Configured" view.
        guard !configurations.isEmpty else {
            let entry = StatlyEntry(
                date: Date(),
                configuration: nil,
                stats: nil,
                error: nil
            )
            let next = Date().addingTimeInterval(3600)
            return Timeline(entries: [entry], policy: .after(next))
        }

        // User hasn't picked a configuration in the widget edit sheet yet.
        guard let selected = configurationIntent.configuration else {
            let entry = StatlyEntry(
                date: Date(),
                configuration: nil,
                stats: nil,
                error: "Select a widget"
            )
            let next = Date().addingTimeInterval(300)
            return Timeline(entries: [entry], policy: .after(next))
        }

        guard var config = configuration(id: selected.id, in: configurations) else {
            let entry = StatlyEntry(
                date: Date(),
                configuration: nil,
                stats: nil,
                error: "Select a widget"
            )
            let next = Date().addingTimeInterval(300)
            return Timeline(entries: [entry], policy: .after(next))
        }
        
        // Ensure logo image is loaded from separate storage
        if let logoData = ConfigurationManager.shared.loadLogoImage(for: config.id) {
            config.styling.logoImageData = logoData
        }

        do {
            let stats = try await APIService.shared.fetchStats(config: config)
            ConfigurationManager.shared.cacheStats(stats, for: config.id)

            let entry = StatlyEntry(
                date: Date(),
                configuration: config,
                stats: stats,
                error: nil
            )

            let nextUpdate = Date().addingTimeInterval(config.refreshInterval.timeInterval)
            return Timeline(entries: [entry], policy: .after(nextUpdate))
        } catch {
            if let cachedStats = ConfigurationManager.shared.loadCachedStats(for: config.id) {
                let entry = StatlyEntry(
                    date: Date(),
                    configuration: config,
                    stats: cachedStats,
                    error: "Using cached data"
                )
                let next = Date().addingTimeInterval(300)
                return Timeline(entries: [entry], policy: .after(next))
            } else {
                let entry = StatlyEntry(
                    date: Date(),
                    configuration: config,
                    stats: nil,
                    error: error.localizedDescription
                )
                let next = Date().addingTimeInterval(300)
                return Timeline(entries: [entry], policy: .after(next))
            }
        }
    }

    private func configuration(id: UUID,
                               in configurations: [StatlyWidgetConfiguration]) -> StatlyWidgetConfiguration? {
        configurations.first { $0.id == id }
    }

    private func createSampleConfig() -> StatlyWidgetConfiguration {
        StatlyWidgetConfiguration(
            name: "Sample Widget",
            endpointURL: "https://api.example.com/stats",
            apiKey: "sample-key",
            styling: WidgetStyling(
                backgroundColor: "#1C1C1E",
                primaryTextColor: "#8E8E93",
                valueTextColor: "#FFFFFF",
                logoURL: "",
                appName: "My SaaS"
            )
        )
    }

    private func createSampleStats() -> StatsResponse {
        StatsResponse(
            stats: [
                Stat(label: "USERS", value: "1,234", trend: "+12%", trendDirection: .up),
                Stat(label: "REVENUE", value: "$45.2K", trend: "-5%", trendDirection: .down),
                Stat(label: "CONVERSIONS", value: "89", trend: "0%", trendDirection: .neutral)
            ],
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
    }
}

// MARK: - Widget Entry View
struct StatlyWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    let entry: StatlyEntry

    var body: some View {
        Group {
            if let error = entry.error, entry.stats == nil {
                if error == "Select a widget" {
                    NoConfigSelectedView()
                } else {
                    ErrorView(error: error, config: entry.configuration)
                }
            } else if let config = entry.configuration, let stats = entry.stats {
                switch widgetFamily {
                case .systemSmall:
                    SmallWidgetView(config: config, stats: stats, date: entry.date)
                case .systemMedium:
                    MediumWidgetView(config: config, stats: stats, date: entry.date)
                case .systemLarge:
                    LargeWidgetView(config: config, stats: stats, date: entry.date)
                default:
                    EmptyView()
                }
            } else {
                NoConfigView()
            }
        }
        .containerBackground(for: .widget) {
            if let config = entry.configuration {
                Color(hex: config.styling.backgroundColor)
            } else {
                Color.black
            }
        }
    }
}

// MARK: - Widget
@main
struct StatlyWidget: Widget {
    let kind = "StatlyWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind,
                               intent: StatlyWidgetConfigurationIntent.self,
                               provider: StatlyWidgetProvider()) { entry in
            StatlyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Statly")
        .description("Display your SaaS statistics")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

