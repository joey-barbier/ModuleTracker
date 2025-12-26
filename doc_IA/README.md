# AI Documentation

This folder contains documentation designed for AI assistants to help extend ModuleTracker.

## Key Concept: Empty Shell Architecture

ModuleTracker is an **empty shell** by design:
- Core engine provides Registry + Engine + Exporter
- **0 scanners, 0 rules** by default
- Your project adds scanners/rules via `Bootstrap.swift`

```
Running ModuleTracker alone = 0 modules, 0 metrics
Adding your scanners/rules = full analysis
```

## How to Use

When working with an AI assistant (Claude, GPT, Copilot, etc.), reference the relevant skill file:

```
"Read doc_IA/add-rule.md and help me create a rule that detects async/await usage"
```

The AI will understand the project structure and guide you through the implementation.

## Available Skills

| File | Description |
|------|-------------|
| [add-rule.md](add-rule.md) | Add a new detection rule with FieldMetadata |
| [add-scanner.md](add-scanner.md) | Add a new module scanner |
| [add-chart.md](add-chart.md) | Add a new evolution chart |
| [add-snapshot-metric.md](add-snapshot-metric.md) | Add a metric to track over time |
| [add-comparison.md](add-comparison.md) | Add a comparison row |

## Project Architecture

```
ModuleTracker/
├── Sources/ModuleTracker/
│   ├── main.swift                    # Entry point (calls Bootstrap.register())
│   ├── Bootstrap.swift               # ← YOUR REGISTRATIONS HERE
│   ├── Registry/
│   │   ├── ScannersRegistry.swift    # Scanner registration singleton
│   │   └── RulesRegistry.swift       # Rule registration singleton
│   ├── Core/
│   │   ├── ModuleInfo.swift          # Module data model
│   │   ├── ModuleMetrics.swift       # Output structures (with customFields)
│   │   ├── AnyCodable.swift          # Dynamic field support
│   │   ├── HistoryManager.swift      # Snapshot storage
│   │   └── HTMLExporter.swift        # JSON + HTML export
│   ├── Scanners/
│   │   ├── ScannerProtocol.swift     # Scanner interface
│   │   └── ScannersEngine.swift      # Loops over ScannersRegistry
│   └── Rules/
│       ├── RuleProtocol.swift        # Rule interface + FieldMetadata
│       └── RulesEngine.swift         # Loops over RulesRegistry
└── Output/
    ├── module-tracker.json           # Data export
    ├── index.html                    # Interactive dashboard
    └── history.json                  # Historical snapshots
```

## The `_register` Pattern

Every scanner and rule uses this pattern:

```swift
struct MyScanner {
    static let _register: Void = {
        ScannersRegistry.shared.register(name: "my_scanner") { rootPath in
            MyScanner(rootPath: rootPath).scan()
        }
    }()
}

struct MyRule: Rule {
    static let _register: Void = {
        RulesRegistry.shared.registerTargetRule(metadata: metadata) { target, _ in
            return ["my_field": MyRule().detect(in: target.path)]
        }
    }()

    static var metadata: FieldMetadata { /* ... */ }
}
```

Then register in `Bootstrap.swift`:
```swift
enum Bootstrap {
    static func register() {
        _ = MyScanner._register
        _ = MyRule._register
    }
}
```

## Extension Points

### 1. Add Scanners
Create a scanner struct with `_register` and register in Bootstrap.

### 2. Add Rules
Create a rule struct with:
- `_register` static property
- `metadata: FieldMetadata` for HTML dashboard auto-generation

### 3. Charts
Charts are **auto-generated** from rules where `showInChart: true` in metadata.

### 4. Comparisons
Comparisons are **auto-generated** from rules where `showInComparison: true` in metadata.

## Quick Start for AI

When extending this project, always:

1. **Read the relevant skill file** from this folder
2. **Create your scanner/rule** with `_register` pattern
3. **Add `FieldMetadata`** for rules (required for HTML dashboard)
4. **Register in `Bootstrap.swift`** via `_ = YourType._register`
5. **Run `swift build`** to verify compilation
6. **Run `swift run`** to test the changes

## Example Prompts

### Add a Rule
```
"Read doc_IA/add-rule.md and create a rule that detects if a module uses Combine framework"
```

### Add a Scanner
```
"Read doc_IA/add-scanner.md and create a scanner for CocoaPods dependencies"
```

### Add a Chart
```
"Read doc_IA/add-chart.md and add a chart showing test framework migration over time"
```

### Add a Metric
```
"Read doc_IA/add-snapshot-metric.md and track the total number of Swift files across all modules"
```
