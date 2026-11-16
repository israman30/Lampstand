import Foundation

/// Centralized console logging for Lampstand so app lifecycle, fetches, queries,
/// and failures are easy to find in Xcode's console.
enum LampstandLog {
    enum Category: String {
        case app
        case fetch
        case query
        case success
        case failure

        var emoji: String {
            switch self {
            case .app:
                return "⚙️"
            case .fetch:
                return "🚀"
            case .query:
                return "🔎"
            case .success:
                return "✅"
            case .failure:
                return "❌"
            }
        }
    }

    private static let prefix = "[LAMPSTAND]"
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    static func app(_ message: String, details: String = "") {
        log(.app, message: message, details: details)
    }

    static func fetch(_ message: String, details: String = "") {
        log(.fetch, message: message, details: details)
    }

    static func query(_ message: String, details: String = "") {
        log(.query, message: message, details: details)
    }

    static func success(_ message: String, details: String = "") {
        log(.success, message: message, details: details)
    }

    static func failure(_ message: String, details: String = "", error: Error? = nil) {
        log(.failure, message: message, details: details, error: error)
    }

    private static func log(_ category: Category, message: String, details: String = "", error: Error? = nil) {
        let timestamp = timeFormatter.string(from: Date())
        var parts: [String] = [
            "\(prefix) [\(category.emoji)] [\(category.rawValue.uppercased())]",
            timestamp,
            message
        ]

        if !details.isEmpty {
            parts.append(details)
        }

        if let error {
            parts.append("error=\(String(describing: error))")
        }

        print(parts.joined(separator: " | "))
    }
}
