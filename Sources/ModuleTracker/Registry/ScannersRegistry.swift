import Foundation

/// Registry for module scanners.
/// Projects register their scanners here via Bootstrap.
final class ScannersRegistry {
    static let shared = ScannersRegistry()

    private init() {}

    /// Registered scanners with their names
    private var scanners: [(name: String, scan: (URL) -> [ModuleInfo])] = []

    /// Register a scanner
    /// - Parameters:
    ///   - name: Scanner identifier (e.g., "spm", "legacy", "scenes")
    ///   - scanner: Closure that scans the root path and returns modules
    func register(name: String, scanner: @escaping (URL) -> [ModuleInfo]) {
        scanners.append((name, scanner))
    }

    /// Scan all registered scanners
    /// - Parameter rootPath: Project root path
    /// - Returns: All discovered modules from all scanners
    func scanAll(rootPath: URL) -> [ModuleInfo] {
        scanners.flatMap { $0.scan(rootPath) }
    }

    /// Returns number of registered scanners
    var count: Int { scanners.count }

    /// Returns registered scanner names
    var registeredNames: [String] { scanners.map { $0.name } }
}
