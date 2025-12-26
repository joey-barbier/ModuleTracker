# Skill: Add a Detection Rule

## Context
ModuleTracker uses a plugin architecture for detection rules. Each rule analyzes modules and extracts specific metrics.

ModuleTracker is an **empty shell** by design - rules register themselves via the Registry pattern and provide metadata for automatic HTML dashboard generation.

## Files to Create/Modify

### 1. Create the Rule File
**Location:** Any location in your project (e.g., `Rules/YourRule.swift`)

```swift
import Foundation

struct YourRule: Rule {
    typealias Output = String  // String, Bool, Int, or custom type

    static let name = "Your Rule Name"
    static let documentationFile = "your-rule.md"

    // Auto-registration pattern
    static let _register: Void = {
        RulesRegistry.shared.registerTargetRule(metadata: metadata) { target, _ in
            let result = YourRule().detect(in: target.path)
            return ["your_field": result]
        }
    }()

    // Metadata for HTML dashboard (REQUIRED)
    static var metadata: FieldMetadata {
        FieldMetadata(
            id: "your_field",
            label: "Your Label",
            description: "Description shown in modal when clicking the badge",
            isFilterable: true,
            showInTable: true,
            showInChart: true,
            showInComparison: true,
            chartType: "line",      // "line", "bar", or "area"
            chartColor: "#58a6ff",  // Hex color
            values: [
                "value_1": ValueMeta(
                    label: "Value 1",
                    color: "green",
                    description: "What value_1 means"
                ),
                "value_2": ValueMeta(
                    label: "Value 2",
                    color: "orange",
                    description: "What value_2 means"
                ),
                "none": ValueMeta(
                    label: "None",
                    color: "gray",
                    description: "Not applicable"
                )
            ]
        )
    }

    func detect(in path: URL) -> String {
        // Your detection logic here
        // Use SwiftFileEnumerator.enumerate(in:handler:) to scan Swift files

        return "value_1"  // Must match a key in values dictionary
    }
}
```

### 2. Register in Bootstrap.swift
**Location:** `Sources/ModuleTracker/Bootstrap.swift`

```swift
enum Bootstrap {
    static func register() {
        // Rules
        _ = YourRule._register

        // Other rules...
    }
}
```

That's it! No need to modify `RulesEngine.swift` or `ModuleMetrics.swift`.

## How It Works

1. `Bootstrap.register()` is called at startup
2. Accessing `YourRule._register` triggers the lazy static closure
3. The closure calls `RulesRegistry.shared.registerTargetRule(metadata:apply:)`
4. `RulesEngine` automatically:
   - Loops over all registered rules
   - Applies them to each target/module
   - Stores results in `customFields`
5. `HTMLExporter` automatically:
   - Generates filters from `isFilterable: true` metadata
   - Creates table columns from `showInTable: true` metadata
   - Generates charts from `showInChart: true` metadata
   - Shows badges with colors from `values` metadata

## FieldMetadata Reference

| Property | Type | Description |
|----------|------|-------------|
| `id` | String | Unique field identifier (snake_case, matches return key) |
| `label` | String | Display name in UI |
| `description` | String | Shown in modal on click |
| `isFilterable` | Bool | Add dropdown filter in table header |
| `showInTable` | Bool | Show column in modules table |
| `showInChart` | Bool | Generate evolution chart |
| `showInComparison` | Bool | Show in comparison view |
| `invertedComparison` | Bool? | True if lower is better (e.g., violations) |
| `chartType` | String? | "line", "bar", or "area" |
| `chartColor` | String? | Hex color for chart (e.g., "#58a6ff") |
| `values` | Dictionary | Possible values with labels/colors |

## ValueMeta Reference

| Property | Type | Description |
|----------|------|-------------|
| `label` | String | Display label (e.g., "Swift Testing") |
| `color` | String | Badge color: green, yellow, orange, red, blue, gray, purple |
| `description` | String? | Explanation shown in modal |

## Registration Types

### Target Rules
Analyze individual targets within SPM modules:
```swift
RulesRegistry.shared.registerTargetRule(metadata: metadata) { target, modulePath in
    // target.path = target directory
    // modulePath = parent module path
    return ["your_field": result]
}
```

### Module Rules
Analyze entire modules (legacy or SPM module-level):
```swift
RulesRegistry.shared.registerModuleRule(metadata: metadata) { module in
    // module.path = module directory
    return ["your_field": result]
}
```

## Example: Adding a "Has Combine" Rule

```swift
// Rules/HasCombineRule.swift
import Foundation

struct HasCombineRule: Rule {
    typealias Output = Bool

    static let name = "Has Combine"
    static let documentationFile = "has-combine.md"

    static let _register: Void = {
        RulesRegistry.shared.registerTargetRule(metadata: metadata) { target, _ in
            let result = HasCombineRule().detect(in: target.path)
            return ["has_combine": result]
        }
    }()

    static var metadata: FieldMetadata {
        FieldMetadata(
            id: "has_combine",
            label: "Combine",
            description: "Detects if the module uses Apple's Combine framework",
            isFilterable: true,
            showInTable: true,
            showInChart: true,
            showInComparison: true,
            chartType: "area",
            chartColor: "#a371f7",
            values: [
                "true": ValueMeta(
                    label: "Yes",
                    color: "purple",
                    description: "Module imports and uses Combine framework"
                ),
                "false": ValueMeta(
                    label: "No",
                    color: "gray",
                    description: "No Combine usage detected"
                )
            ]
        )
    }

    func detect(in path: URL) -> Bool {
        var hasCombine = false

        SwiftFileEnumerator.enumerate(in: path) { _, content in
            if content.contains("import Combine") {
                hasCombine = true
            }
        }

        return hasCombine
    }
}
```

Then register:
```swift
// Bootstrap.swift
_ = HasCombineRule._register
```

## Utilities

### SwiftFileEnumerator
```swift
// Scan all .swift files in a directory
SwiftFileEnumerator.enumerate(in: path) { fileURL, content in
    if content.contains("import Testing") {
        // Found!
    }
}

// Check if path exists
if SwiftFileEnumerator.pathExists(path) {
    // ...
}
```

## Checklist
- [ ] Rule file created with `_register` static property
- [ ] `metadata` property defined with all required fields
- [ ] `values` dictionary contains all possible return values
- [ ] Rule registered in `Bootstrap.swift` via `_ = YourRule._register`
- [ ] Run `swift build` to verify compilation
