# Skill: Add a Comparison Metric

## Context
The Compare view shows side-by-side differences between the current and previous snapshots. Each row displays: label, old value, arrow, new value, and delta badge.

## Files to Modify

### 1. Ensure Metric Exists in Snapshot
The metric must exist in `HistorySnapshot`. If not, see `add-snapshot-metric.md` first.

### 2. Add Comparison Row
**Location:** `Sources/ModuleTracker/Core/HTMLExporter.swift`

Find the `renderCompare()` function and add your row to the appropriate card:

```javascript
function renderCompare() {
    // ... existing code ...

    container.innerHTML = `
        <div class="comparison-grid">
            <div class="comparison-card">
                <h4>Your Category</h4>
                ${compareRow('Your Metric', current.your_metric_count, previous.your_metric_count)}
                ${compareRow('Another Metric', current.another_count, previous.another_count, true)}
            </div>
        </div>
    `;
}
```

### 3. compareRow() Parameters

```javascript
compareRow(label, currentValue, previousValue, inverted = false)
```

| Parameter | Description |
|-----------|-------------|
| `label` | Display name for the metric |
| `currentValue` | Value from current snapshot |
| `previousValue` | Value from previous snapshot |
| `inverted` | If `true`, decrease is good (green), increase is bad (red) |

### Inverted Logic Examples

**Normal (higher is better):**
- VIP Modern count: more = better → `inverted: false`
- Swift 6 count: more = better → `inverted: false`
- Test coverage: higher = better → `inverted: false`

**Inverted (lower is better):**
- Violations: fewer = better → `inverted: true`
- Legacy modules: fewer = better → `inverted: true`
- Technical debt: lower = better → `inverted: true`

## Example: Adding Build Time Comparison

```javascript
// In the comparison-grid, add a new card:
<div class="comparison-card">
    <h4>Performance</h4>
    ${compareRow('Build Time (s)', current.build_time_seconds, previous.build_time_seconds, true)}
    ${compareRow('Binary Size (MB)', current.binary_size_mb, previous.binary_size_mb, true)}
</div>
```

## Adding a New Comparison Card

Structure for a new category:
```javascript
<div class="comparison-card">
    <h4>Category Name</h4>
    ${compareRow('Metric 1', current.metric_1, previous.metric_1)}
    ${compareRow('Metric 2', current.metric_2, previous.metric_2, true)}
    ${compareRow('Metric 3', current.metric_3, previous.metric_3)}
</div>
```

## Checklist
- [ ] Metric exists in `HistorySnapshot` (see `add-snapshot-metric.md`)
- [ ] `compareRow()` added to appropriate card in `renderCompare()`
- [ ] Correct `inverted` value chosen
- [ ] New card created if new category
- [ ] Rebuild and test: `swift build && swift run`
