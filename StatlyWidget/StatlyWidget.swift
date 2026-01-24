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
struct StatlyWidgetProvider: TimelineProvider {
    typealias Entry = StatlyEntry
    
    func placeholder(in context: Context) -> StatlyEntry {
        StatlyEntry(
            date: Date(),
            configuration: createSampleConfig(),
            stats: createSampleStats(),
            error: nil
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (StatlyEntry) -> Void) {
        let entry = StatlyEntry(
            date: Date(),
            configuration: createSampleConfig(),
            stats: createSampleStats(),
            error: nil
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<StatlyEntry>) -> Void) {
        Task {
            await fetchAndCreateTimeline(context: context, completion: completion)
        }
    }
    
    private func fetchAndCreateTimeline(
        context: Context,
        completion: @escaping (Timeline<StatlyEntry>) -> Void
    ) async {
        let configurations = ConfigurationManager.shared.loadAllConfigurations()
        
        guard let config = configurations.first else {
            let entry = StatlyEntry(
                date: Date(),
                configuration: nil,
                stats: nil,
                error: "No widget configured"
            )
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
            completion(timeline)
            return
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
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
            
        } catch {
            if let cachedStats = ConfigurationManager.shared.loadCachedStats(for: config.id) {
                let entry = StatlyEntry(
                    date: Date(),
                    configuration: config,
                    stats: cachedStats,
                    error: "Using cached data"
                )
                let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(300)))
                completion(timeline)
            } else {
                let entry = StatlyEntry(
                    date: Date(),
                    configuration: config,
                    stats: nil,
                    error: error.localizedDescription
                )
                let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(300)))
                completion(timeline)
            }
        }
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
                ErrorView(error: error, config: entry.configuration)
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
    }
}

// MARK: - Widget
@main
struct StatlyWidget: Widget {
    let kind = "StatlyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StatlyWidgetProvider()) { entry in
            StatlyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Statly")
        .description("Display your SaaS statistics")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
