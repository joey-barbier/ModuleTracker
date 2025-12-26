import Foundation

/// Metrics for a target within a module
struct TargetMetrics: Codable {
    let name: String
    let customFields: [String: AnyCodable]

    init(name: String, customFields: [String: Any] = [:]) {
        self.name = name
        self.customFields = customFields.mapValues { AnyCodable($0) }
    }
}

/// Metrics for a module - 100% data-driven via customFields
struct ModuleMetrics: Codable {
    let name: String
    let path: String
    let source: String
    let isModularized: Bool
    let targets: [TargetMetrics]
    let customFields: [String: AnyCodable]

    init(
        name: String,
        path: String,
        source: String,
        isModularized: Bool,
        targets: [TargetMetrics] = [],
        customFields: [String: Any] = [:]
    ) {
        self.name = name
        self.path = path
        self.source = source
        self.isModularized = isModularized
        self.targets = targets
        self.customFields = customFields.mapValues { AnyCodable($0) }
    }
}

/// Output structure for JSON export
struct TrackerOutput: Codable {
    let generatedAt: String
    let rulesVersion: String
    let modulesCount: Int
    let fieldsMeta: [String: FieldMetadata]
    let modules: [ModuleMetrics]
}
