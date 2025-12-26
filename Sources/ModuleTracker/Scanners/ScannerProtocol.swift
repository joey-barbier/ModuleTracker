import Foundation

/// Protocol for module scanners
/// Each scanner discovers modules from a specific source
protocol Scanner {
    /// Display name for this scanner
    static var name: String { get }

    /// Root path to scan from
    var rootPath: URL { get }

    /// Discover modules from this source
    func scan() -> [ModuleInfo]
}
