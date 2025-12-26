# ModuleTracker

[![FR](https://img.shields.io/badge/lang-FR-blue)](README_FR.md)

A lightweight Swift CLI framework that scans your iOS/Swift codebase and generates an interactive HTML dashboard showing module metrics, architecture patterns, and migration progress over time.

**Key feature:** ModuleTracker is an **empty shell** by design. It provides the core engine, and your project adds custom scanners and rules via a simple registration system.

**Use cases:**
- Track modularization progress (monolith → SPM modules)
- Monitor architecture migration (VIPER → VIP → SwiftUI)
- Enforce coding standards via detection rules
- Visualize trends over time with auto-generated charts

## Prerequisites

- Swift 5.9+ (macOS 13+)
- No external dependencies

## Quick Start

```bash
# Clone and build
git clone git@github.com:joey-barbier/ModuleTracker.git
cd ModuleTracker

# Setup Bootstrap (required)
cp Sources/ModuleTracker/Bootstrap.swift.example Sources/ModuleTracker/Bootstrap.swift

swift build

# Run on your project
swift run ModuleTracker /path/to/your/ios/project

# Or use environment variable
export MODULE_TRACKER_ROOT=/path/to/your/ios/project
swift run ModuleTracker

# View results
open Output/index.html
```

## Architecture

ModuleTracker uses a **Registry pattern** where scanners and rules register themselves at startup:

```
┌─────────────────────────────────────────────────────────────┐
│                    YOUR PROJECT                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Bootstrap.swift                                     │   │
│  │  ├── _ = MyScanner._register                        │   │
│  │  ├── _ = MyRule._register                           │   │
│  │  └── ...                                            │   │
│  └─────────────────────────────────────────────────────┘   │
└────────────────────────┬────────────────────────────────────┘
                         │ registers via
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              ModuleTracker Core (empty shell)               │
│  ┌─────────────────┐        ┌─────────────────┐            │
│  │ ScannersRegistry│        │  RulesRegistry  │            │
│  │  (empty array)  │        │  (empty array)  │            │
│  └────────┬────────┘        └────────┬────────┘            │
│           │                          │                      │
│           ▼                          ▼                      │
│  ┌─────────────────┐        ┌─────────────────┐            │
│  │ ScannersEngine  │───────▶│   RulesEngine   │            │
│  │ (loops registry)│        │ (loops registry)│            │
│  └─────────────────┘        └─────────────────┘            │
│                    │                                        │
│                    ▼                                        │
│           ┌─────────────────┐                              │
│           │  HTMLExporter   │ → JSON + Dashboard           │
│           └─────────────────┘                              │
└─────────────────────────────────────────────────────────────┘
```

**Result:** Running ModuleTracker alone = 0 modules, 0 rules. Add your scanners/rules = full analysis.

## Project Structure

```
Sources/ModuleTracker/
├── Core/
│   ├── ModuleInfo.swift       # Module data model
│   ├── ModuleMetrics.swift    # Metrics output model
│   ├── AnyCodable.swift       # Dynamic field support
│   └── HTMLExporter.swift     # Export utilities
├── Registry/
│   ├── ScannersRegistry.swift # Scanner registration
│   └── RulesRegistry.swift    # Rule registration
├── Scanners/
│   ├── ScannerProtocol.swift  # Scanner interface
│   └── ScannersEngine.swift   # Orchestrator
├── Rules/
│   ├── RuleProtocol.swift     # Rule interface + FieldMetadata
│   └── RulesEngine.swift      # Orchestrator
├── Bootstrap.swift.example    # Template (copy to Bootstrap.swift)
└── main.swift                 # Entry point
```

## Creating a Scanner

### 1. Create your scanner file

```swift
import Foundation

struct SPMScanner {
    let rootPath: URL

    // Auto-registration pattern
    static let _register: Void = {
        ScannersRegistry.shared.register(name: "spm") { rootPath in
            SPMScanner(rootPath: rootPath).scan()
        }
    }()

    func scan() -> [ModuleInfo] {
        var modules: [ModuleInfo] = []

        // Your discovery logic
        let modulePath = rootPath.appendingPathComponent("Modules/MyModule")
        modules.append(ModuleInfo(
            name: "MyModule",
            path: modulePath,
            source: "spm"  // String identifier
        ))

        return modules
    }
}
```

### 2. Register in Bootstrap.swift

```swift
enum Bootstrap {
    static func register() {
        // Scanners
        _ = SPMScanner._register
    }
}
```

## Creating a Rule

Rules analyze modules and return structured data with metadata for the HTML dashboard.

### 1. Create your rule file

```swift
import Foundation

struct TestFrameworkRule: Rule {
    typealias Output = String

    static let name = "Test Framework"
    static let documentationFile = "test-framework.md"

    // Auto-registration pattern
    static let _register: Void = {
        RulesRegistry.shared.registerTargetRule(metadata: metadata) { target, _ in
            let result = TestFrameworkRule().detect(in: target.path)
            return ["test_framework": result]
        }
    }()

    // Metadata for HTML dashboard
    static var metadata: FieldMetadata {
        FieldMetadata(
            id: "test_framework",
            label: "Tests",
            description: "Testing framework used in the module",
            isFilterable: true,
            showInTable: true,
            showInChart: true,
            showInComparison: true,
            chartType: "line",
            chartColor: "#58a6ff",
            values: [
                "swift_testing": ValueMeta(
                    label: "Swift Testing",
                    color: "green",
                    description: "Modern Swift Testing framework (@Test macro)"
                ),
                "xctest": ValueMeta(
                    label: "XCTest",
                    color: "orange",
                    description: "Legacy XCTest framework"
                ),
                "none": ValueMeta(
                    label: "None",
                    color: "gray",
                    description: "No tests found"
                )
            ]
        )
    }

    func detect(in path: URL) -> String {
        var hasSwiftTesting = false
        var hasXCTest = false

        SwiftFileEnumerator.enumerate(in: path) { _, content in
            if content.contains("import Testing") { hasSwiftTesting = true }
            if content.contains("import XCTest") { hasXCTest = true }
        }

        if hasSwiftTesting && hasXCTest { return "mixed" }
        if hasSwiftTesting { return "swift_testing" }
        if hasXCTest { return "xctest" }
        return "none"
    }
}
```

### 2. Register in Bootstrap.swift

```swift
enum Bootstrap {
    static func register() {
        // Scanners
        _ = SPMScanner._register

        // Rules
        _ = TestFrameworkRule._register
    }
}
```

## FieldMetadata Reference

Every rule must provide `metadata` for the HTML dashboard:

| Property | Type | Description |
|----------|------|-------------|
| `id` | String | Unique field identifier (snake_case) |
| `label` | String | Display name in UI |
| `description` | String | Shown in modal on click |
| `isFilterable` | Bool | Add dropdown filter |
| `showInTable` | Bool | Show column in table |
| `showInChart` | Bool | Generate evolution chart |
| `showInComparison` | Bool | Show in comparison view |
| `chartType` | String? | "line", "bar", or "area" |
| `chartColor` | String? | Hex color for chart |
| `values` | Dictionary | Possible values with labels/colors |

### ValueMeta

Each value in `values` dictionary has:

| Property | Type | Description |
|----------|------|-------------|
| `label` | String | Display label (e.g., "Swift Testing") |
| `color` | String | Badge color: green, yellow, orange, red, blue, gray, purple |
| `description` | String? | Explanation shown in modal |

## Utilities

### SwiftFileEnumerator

Scan all Swift files in a directory:

```swift
SwiftFileEnumerator.enumerate(in: modulePath) { fileURL, content in
    if content.contains("import Testing") {
        // Found Swift Testing
    }
}

// Check if path exists
if SwiftFileEnumerator.pathExists(modulePath) {
    // ...
}
```

## Output

- **JSON**: `Output/module-tracker.json` — Raw data with all metrics
- **HTML**: `Output/index.html` — Interactive dashboard with:
  - **Tables**: Filterable module listings with badges
  - **Charts**: Auto-generated evolution graphs from `showInChart` rules
  - **Compare**: Side-by-side delta view between snapshots
- **History**: `Output/history.json` — Snapshots for trend tracking

## AI-Assisted Development

The `doc_IA/` folder contains documentation designed for AI assistants. When working with an AI (Claude, GPT, Copilot, etc.), reference these files:

```
"Read doc_IA/add-rule.md and help me create a rule that detects Combine usage"
```

| File | Description |
|------|-------------|
| `doc_IA/add-rule.md` | Add a detection rule |
| `doc_IA/add-scanner.md` | Add a module scanner |
| `doc_IA/add-chart.md` | Add an evolution chart |
| `doc_IA/add-snapshot-metric.md` | Add a tracked metric |
| `doc_IA/add-comparison.md` | Add a comparison row |

## Getting Started (Summary)

1. Clone ModuleTracker
2. Copy `Bootstrap.swift.example` to `Bootstrap.swift`
3. Add your scanners (implement `scan() -> [ModuleInfo]` + `_register`)
4. Add your rules (implement `detect()` + `metadata` + `_register`)
5. Register everything in `Bootstrap.swift`
6. Run `swift build && swift run`
7. Open `Output/index.html`

## License

MIT
