import Foundation

public struct LaunchAtLoginStatus: Equatable, Sendable {
    public let isEnabled: Bool
    public let isAvailable: Bool

    public init(isEnabled: Bool, isAvailable: Bool) {
        self.isEnabled = isEnabled
        self.isAvailable = isAvailable
    }
}

public enum LaunchAtLoginError: Equatable, LocalizedError {
    case appBundleRequired
    case invalidBundleIdentifier
    case unableToCreateLaunchAgent
    case unableToWriteLaunchAgent
    case unableToRemoveLaunchAgent

    public var errorDescription: String? {
        switch self {
        case .appBundleRequired:
            "Open at Login is available only when Go To Sleep is launched from Go To Sleep.app."
        case .invalidBundleIdentifier:
            "Go To Sleep couldn't determine a safe login item identifier."
        case .unableToCreateLaunchAgent:
            "Go To Sleep couldn't create its login item configuration."
        case .unableToWriteLaunchAgent:
            "Go To Sleep couldn't save its Open at Login setting."
        case .unableToRemoveLaunchAgent:
            "Go To Sleep couldn't remove its Open at Login setting."
        }
    }
}

public protocol LaunchAtLoginControlling {
    func currentStatus() -> LaunchAtLoginStatus
    func syncRegistrationIfNeeded() throws -> LaunchAtLoginStatus
    func setEnabled(_ isEnabled: Bool) throws -> LaunchAtLoginStatus
}

public final class LaunchAtLoginController: LaunchAtLoginControlling {
    private static let fallbackBundleIdentifier = "com.benbolte.gotosleep"
    private static let validLabelCharacters = CharacterSet(
        charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-"
    )

    private let fileManager: FileManager
    private let launchAgentDirectoryURL: URL
    private let bundleURLProvider: () -> URL
    private let executableURLProvider: () -> URL?
    private let bundleIdentifierProvider: () -> String?

    public init(
        fileManager: FileManager = .default,
        launchAgentDirectoryURL: URL? = nil,
        bundleURLProvider: @escaping () -> URL = { Bundle.main.bundleURL },
        executableURLProvider: @escaping () -> URL? = { Bundle.main.executableURL },
        bundleIdentifierProvider: @escaping () -> String? = { Bundle.main.bundleIdentifier }
    ) {
        self.fileManager = fileManager
        self.launchAgentDirectoryURL = launchAgentDirectoryURL
            ?? fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents", isDirectory: true)
        self.bundleURLProvider = bundleURLProvider
        self.executableURLProvider = executableURLProvider
        self.bundleIdentifierProvider = bundleIdentifierProvider
    }

    public func currentStatus() -> LaunchAtLoginStatus {
        let launchAgentURL = launchAgentURL
        return LaunchAtLoginStatus(
            isEnabled: launchAgentURL.map { fileManager.fileExists(atPath: $0.path) } ?? false,
            isAvailable: bundledExecutableURL != nil && launchAgentURL != nil
        )
    }

    public func syncRegistrationIfNeeded() throws -> LaunchAtLoginStatus {
        let status = currentStatus()
        guard status.isEnabled, status.isAvailable else {
            return status
        }

        return try setEnabled(true)
    }

    public func setEnabled(_ isEnabled: Bool) throws -> LaunchAtLoginStatus {
        if isEnabled {
            try writeLaunchAgent()
        } else {
            try removeLaunchAgent()
        }

        return currentStatus()
    }

    private var bundledExecutableURL: URL? {
        let bundleURL = bundleURLProvider().resolvingSymlinksInPath()
        guard bundleURL.pathExtension.caseInsensitiveCompare("app") == .orderedSame,
              let executableURL = executableURLProvider()?.resolvingSymlinksInPath(),
              executableURL.path.hasPrefix(bundleURL.path + "/") else {
            return nil
        }

        return executableURL
    }

    private var launchAgentLabel: String? {
        let label = bundleIdentifierProvider() ?? Self.fallbackBundleIdentifier
        return Self.isValidLaunchAgentLabel(label) ? label : nil
    }

    private var launchAgentURL: URL? {
        guard let launchAgentLabel else {
            return nil
        }

        return launchAgentDirectoryURL.appendingPathComponent("\(launchAgentLabel).plist")
    }

    private func writeLaunchAgent() throws {
        guard let executableURL = bundledExecutableURL else {
            throw LaunchAtLoginError.appBundleRequired
        }
        guard let launchAgentLabel, let launchAgentURL else {
            throw LaunchAtLoginError.invalidBundleIdentifier
        }

        let propertyList: [String: Any] = [
            "Label": launchAgentLabel,
            "ProgramArguments": [executableURL.path],
            "RunAtLoad": true,
        ]

        let data: Data
        do {
            data = try PropertyListSerialization.data(
                fromPropertyList: propertyList,
                format: .xml,
                options: 0
            )
        } catch {
            throw LaunchAtLoginError.unableToWriteLaunchAgent
        }

        do {
            try fileManager.createDirectory(
                at: launchAgentDirectoryURL,
                withIntermediateDirectories: true
            )
        } catch {
            throw LaunchAtLoginError.unableToCreateLaunchAgent
        }

        do {
            try data.write(to: launchAgentURL, options: .atomic)
        } catch {
            throw LaunchAtLoginError.unableToWriteLaunchAgent
        }
    }

    private func removeLaunchAgent() throws {
        guard let launchAgentURL else {
            return
        }
        guard fileManager.fileExists(atPath: launchAgentURL.path) else {
            return
        }

        do {
            try fileManager.removeItem(at: launchAgentURL)
        } catch {
            throw LaunchAtLoginError.unableToRemoveLaunchAgent
        }
    }

    private static func isValidLaunchAgentLabel(_ label: String) -> Bool {
        guard !label.isEmpty,
              !label.hasPrefix("."),
              !label.hasSuffix("."),
              !label.contains("..") else {
            return false
        }

        return label.unicodeScalars.allSatisfy { validLabelCharacters.contains($0) }
    }
}
