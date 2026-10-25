import Foundation

nonisolated enum DisconnectReason: String, Codable, Sendable {
    case removedByHost
    case connectionLost

    var message: String {
        switch self {
        case .removedByHost:
            return "You were removed from the gathering by the host."

        case .connectionLost:
            return "The connection ended."
        }
    }
}