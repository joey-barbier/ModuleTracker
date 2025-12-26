import Foundation

/// Orchestrator that coordinates all detection rules via RulesRegistry.
/// By default, no rules are registered - projects add their own via Bootstrap.
struct RulesEngine {

    /// Returns all field metadata from registered rules
    static func allFieldsMetadata() -> [FieldMetadata] {
        RulesRegistry.shared.allFieldsMetadata()
    }

    /// Returns field metadata as dictionary
    static func fieldsMetadataDict() -> [String: FieldMetadata] {
        Dictionary(uniqueKeysWithValues: allFieldsMetadata().map { ($0.id, $0) })
    }

    // MARK: - Module Analysis

    /// Analyze a module - applies all registered rules
    func analyze(module: ModuleInfo) -> ModuleMetrics {
        // Analyze each target
        let targets = module.targets.map { target in
            analyzeTarget(target: target, modulePath: module.path)
        }

        // Apply module-level rules
        let customFields = RulesRegistry.shared.applyToModule(module)

        return ModuleMetrics(
            name: module.name,
            path: module.path.path,
            source: module.source,
            isModularized: !module.targets.isEmpty,
            targets: targets,
            customFields: customFields
        )
    }

    // MARK: - Target Analysis

    private func analyzeTarget(target: TargetInfo, modulePath: URL) -> TargetMetrics {
        let customFields = RulesRegistry.shared.applyToTarget(target, modulePath: modulePath)
        return TargetMetrics(name: target.name, customFields: customFields)
    }
}
