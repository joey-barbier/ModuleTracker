import Foundation

/// Orchestrates all module scanners via ScannersRegistry.
/// By default, no scanners are registered - projects add their own via Bootstrap.
struct ScannersEngine {

    let rootPath: URL

    /// Scans all registered scanners
    /// Returns empty if no scanners registered
    func scanAll() -> [ModuleInfo] {
        ScannersRegistry.shared.scanAll(rootPath: rootPath)
    }
}
