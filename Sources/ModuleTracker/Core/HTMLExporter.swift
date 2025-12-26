import Foundation

struct HTMLExporter {

    func exportJSON(modules: [ModuleMetrics], to outputURL: URL) throws {
        let dateFormatter = ISO8601DateFormatter()
        let timestamp = dateFormatter.string(from: Date())

        let output = TrackerOutput(
            generatedAt: timestamp,
            rulesVersion: "2.0",
            modulesCount: modules.count,
            fieldsMeta: RulesEngine.fieldsMetadataDict(),
            modules: modules
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.keyEncodingStrategy = .convertToSnakeCase

        let data = try encoder.encode(output)
        try data.write(to: outputURL)
        print("JSON exported to: \(outputURL.path)")
    }

    func exportHTML(
        modules: [ModuleMetrics],
        history: HistoryData,
        to outputURL: URL
    ) throws {
        let dateFormatter = ISO8601DateFormatter()
        let timestamp = dateFormatter.string(from: Date())

        let output = TrackerOutput(
            generatedAt: timestamp,
            rulesVersion: "2.0",
            modulesCount: modules.count,
            fieldsMeta: RulesEngine.fieldsMetadataDict(),
            modules: modules
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.keyEncodingStrategy = .convertToSnakeCase

        let jsonData = try encoder.encode(output)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"

        let historyEncoder = JSONEncoder()
        historyEncoder.outputFormatting = [.sortedKeys]
        historyEncoder.keyEncodingStrategy = .convertToSnakeCase
        let historyData = try historyEncoder.encode(history)
        let historyString = String(data: historyData, encoding: .utf8) ?? "{\"snapshots\":[]}"

        let html = generateHTML(jsonString: jsonString, historyString: historyString)
        try html.write(to: outputURL, atomically: true, encoding: .utf8)
        print("HTML exported to: \(outputURL.path)")
    }

    private func generateHTML(jsonString: String, historyString: String) -> String {
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Module Tracker</title>
            <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
            <style>
                * { box-sizing: border-box; margin: 0; padding: 0; }
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0d1117; color: #c9d1d9; padding: 20px; }
                .container { max-width: 1800px; margin: 0 auto; }
                h1 { color: #58a6ff; margin-bottom: 10px; }
                h2 { color: #8b949e; margin: 30px 0 15px; font-size: 18px; }
                .meta { color: #8b949e; font-size: 14px; margin-bottom: 20px; }

                /* Tab Menu */
                .tabs { display: flex; gap: 5px; margin-bottom: 25px; border-bottom: 1px solid #30363d; padding-bottom: 0; }
                .tab { background: transparent; border: none; color: #8b949e; padding: 12px 20px; cursor: pointer; font-size: 14px; font-weight: 500; border-bottom: 2px solid transparent; margin-bottom: -1px; transition: all 0.2s; }
                .tab:hover { color: #c9d1d9; }
                .tab.active { color: #58a6ff; border-bottom-color: #58a6ff; }
                .tab-content { display: none; }
                .tab-content.active { display: block; }

                /* Stats */
                .stats { display: flex; gap: 15px; margin-bottom: 25px; flex-wrap: wrap; }
                .stat { background: #161b22; padding: 12px 18px; border-radius: 8px; border: 1px solid #30363d; position: relative; }
                .stat-value { font-size: 24px; font-weight: bold; color: #58a6ff; }
                .stat-label { font-size: 11px; color: #8b949e; }
                .stat-delta { position: absolute; top: 8px; right: 8px; font-size: 11px; font-weight: 600; }
                .stat-delta.positive { color: #3fb950; }
                .stat-delta.negative { color: #f85149; }
                .stat-delta.neutral { color: #8b949e; }

                /* Filters */
                .filters { display: flex; gap: 10px; margin-bottom: 15px; flex-wrap: wrap; }
                input, select { background: #161b22; border: 1px solid #30363d; color: #c9d1d9; padding: 8px 12px; border-radius: 6px; font-size: 14px; }
                input:focus, select:focus { outline: none; border-color: #58a6ff; }

                /* Tables */
                table { width: 100%; border-collapse: collapse; background: #161b22; border-radius: 8px; overflow: hidden; margin-bottom: 30px; }
                th, td { padding: 10px 14px; text-align: left; border-bottom: 1px solid #30363d; font-size: 13px; }
                th { background: #21262d; color: #8b949e; font-weight: 600; }
                tr:hover { background: #1c2128; }
                tr.target-row { background: #0d1117; }
                tr.target-row td:first-child { padding-left: 40px; }

                /* Badges */
                .badge { display: inline-block; padding: 2px 8px; border-radius: 12px; font-size: 11px; font-weight: 500; }
                .badge-green { background: #238636; color: #fff; }
                .badge-yellow { background: #9e6a03; color: #fff; }
                .badge-orange { background: #bd5800; color: #fff; }
                .badge-red { background: #da3633; color: #fff; }
                .badge-blue { background: #1f6feb; color: #fff; }
                .badge-gray { background: #30363d; color: #8b949e; }
                .badge-purple { background: #8957e5; color: #fff; }
                .num { text-align: center; }
                .section-title { display: flex; align-items: center; gap: 10px; }
                .section-count { background: #30363d; padding: 2px 8px; border-radius: 10px; font-size: 12px; }
                .module-name { font-weight: bold; color: #58a6ff; }
                .target-name { color: #8b949e; font-size: 12px; }
                .expand-btn { color: #58a6ff; margin-right: 8px; }
                .module-row { cursor: pointer; }
                .module-row:hover { background: #21262d; }

                /* Charts */
                .charts-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(500px, 1fr)); gap: 20px; margin-bottom: 30px; }
                .chart-card { background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 20px; }
                .chart-card h3 { color: #c9d1d9; font-size: 14px; margin-bottom: 15px; }
                .chart-container { position: relative; height: 300px; }

                /* Comparison */
                .comparison-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 15px; margin-bottom: 30px; }
                .comparison-card { background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 20px; }
                .comparison-card h4 { color: #8b949e; font-size: 12px; text-transform: uppercase; margin-bottom: 10px; }
                .comparison-row { display: flex; justify-content: space-between; align-items: center; padding: 8px 0; border-bottom: 1px solid #21262d; }
                .comparison-row:last-child { border-bottom: none; }
                .comparison-label { color: #c9d1d9; font-size: 13px; }
                .comparison-values { display: flex; align-items: center; gap: 10px; }
                .comparison-old { color: #8b949e; font-size: 13px; }
                .comparison-arrow { color: #8b949e; }
                .comparison-new { font-weight: 600; font-size: 13px; }
                .comparison-delta { font-size: 12px; font-weight: 600; padding: 2px 6px; border-radius: 4px; }
                .delta-positive { background: rgba(63, 185, 80, 0.2); color: #3fb950; }
                .delta-negative { background: rgba(248, 81, 73, 0.2); color: #f85149; }
                .delta-neutral { background: rgba(139, 148, 158, 0.2); color: #8b949e; }

                .no-data { text-align: center; padding: 60px 20px; color: #8b949e; }
                .no-data-icon { font-size: 48px; margin-bottom: 15px; }

                /* Modal */
                .modal { display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.8); z-index: 100; }
                .modal.active { display: flex; align-items: center; justify-content: center; }
                .modal-content { background: #161b22; border: 1px solid #30363d; border-radius: 12px; padding: 25px; max-width: 600px; max-height: 80vh; overflow-y: auto; }
                .modal-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px; }
                .modal-close { background: none; border: none; color: #8b949e; font-size: 24px; cursor: pointer; }
                .modal-close:hover { color: #c9d1d9; }
                .field-info { margin-bottom: 15px; }
                .field-info h4 { color: #58a6ff; margin-bottom: 5px; }
                .field-info p { color: #8b949e; font-size: 13px; line-height: 1.5; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>Module Tracker</h1>
                <div class="meta" id="meta">Loading...</div>

                <!-- Tab Menu -->
                <div class="tabs">
                    <button class="tab active" onclick="switchTab('tables')">Tables</button>
                    <button class="tab" onclick="switchTab('charts')">Charts</button>
                    <button class="tab" onclick="switchTab('compare')">Compare</button>
                </div>

                <!-- Tables Tab -->
                <div class="tab-content active" id="tab-tables">
                    <div class="stats" id="stats"></div>

                    <div id="modularized-section">
                        <h2 class="section-title">Modularized <span class="section-count" id="modularized-count">0</span></h2>
                        <div class="filters" id="filters"></div>
                        <table id="modularized-table">
                            <thead id="modularized-thead"></thead>
                            <tbody id="modularized-tbody"></tbody>
                        </table>
                    </div>

                    <div id="legacy-section" style="display:none;">
                        <h2 class="section-title">Legacy <span class="section-count" id="legacy-count">0</span></h2>
                        <table id="legacy-table">
                            <thead id="legacy-thead"></thead>
                            <tbody id="legacy-tbody"></tbody>
                        </table>
                    </div>
                </div>

                <!-- Charts Tab -->
                <div class="tab-content" id="tab-charts">
                    <div id="charts-container"></div>
                </div>

                <!-- Compare Tab -->
                <div class="tab-content" id="tab-compare">
                    <div id="compare-container"></div>
                </div>
            </div>

            <div class="modal" id="modal">
                <div class="modal-content">
                    <div class="modal-header">
                        <h3 id="modal-title">Field Info</h3>
                        <button class="modal-close" onclick="closeModal()">&times;</button>
                    </div>
                    <div id="modal-body"></div>
                </div>
            </div>

            <script>
                const data = \(jsonString);
                const history = \(historyString);
                const expanded = new Set();
                let charts = [];

                // Split modules by type
                const modularizedModules = data.modules.filter(m => m.is_modularized);
                const legacyModules = data.modules.filter(m => !m.is_modularized);

                // Fields metadata from JSON - 100% data-driven
                const fieldsMeta = data.fields_meta || {};

                function switchTab(tabId) {
                    document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
                    document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
                    document.querySelector(`[onclick="switchTab('${tabId}')"]`).classList.add('active');
                    document.getElementById(`tab-${tabId}`).classList.add('active');
                    if (tabId === 'charts') renderCharts();
                    if (tabId === 'compare') renderCompare();
                }

                function init() {
                    const fieldsCount = Object.keys(fieldsMeta).length;
                    document.getElementById('meta').textContent = `Generated: ${new Date(data.generated_at).toLocaleString()} | ${fieldsCount} fields | ${history.snapshots.length} snapshots`;
                    document.getElementById('modularized-count').textContent = modularizedModules.length;
                    document.getElementById('legacy-count').textContent = legacyModules.length;

                    if (legacyModules.length > 0) {
                        document.getElementById('legacy-section').style.display = 'block';
                    }
                    if (modularizedModules.length === 0) {
                        document.getElementById('modularized-section').style.display = 'none';
                    }

                    renderFilters();
                    renderStats();
                    renderTableHeaders();
                    renderModularized();
                    renderLegacy();
                }

                function renderFilters() {
                    const filtersDiv = document.getElementById('filters');
                    let html = '<input type="text" id="search" placeholder="Search...">';

                    // Source filter
                    const sources = [...new Set(data.modules.map(m => m.source))];
                    if (sources.length > 1) {
                        html += '<select id="filter-source"><option value="">All Sources</option>';
                        sources.forEach(s => html += `<option value="${s}">${s}</option>`);
                        html += '</select>';
                    }

                    // Custom field filters from fieldsMeta
                    Object.entries(fieldsMeta).filter(([k, f]) => f.is_filterable).forEach(([fieldId, field]) => {
                        const values = new Set();
                        data.modules.forEach(m => {
                            m.targets.forEach(t => {
                                const v = t.custom_fields?.[fieldId];
                                if (v !== undefined) values.add(v);
                            });
                            const v = m.custom_fields?.[fieldId];
                            if (v !== undefined) values.add(v);
                        });
                        if (values.size > 0) {
                            html += `<select id="filter-${fieldId}"><option value="">All ${field.label}</option>`;
                            [...values].sort().forEach(v => {
                                const label = field.values?.[v]?.label || v;
                                html += `<option value="${v}">${label}</option>`;
                            });
                            html += '</select>';
                        }
                    });

                    filtersDiv.innerHTML = html;

                    document.getElementById('search')?.addEventListener('input', renderModularized);
                    document.getElementById('filter-source')?.addEventListener('change', renderModularized);
                    Object.keys(fieldsMeta).filter(k => fieldsMeta[k].is_filterable).forEach(fieldId => {
                        document.getElementById(`filter-${fieldId}`)?.addEventListener('change', renderModularized);
                    });
                }

                function renderTableHeaders() {
                    const tableFields = Object.entries(fieldsMeta).filter(([k, f]) => f.show_in_table);

                    let modHeader = '<tr><th>Module / Target</th>';
                    tableFields.forEach(([fieldId, field]) => {
                        modHeader += `<th>${field.label}</th>`;
                    });
                    modHeader += '</tr>';
                    document.getElementById('modularized-thead').innerHTML = modHeader;

                    let legacyHeader = '<tr><th>Module</th><th>Source</th>';
                    tableFields.forEach(([fieldId, field]) => {
                        legacyHeader += `<th>${field.label}</th>`;
                    });
                    legacyHeader += '</tr>';
                    document.getElementById('legacy-thead').innerHTML = legacyHeader;
                }

                function renderStats() {
                    let totalTargets = 0;
                    modularizedModules.forEach(m => totalTargets += m.targets.length);
                    const prev = history.snapshots.length > 1 ? history.snapshots[history.snapshots.length - 2] : null;

                    let html = `
                        <div class="stat"><div class="stat-value">${modularizedModules.length}</div><div class="stat-label">Modularized</div>${prev ? formatDelta(modularizedModules.length - prev.modularized_count) : ''}</div>
                        <div class="stat"><div class="stat-value">${totalTargets}</div><div class="stat-label">Total Targets</div>${prev ? formatDelta(totalTargets - prev.total_targets) : ''}</div>
                    `;

                    if (legacyModules.length > 0) {
                        html += `<div class="stat"><div class="stat-value">${legacyModules.length}</div><div class="stat-label">Legacy</div>${prev ? formatDelta(legacyModules.length - prev.legacy_count, true) : ''}</div>`;
                    }

                    document.getElementById('stats').innerHTML = html;
                }

                function formatDelta(delta, inverted = false) {
                    if (delta === 0) return '';
                    const isGood = inverted ? delta < 0 : delta > 0;
                    const cls = isGood ? 'positive' : 'negative';
                    const sign = delta > 0 ? '+' : '';
                    return `<span class="stat-delta ${cls}">${sign}${delta}</span>`;
                }

                function badge(fieldId, value) {
                    const field = fieldsMeta[fieldId];
                    if (!field) {
                        return `<span class="badge badge-gray">${value}</span>`;
                    }
                    const valueMeta = field.values?.[String(value)];
                    const color = valueMeta?.color || 'gray';
                    const label = valueMeta?.label || value;
                    return `<span class="badge badge-${color}" title="${field.description || ''}">${label}</span>`;
                }

                function toggleExpand(moduleName) {
                    if (expanded.has(moduleName)) expanded.delete(moduleName);
                    else expanded.add(moduleName);
                    renderModularized();
                }

                function getActiveFilters() {
                    const filters = {};
                    filters.search = (document.getElementById('search')?.value || '').toLowerCase();
                    filters.source = document.getElementById('filter-source')?.value || '';
                    Object.keys(fieldsMeta).filter(k => fieldsMeta[k].is_filterable).forEach(fieldId => {
                        filters[fieldId] = document.getElementById(`filter-${fieldId}`)?.value || '';
                    });
                    return filters;
                }

                function renderModularized() {
                    const filters = getActiveFilters();
                    const tableFields = Object.entries(fieldsMeta).filter(([k, f]) => f.show_in_table);
                    let html = '';

                    modularizedModules.forEach(m => {
                        if (filters.source && m.source !== filters.source) return;

                        const matchingTargets = m.targets.filter(t => {
                            for (const [fieldId, val] of Object.entries(filters)) {
                                if (['search', 'source'].includes(fieldId)) continue;
                                const tVal = t.custom_fields?.[fieldId];
                                if (val && String(tVal) !== val) return false;
                            }
                            return true;
                        });

                        if (Object.keys(filters).some(k => !['search', 'source'].includes(k) && filters[k]) && matchingTargets.length === 0) return;

                        const moduleMatches = m.name.toLowerCase().includes(filters.search);
                        const targetMatches = matchingTargets.some(t => t.name.toLowerCase().includes(filters.search));
                        if (filters.search && !moduleMatches && !targetMatches) return;

                        const isExpanded = expanded.has(m.name);
                        const expandIcon = `<span class="expand-btn">${isExpanded ? '▼' : '▶'}</span>`;

                        html += `<tr class="module-row" onclick="toggleExpand('${m.name}')">
                            <td title="${m.path || ''}">${expandIcon}<span class="module-name">${m.name}</span> <span class="badge badge-purple">${m.targets.length} target${m.targets.length > 1 ? 's' : ''}</span></td>`;
                        tableFields.forEach(() => html += '<td>-</td>');
                        html += '</tr>';

                        if (isExpanded) {
                            const targetsToShow = filters.search && !moduleMatches
                                ? matchingTargets.filter(t => t.name.toLowerCase().includes(filters.search))
                                : matchingTargets;
                            targetsToShow.forEach(t => {
                                html += `<tr class="target-row">
                                    <td><span class="target-name">↳ ${t.name}</span></td>`;
                                tableFields.forEach(([fieldId, field]) => {
                                    const val = t.custom_fields?.[fieldId];
                                    html += `<td onclick="showField('${fieldId}')" style="cursor:pointer">${val !== undefined ? badge(fieldId, val) : '-'}</td>`;
                                });
                                html += '</tr>';
                            });
                        }
                    });

                    document.getElementById('modularized-tbody').innerHTML = html || '<tr><td colspan="10" style="text-align:center;color:#8b949e;">No modules found</td></tr>';
                }

                function renderLegacy() {
                    const tableFields = Object.entries(fieldsMeta).filter(([k, f]) => f.show_in_table);
                    let html = '';
                    legacyModules.forEach(m => {
                        html += `<tr><td title="${m.path || ''}"><strong>${m.name}</strong></td><td>${m.source}</td>`;
                        tableFields.forEach(([fieldId, field]) => {
                            const val = m.custom_fields?.[fieldId];
                            html += `<td onclick="showField('${fieldId}')" style="cursor:pointer">${val !== undefined ? badge(fieldId, val) : '-'}</td>`;
                        });
                        html += '</tr>';
                    });
                    document.getElementById('legacy-tbody').innerHTML = html;
                }

                function renderCharts() {
                    const container = document.getElementById('charts-container');
                    const chartFields = Object.entries(fieldsMeta).filter(([k, f]) => f.show_in_chart);

                    if (history.snapshots.length < 1) {
                        container.innerHTML = `<div class="no-data">
                            <div class="no-data-icon">📈</div>
                            <h3>No data for charts</h3>
                            <p>Run the tracker to generate snapshots.</p>
                        </div>`;
                        return;
                    }

                    charts.forEach(c => c.destroy());
                    charts = [];
                    const labels = history.snapshots.map(s => new Date(s.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }));

                    let html = '<div class="charts-grid">';
                    html += `<div class="chart-card"><h3>Module Distribution</h3><div class="chart-container"><canvas id="chart-modules"></canvas></div></div>`;

                    chartFields.forEach(([fieldId, field]) => {
                        html += `<div class="chart-card"><h3>${field.label} Evolution</h3><div class="chart-container"><canvas id="chart-${fieldId}"></canvas></div></div>`;
                    });

                    html += '</div>';
                    container.innerHTML = html;

                    createChart('chart-modules', labels, [
                        { label: 'Modularized', data: history.snapshots.map(s => s.modularized_count), color: '#58a6ff' },
                        { label: 'Legacy', data: history.snapshots.map(s => s.legacy_count), color: '#f0883e' }
                    ]);

                    chartFields.forEach(([fieldId, field]) => {
                        const values = field.values ? Object.keys(field.values) : [];
                        const datasets = values.map(v => ({
                            label: field.values[v]?.label || v,
                            data: history.snapshots.map(s => s.custom_metrics?.[`${fieldId}_${v}_count`] || 0),
                            color: colorForValue(field.values[v]?.color)
                        }));
                        createChart(`chart-${fieldId}`, labels, datasets, field.chart_type || 'line');
                    });
                }

                function createChart(canvasId, labels, datasets, type = 'line', stacked = false) {
                    const ctx = document.getElementById(canvasId);
                    if (!ctx) return;
                    charts.push(new Chart(ctx, {
                        type: type === 'area' ? 'line' : type,
                        data: {
                            labels,
                            datasets: datasets.map(ds => ({
                                label: ds.label,
                                data: ds.data,
                                borderColor: ds.color,
                                backgroundColor: type === 'bar' ? ds.color : (type === 'area' ? ds.color + '1a' : undefined),
                                fill: type === 'area',
                                tension: 0.3
                            }))
                        },
                        options: {
                            responsive: true,
                            maintainAspectRatio: false,
                            plugins: { legend: { labels: { color: '#c9d1d9' } } },
                            scales: {
                                x: { ticks: { color: '#8b949e' }, grid: { color: '#21262d' }, stacked },
                                y: { ticks: { color: '#8b949e' }, grid: { color: '#21262d' }, beginAtZero: true, stacked }
                            }
                        }
                    }));
                }

                function colorForValue(colorName) {
                    const colors = { green: '#3fb950', yellow: '#9e6a03', orange: '#f0883e', red: '#f85149', blue: '#58a6ff', gray: '#8b949e', purple: '#a371f7' };
                    return colors[colorName] || '#8b949e';
                }

                let compareFromIdx = 0;
                let compareToIdx = Math.max(0, history.snapshots.length - 1);

                function renderCompare() {
                    const container = document.getElementById('compare-container');
                    const comparisonFields = Object.entries(fieldsMeta).filter(([k, f]) => f.show_in_comparison);

                    if (history.snapshots.length < 2) {
                        container.innerHTML = `<div class="no-data">
                            <div class="no-data-icon">🔄</div>
                            <h3>Not enough data for comparison</h3>
                            <p>Run the tracker again to compare with previous results.</p>
                        </div>`;
                        return;
                    }

                    const from = history.snapshots[compareFromIdx];
                    const to = history.snapshots[compareToIdx];

                    const dateOptions = history.snapshots.map((s, i) =>
                        `<option value="${i}">${new Date(s.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}</option>`
                    ).join('');

                    let html = `
                        <div style="display:flex;gap:20px;align-items:center;margin-bottom:25px;flex-wrap:wrap;">
                            <div style="display:flex;align-items:center;gap:10px;">
                                <label style="color:#8b949e;font-size:14px;">From:</label>
                                <select id="compare-from" style="min-width:150px;">${dateOptions}</select>
                            </div>
                            <div style="display:flex;align-items:center;gap:10px;">
                                <label style="color:#8b949e;font-size:14px;">To:</label>
                                <select id="compare-to" style="min-width:150px;">${dateOptions}</select>
                            </div>
                            <div style="background:#21262d;padding:8px 16px;border-radius:6px;color:#58a6ff;font-size:13px;">
                                <span style="color:#8b949e;">Period:</span> ${Math.round((new Date(to.date) - new Date(from.date)) / (1000 * 60 * 60 * 24))} days
                            </div>
                        </div>
                        <div class="comparison-grid">
                            <div class="comparison-card">
                                <h4>Modules</h4>
                                ${compareRow('Modularized', to.modularized_count, from.modularized_count)}
                                ${compareRow('Legacy', to.legacy_count, from.legacy_count, true)}
                                ${compareRow('Total Targets', to.total_targets, from.total_targets)}
                            </div>
                    `;

                    // Auto-generate comparison cards from fieldsMeta
                    comparisonFields.forEach(([fieldId, field]) => {
                        html += `<div class="comparison-card"><h4>${field.label}</h4>`;
                        if (field.values) {
                            Object.entries(field.values).forEach(([v, meta]) => {
                                const toVal = to.custom_metrics?.[`${fieldId}_${v}_count`] || 0;
                                const fromVal = from.custom_metrics?.[`${fieldId}_${v}_count`] || 0;
                                const inverted = field.inverted_comparison && meta.color !== 'green';
                                html += compareRow(meta.label, toVal, fromVal, inverted);
                            });
                        }
                        html += '</div>';
                    });

                    html += '</div>';

                    container.innerHTML = html;
                    document.getElementById('compare-from').value = compareFromIdx;
                    document.getElementById('compare-to').value = compareToIdx;
                    document.getElementById('compare-from').addEventListener('change', (e) => { compareFromIdx = parseInt(e.target.value); renderCompare(); });
                    document.getElementById('compare-to').addEventListener('change', (e) => { compareToIdx = parseInt(e.target.value); renderCompare(); });
                }

                function compareRow(label, curr, prev, inverted = false) {
                    const delta = (curr || 0) - (prev || 0);
                    const isGood = inverted ? delta < 0 : delta > 0;
                    const deltaClass = delta === 0 ? 'delta-neutral' : (isGood ? 'delta-positive' : 'delta-negative');
                    const sign = delta > 0 ? '+' : '';
                    return `<div class="comparison-row">
                        <span class="comparison-label">${label}</span>
                        <div class="comparison-values">
                            <span class="comparison-old">${prev || 0}</span>
                            <span class="comparison-arrow">→</span>
                            <span class="comparison-new">${curr || 0}</span>
                            <span class="comparison-delta ${deltaClass}">${sign}${delta}</span>
                        </div>
                    </div>`;
                }

                function showField(fieldId) {
                    const field = fieldsMeta[fieldId];
                    if (!field) return;
                    document.getElementById('modal-title').textContent = field.label;
                    let html = `<div class="field-info"><p>${field.description || ''}</p></div>`;
                    if (field.values) {
                        html += '<div class="field-info"><h4>Values</h4><div style="margin-top:10px;">';
                        for (const [k, v] of Object.entries(field.values)) {
                            const desc = v.description || k;
                            html += `<div style="margin-bottom:12px;"><span class="badge badge-${v.color}">${v.label}</span><p style="margin-top:4px;color:#8b949e;font-size:12px;">${desc}</p></div>`;
                        }
                        html += '</div></div>';
                    }
                    document.getElementById('modal-body').innerHTML = html;
                    document.getElementById('modal').classList.add('active');
                }

                function closeModal() { document.getElementById('modal').classList.remove('active'); }
                document.getElementById('modal').addEventListener('click', e => { if (e.target.id === 'modal') closeModal(); });

                init();
            </script>
        </body>
        </html>
        """
    }
}
