import Foundation

// Register custom scanners and rules
Bootstrap.register()

// Determine project root:
// 1. CLI argument: swift run ModuleTracker /path/to/project
// 2. Environment variable: MODULE_TRACKER_ROOT
// 3. Current directory (default)
let projectRoot: URL
if CommandLine.arguments.count > 1 {
    projectRoot = URL(fileURLWithPath: CommandLine.arguments[1])
} else if let envRoot = ProcessInfo.processInfo.environment["MODULE_TRACKER_ROOT"] {
    projectRoot = URL(fileURLWithPath: envRoot)
} else {
    projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
}

// Output directory next to Package.swift
let scriptURL = URL(fileURLWithPath: #file)
let moduleTrackerDir = scriptURL
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
let outputDir = moduleTrackerDir.appendingPathComponent("Output")

print("Module Tracker v1.0")
print("===================")
print("Project root: \(projectRoot.path)")
print("Registered scanners: \(ScannersRegistry.shared.count)")
print("Registered rules: \(RulesRegistry.shared.count)")
print("")

// Scan for modules
let scannersEngine = ScannersEngine(rootPath: projectRoot)
let modules = scannersEngine.scanAll()

print("Found \(modules.count) modules")
print("")

// Analyze modules
let rulesEngine = RulesEngine()

print("Analyzing modules...")
var metrics: [ModuleMetrics] = []
for module in modules {
    let result = rulesEngine.analyze(module: module)
    metrics.append(result)

    let targetCount = result.targets.count
    let targetStr = targetCount > 0 ? " - \(targetCount) targets" : ""
    print("  [\u{2713}] \(result.name)\(targetStr)")
}

print("")

// Export
let fileManager = FileManager.default
if !fileManager.fileExists(atPath: outputDir.path) {
    try? fileManager.createDirectory(at: outputDir, withIntermediateDirectories: true)
}

let jsonURL = outputDir.appendingPathComponent("module-tracker.json")
let htmlURL = outputDir.appendingPathComponent("index.html")

// History management
let historyManager = HistoryManager(outputDirectory: outputDir)

do {
    // Record snapshot for history
    try historyManager.recordSnapshot(modules: metrics)

    // Load history for charts/comparison
    let history = historyManager.loadHistory()

    let exporter = HTMLExporter()
    try exporter.exportJSON(modules: metrics, to: jsonURL)
    try exporter.exportHTML(modules: metrics, history: history, to: htmlURL)
    print("")
    print("Done! Open Output/index.html in your browser.")
} catch {
    print("Error exporting: \(error)")
}
