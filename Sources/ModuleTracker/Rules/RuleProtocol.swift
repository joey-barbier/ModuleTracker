import Foundation

// MARK: - Field Metadata

/// Metadata for a field, used to auto-generate UI (filters, charts, comparisons, badges)
struct FieldMetadata: Codable {
    let id: String
    let label: String
    let description: String?

    // Scope
    let level: String  // "module" or "target"

    // Display options
    let isFilterable: Bool
    let showInTable: Bool
    let showInChart: Bool
    let showInComparison: Bool
    let invertedComparison: Bool  // true = lower is better (e.g., legacy count)

    // Chart config
    let chartType: String?  // "line", "bar", "area"
    let chartColor: String?

    // Values config (for enums)
    let values: [String: ValueMeta]

    init(
        id: String,
        label: String,
        description: String? = nil,
        level: String = "target",
        isFilterable: Bool = false,
        showInTable: Bool = true,
        showInChart: Bool = false,
        showInComparison: Bool = false,
        invertedComparison: Bool = false,
        chartType: String? = nil,
        chartColor: String? = nil,
        values: [String: ValueMeta] = [:]
    ) {
        self.id = id
        self.label = label
        self.description = description
        self.level = level
        self.isFilterable = isFilterable
        self.showInTable = showInTable
        self.showInChart = showInChart
        self.showInComparison = showInComparison
        self.invertedComparison = invertedComparison
        self.chartType = chartType
        self.chartColor = chartColor
        self.values = values
    }
}

/// Metadata for a specific value (label, badge color, and description)
struct ValueMeta: Codable {
    let label: String
    let color: String  // "green", "yellow", "orange", "red", "blue", "gray", "purple"
    let description: String?

    init(label: String, color: String, description: String? = nil) {
        self.label = label
        self.color = color
        self.description = description
    }
}

// MARK: - Rule Protocol

/// Protocol defining a detection rule for module analysis.
/// Each rule is responsible for detecting a specific aspect of the codebase.
/// Projects define their own rules in Custom/ folder.
protocol Rule {
    associatedtype Output

    /// The name of the rule (used for logging and debugging)
    static var name: String { get }

    /// The documentation file name (e.g., "swift-version.md")
    static var documentationFile: String { get }

    /// Metadata for this field (used for auto-generating UI)
    static var metadata: FieldMetadata { get }

    /// Detects the rule's output for a given path
    func detect(in path: URL) -> Output
}

// MARK: - File Enumeration Helper

/// Utility for enumerating Swift files in a directory
struct SwiftFileEnumerator {

    /// Enumerates all Swift files in a directory and calls the handler for each
    static func enumerate(
        in path: URL,
        handler: (URL, String) -> Void
    ) {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: path.path),
              let enumerator = fileManager.enumerator(
                at: path,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
              ) else {
            return
        }

        while let fileURL = enumerator.nextObject() as? URL {
            guard fileURL.pathExtension == "swift",
                  let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
                continue
            }
            handler(fileURL, content)
        }
    }

    /// Checks if a path exists
    static func pathExists(_ path: URL) -> Bool {
        FileManager.default.fileExists(atPath: path.path)
    }
}
