# Skill: Add a Chart

## Context
ModuleTracker uses a declarative chart configuration system. Charts are defined in a JavaScript array and automatically rendered using Chart.js.

## Files to Modify

### 1. Add Chart Configuration
**Location:** `Sources/ModuleTracker/Core/HTMLExporter.swift`

Find the `chartConfigs` array in the JavaScript section and add your chart:

```javascript
const chartConfigs = [
    // ... existing charts ...

    {
        id: 'your-chart',        // Unique ID (used for canvas element)
        title: 'Your Chart Title',
        type: 'line',            // 'line', 'bar', or 'area'
        stacked: false,          // true for stacked bar charts
        datasets: [
            { label: 'Dataset 1', key: 'your_metric_key', color: '#58a6ff' },
            { label: 'Dataset 2', key: 'another_key', color: '#3fb950' }
        ]
    }
];
```

### 2. Ensure Metrics Exist in Snapshot
The `key` values must match properties in `HistorySnapshot`. If your metric doesn't exist yet, see `add-snapshot-metric.md`.

## Chart Types

### Line Chart
```javascript
{
    id: 'trend',
    title: 'Trend Over Time',
    type: 'line',
    datasets: [
        { label: 'Metric A', key: 'metric_a', color: '#58a6ff' },
        { label: 'Metric B', key: 'metric_b', color: '#3fb950' }
    ]
}
```

### Bar Chart (Stacked)
```javascript
{
    id: 'distribution',
    title: 'Distribution',
    type: 'bar',
    stacked: true,
    datasets: [
        { label: 'Category 1', key: 'cat_1_count', color: '#3fb950' },
        { label: 'Category 2', key: 'cat_2_count', color: '#f0883e' }
    ]
}
```

### Area Chart (Line with Fill)
```javascript
{
    id: 'coverage',
    title: 'Coverage Area',
    type: 'area',
    datasets: [
        { label: 'Coverage', key: 'coverage_percent', color: '#3fb950' }
    ]
}
```

## Color Palette Reference
```
Green (positive):   #3fb950
Blue (neutral):     #58a6ff
Orange (warning):   #f0883e
Red (negative):     #f85149
Purple (info):      #a371f7
Yellow:             #d29922
```

## Example: Adding "Code Coverage" Chart

```javascript
{
    id: 'coverage',
    title: 'Test Coverage Evolution',
    type: 'area',
    datasets: [
        { label: 'Coverage %', key: 'test_coverage_percent', color: '#3fb950' }
    ]
}
```

Then ensure `test_coverage_percent` exists in `HistorySnapshot` (see `add-snapshot-metric.md`).

## Checklist
- [ ] Chart config added to `chartConfigs` array
- [ ] Unique `id` chosen
- [ ] All `key` values exist in `HistorySnapshot`
- [ ] Appropriate chart type selected
- [ ] Colors chosen from palette
- [ ] Rebuild and test: `swift build && swift run`
