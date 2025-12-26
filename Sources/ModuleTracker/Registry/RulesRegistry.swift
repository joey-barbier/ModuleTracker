import Foundation

/// Registry for detection rules.
/// Projects register their rules here via Bootstrap.
final class RulesRegistry {
    static let shared = RulesRegistry()

    private init() {}

    /// Target-level rules (applied to each target in SPM modules)
    private var targetRules: [(metadata: FieldMetadata, apply: (TargetInfo, URL) -> [String: Any])] = []

    /// Module-level rules (applied to legacy modules)
    private var moduleRules: [(metadata: FieldMetadata, apply: (ModuleInfo) -> [String: Any])] = []

    // MARK: - Registration

    /// Register a rule that applies to SPM targets
    /// - Parameters:
    ///   - metadata: Field metadata for UI generation
    ///   - apply: Closure that returns custom fields for a target
    func registerTargetRule(
        metadata: FieldMetadata,
        apply: @escaping (TargetInfo, URL) -> [String: Any]
    ) {
        targetRules.append((metadata, apply))
    }

    /// Register a rule that applies to legacy modules
    /// - Parameters:
    ///   - metadata: Field metadata for UI generation
    ///   - apply: Closure that returns custom fields for a module
    func registerModuleRule(
        metadata: FieldMetadata,
        apply: @escaping (ModuleInfo) -> [String: Any]
    ) {
        moduleRules.append((metadata, apply))
    }

    // MARK: - Metadata

    /// Returns all registered field metadata
    func allFieldsMetadata() -> [FieldMetadata] {
        let targetMeta = targetRules.map { $0.metadata }
        let moduleMeta = moduleRules.map { $0.metadata }
        // Deduplicate by id (same rule can be registered for both)
        var seen = Set<String>()
        return (targetMeta + moduleMeta).filter { seen.insert($0.id).inserted }
    }

    /// Returns field metadata as dictionary
    func fieldsMetadataDict() -> [String: FieldMetadata] {
        Dictionary(uniqueKeysWithValues: allFieldsMetadata().map { ($0.id, $0) })
    }

    // MARK: - Application

    /// Apply all target rules to a target
    /// - Parameters:
    ///   - target: The target to analyze
    ///   - modulePath: Path to the parent module
    /// - Returns: Custom fields dictionary
    func applyToTarget(_ target: TargetInfo, modulePath: URL) -> [String: Any] {
        targetRules.reduce(into: [:]) { result, rule in
            result.merge(rule.apply(target, modulePath)) { _, new in new }
        }
    }

    /// Apply all module rules to a legacy module
    /// - Parameter module: The module to analyze
    /// - Returns: Custom fields dictionary
    func applyToModule(_ module: ModuleInfo) -> [String: Any] {
        moduleRules.reduce(into: [:]) { result, rule in
            result.merge(rule.apply(module)) { _, new in new }
        }
    }

    /// Returns number of registered rules
    var count: Int { targetRules.count + moduleRules.count }
}
