//
//  StatlyWidgetIntent.swift
//  StatlyWidgetExtension
//
//  AppIntent used to let the user pick which
//  Statly widget configuration a widget instance uses.
//

import AppIntents

// MARK: - AppEntity representing one saved widget configuration from the app.

struct StatlyConfigurationEntity: AppEntity, Identifiable {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Statly Widget")
    }

    static var defaultQuery = StatlyConfigurationQuery()

    let id: UUID
    let name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct StatlyConfigurationQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [StatlyConfigurationEntity] {
        let all = ConfigurationManager.shared.loadAllConfigurations()
        return all
            .filter { config in identifiers.contains(config.id) }
            .map { StatlyConfigurationEntity(id: $0.id, name: $0.name) }
    }

    func suggestedEntities() async throws -> [StatlyConfigurationEntity] {
        ConfigurationManager.shared
            .loadAllConfigurations()
            .map { StatlyConfigurationEntity(id: $0.id, name: $0.name) }
    }
}

struct StatlyWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Statly Widget"
    static var description = IntentDescription("Choose which Statly configuration this widget displays.")

    /// The configuration created in the Statly app, chosen from a list.
    @Parameter(title: "Configuration")
    var configuration: StatlyConfigurationEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Show configuration \(\.$configuration)")
    }
}


