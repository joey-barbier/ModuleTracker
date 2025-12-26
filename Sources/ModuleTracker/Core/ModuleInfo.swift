import Foundation

/// Represents a discovered target within a module
struct TargetInfo {
    let name: String
    let path: URL
}

/// Represents a discovered module
struct ModuleInfo {
    let name: String
    let path: URL
    let source: String  // "spm", "app_features", "scenes", etc.
    let targets: [TargetInfo]

    init(name: String, path: URL, source: String, targets: [TargetInfo] = []) {
        self.name = name
        self.path = path
        self.source = source
        self.targets = targets
    }
}
