import Foundation

nonisolated enum GamePhase: String, Codable, Sendable {
    case lobby
    case prompting
    case discussing
    case voting
    case revealing
    case finished
}

nonisolated struct GamePlayer: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var isHost: Bool
    var isImposter: Bool
    var hasSubmittedClue: Bool
    var hasVoted: Bool

    init(
        id: UUID = UUID(),
        name: String,
        isHost: Bool = false,
        isImposter: Bool = false,
        hasSubmittedClue: Bool = false,
        hasVoted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.isHost = isHost
        self.isImposter = isImposter
        self.hasSubmittedClue = hasSubmittedClue
        self.hasVoted = hasVoted
    }
}

nonisolated struct GameState: Codable, Sendable {
    var phase: GamePhase = .lobby
    var players: [GamePlayer] = []
    var prompt: String = ""
    var clues: [UUID: String] = [:]
    var votes: [UUID: UUID] = [:]
    var imposterID: UUID?
    var round: Int = 1
    var winner: String?
    var clueMode: ClueMode = .spoken
    var currentPlayerID: UUID?

    var host: GamePlayer? {
        players.first(where: \.isHost)
    }

    var imposter: GamePlayer? {
        players.first(where: { $0.id == imposterID })
    }
    
    var currentPlayer: GamePlayer? {
        players.first {
            $0.id == currentPlayerID
        }
    }
}

nonisolated enum ClueMode: String, Codable, Sendable {
    case spoken
    case typed
}
