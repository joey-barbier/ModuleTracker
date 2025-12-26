# Skill: Add a Snapshot Metric

## Context
Snapshot metrics are aggregated values tracked over time. They power the Charts and Compare features. Each metric is computed from module data and stored in `history.json`.

## Files to Modify

### 1. Add Property to HistorySnapshot
**Location:** `Sources/ModuleTracker/Core/HistoryManager.swift`

```swift
struct HistorySnapshot: Codable, Equatable {
    // ... existing properties ...
    let yourMetricCount: Int  // Add your new metric

    func hasSameMetrics(as other: HistorySnapshot) -> Bool {
        // ... existing comparisons ...
        && yourMetricCount == other.yourMetricCount  // Add to comparison
    }
}
```

### 2. Compute Metric in createSnapshot()
**Location:** `Sources/ModuleTracker/Core/HistoryManager.swift`

Add variable and computation logic:
```swift
func createSnapshot(...) -> HistorySnapshot {
    // ... existing variables ...
    var yourMetric = 0

    // SPM modules
    for module in spmModules {
        for target in module.targets {
            // Your computation logic
            if target.yourProperty == "some_value" {
                yourMetric += 1
            }
        }
    }

    // Legacy modules (if applicable)
    for module in legacyModules + scenesModules {
        if module.yourProperty == "some_value" {
            yourMetric += 1
        }
    }

    return HistorySnapshot(
        // ... existing properties ...
        yourMetricCount: yourMetric
    )
}
```

### 3. Add to JSON Output (for JS access)
The property name in Swift becomes snake_case in JSON automatically via `keyEncodingStrategy = .convertToSnakeCase`.

- Swift: `yourMetricCount`
- JSON: `your_metric_count`
- JavaScript: `s.your_metric_count`

### 4. Use in Charts
**Location:** `Sources/ModuleTracker/Core/HTMLExporter.swift`

```javascript
{
    id: 'your-chart',
    title: 'Your Metric',
    type: 'line',
    datasets: [
        { label: 'Your Metric', key: 'your_metric_count', color: '#58a6ff' }
    ]
}
```

### 5. Add to Compare View (Optional)
**Location:** `Sources/ModuleTracker/Core/HTMLExporter.swift`

Find `renderCompare()` function and add:
```javascript
${compareRow('Your Metric', current.your_metric_count, previous.your_metric_count)}
// Or with inverted logic (lower is better):
${compareRow('Your Metric', current.your_metric_count, previous.your_metric_count, true)}
```

## Example: Adding "Modules with Tests" Count

```swift
// In HistorySnapshot struct:
let modulesWithTestsCount: Int

// In hasSameMetrics():
&& modulesWithTestsCount == other.modulesWithTestsCount

// In createSnapshot():
var modulesWithTests = 0

for module in spmModules {
    for target in module.targets {
        if target.testFramework != "none" {
            modulesWithTests += 1
        }
    }
}

// In return statement:
modulesWithTestsCount: modulesWithTests
```

## Metric Types

| Type | Use Case | Example |
|------|----------|---------|
| Count | Number of items | `spmModulesCount` |
| Percentage | Ratio (0-100) | `testCoveragePercent` |
| Sum | Accumulated value | `totalLinesOfCode` |
| Boolean count | Items matching condition | `violationsCount` |

## Checklist
- [ ] Property added to `HistorySnapshot` struct
- [ ] Property added to `hasSameMetrics()` comparison
- [ ] Variable declared in `createSnapshot()`
- [ ] Computation logic implemented for SPM modules
- [ ] Computation logic implemented for Legacy modules (if applicable)
- [ ] Property added to `HistorySnapshot` initializer call
- [ ] Chart config added (optional, see `add-chart.md`)
- [ ] Compare row added (optional)
- [ ] Delete `history.json` to reset (or add migration)
- [ ] Rebuild and test: `swift build && swift run`
