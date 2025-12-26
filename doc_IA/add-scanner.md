# Skill: Add a Module Scanner

## Context
ModuleTracker uses scanners to discover modules in the codebase. Each scanner finds a specific type of module (SPM packages, legacy features, etc.).

ModuleTracker is an **empty shell** by design - scanners register themselves via the Registry pattern.

## Files to Create/Modify

### 1. Create the Scanner File
**Location:** Any location in your project (e.g., `Scanners/YourScanner.swift`)

```swift
import Foundation

struct YourScanner {
    let rootPath: URL

    // Auto-registration pattern
    static let _register: Void = {
        ScannersRegistry.shared.register(name: "your_source") { rootPath in
            YourScanner(rootPath: rootPath).scan()
        }
    }()

    func scan() -> [ModuleInfo] {
        var modules: [ModuleInfo] = []

        let searchPath = rootPath.appendingPathComponent("Your/Search/Path")

        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: searchPath,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return modules
        }

        for itemURL in contents {
            // Skip unwanted directories
            let ignoredDirs = ["Deprecated", "Legacy", ".DS_Store"]
            if ignoredDirs.contains(itemURL.lastPathComponent) { continue }

            // Check if it's a valid module
            guard isValidModule(at: itemURL) else { continue }

            let module = ModuleInfo(
                name: itemURL.lastPathComponent,
                path: itemURL,
                source: "your_source"  // String identifier
            )
            modules.append(module)
        }

        return modules.sorted { $0.name < $1.name }
    }

    private func isValidModule(at path: URL) -> Bool {
        // Your validation logic
        return true
    }
}
```

### 2. Register in Bootstrap.swift
**Location:** `Sources/ModuleTracker/Bootstrap.swift`

```swift
enum Bootstrap {
    static func register() {
        // Scanners
        _ = YourScanner._register

        // Other scanners...
    }
}
```

That's it! No need to modify `ScannersEngine.swift` or `main.swift`.

## How It Works

1. `Bootstrap.register()` is called at startup
2. Accessing `YourScanner._register` triggers the lazy static closure
3. The closure calls `ScannersRegistry.shared.register()`
4. `ScannersEngine` automatically loops over all registered scanners

## Example: Adding a "Pods Scanner"

```swift
// Scanners/PodsScanner.swift
import Foundation

struct PodsScanner {
    let rootPath: URL

    static let _register: Void = {
        ScannersRegistry.shared.register(name: "pods") { rootPath in
            PodsScanner(rootPath: rootPath).scan()
        }
    }()

    func scan() -> [ModuleInfo] {
        var modules: [ModuleInfo] = []

        let podsPath = rootPath.appendingPathComponent("Pods")
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: podsPath,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return modules
        }

        for podURL in contents {
            guard podURL.hasDirectoryPath else { continue }

            // Skip Pods metadata
            if podURL.lastPathComponent.hasPrefix("Pods") { continue }

            modules.append(ModuleInfo(
                name: podURL.lastPathComponent,
                path: podURL,
                source: "pods"
            ))
        }

        return modules.sorted { $0.name < $1.name }
    }
}
```

Then register:
```swift
// Bootstrap.swift
_ = PodsScanner._register
```

## ModuleInfo Reference

```swift
struct ModuleInfo {
    let name: String      // Module name
    let path: URL         // Filesystem path
    let source: String    // Source identifier (e.g., "spm", "pods", "legacy")
}
```

The `source` is a simple String - no enum needed. Use snake_case for consistency.

## Checklist
- [ ] Scanner file created with `_register` static property
- [ ] `scan()` returns `[ModuleInfo]` with `source: "your_source"`
- [ ] Scanner registered in `Bootstrap.swift` via `_ = YourScanner._register`
- [ ] Run `swift build` to verify compilation
