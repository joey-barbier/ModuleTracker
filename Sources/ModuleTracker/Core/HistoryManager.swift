import Foundation

/// Snapshot of key metrics at a point in time
struct HistorySnapshot: Codable, Equatable {
    let date: String
    let modulesCount: Int
    let modularizedCount: Int
    let legacyCount: Int
    let totalTargets: Int
    /// Custom metrics from rules (key = field_id_value_count, value = count)
    let customMetrics: [String: Int]

    /// Compare metrics only (ignore date)
    func hasSameMetrics(as other: HistorySnapshot) -> Bool {
        modulesCount == other.modulesCount &&
        modularizedCount == other.modularizedCount &&
        legacyCount == other.legacyCount &&
        totalTargets == other.totalTargets &&
        customMetrics == other.customMetrics
    }
}

struct HistoryData: Codable {
    var snapshots: [HistorySnapshot]
}

struct HistoryManager {
    private let historyURL: URL

    init(outputDirectory: URL) {
        self.historyURL = outputDirectory.appendingPathComponent("history.json")
    }

    /// Load existing history or create empty
    func loadHistory() -> HistoryData {
        guard FileManager.default.fileExists(atPath: historyURL.path),
              let data = try? Data(contentsOf: historyURL),
              let history = try? JSONDecoder().decode(HistoryData.self, from: data) else {
            return HistoryData(snapshots: [])
        }
        return history
    }

    /// Save history to disk
    func saveHistory(_ history: HistoryData) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(history)
        try data.write(to: historyURL)
    }

    /// Create snapshot from current data
    func createSnapshot(modules: [ModuleMetrics]) -> HistorySnapshot {
        let dateFormatter = ISO8601DateFormatter()
        let timestamp = dateFormatter.string(from: Date())

        let modularized = modules.filter { $0.isModularized }
        let legacy = modules.filter { !$0.isModularized }

        let totalTargets = modularized.reduce(0) { $0 + $1.targets.count }

        // Custom metrics computed from registered rules (100% data-driven)
        var customMetrics: [String: Int] = [:]
        let fieldsMeta = RulesRegistry.shared.allFieldsMetadata()
        for field in fieldsMeta where field.showInChart {
            // Count values for each field based on level
            for (value, _) in field.values {
                let key = "\(field.id)_\(value)_count"
                var count = 0
                for module in modules {
                    if field.level == "module" {
                        // Module-level field: count from module.customFields
                        if let val = module.customFields[field.id]?.value {
                            if String(describing: val) == value { count += 1 }
                        }
                    } else {
                        // Target-level field: count from target.customFields
                        for target in module.targets {
                            if let val = target.customFields[field.id]?.value {
                                if String(describing: val) == value { count += 1 }
                            }
                        }
                    }
                }
                customMetrics[key] = count
            }
        }

        return HistorySnapshot(
            date: timestamp,
            modulesCount: modules.count,
            modularizedCount: modularized.count,
            legacyCount: legacy.count,
            totalTargets: totalTargets,
            customMetrics: customMetrics
        )
    }

    /// Add snapshot and save (only if metrics changed)
    func recordSnapshot(modules: [ModuleMetrics]) throws {
        var history = loadHistory()
        let snapshot = createSnapshot(modules: modules)

        // Skip if no changes from last snapshot
        if let lastSnapshot = history.snapshots.last,
           snapshot.hasSameMetrics(as: lastSnapshot) {
            print("History: No changes detected, skipping snapshot")
            return
        }

        history.snapshots.append(snapshot)

        // Keep last 100 snapshots max
        if history.snapshots.count > 100 {
            history.snapshots = Array(history.snapshots.suffix(100))
        }

        try saveHistory(history)
        print("History recorded: \(historyURL.path) (\(history.snapshots.count) snapshots)")
    }
}
