import Foundation

enum GamePhase: String, Codable, Sendable {
    case lobby
    case prompting
    case discussing
    case voting
    case revealing
    case finished
}

struct GamePlayer: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var isHost: Bool
    var isImposter: Bool
    var hasSumbittedClue: Bool
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
        self.hasSumbittedClue = hasSubmittedClue
        self.hasVoted = hasVoted
    }
}

struct GameState: Codable, Sendable {
    var phase: GamePhase = .lobby
    var players: [GamePlayer] = []
    var prompt: String = ""
    var clues: [UUID: String] = [:]
    var votes: [UUID: UUID] = [:]
    var imposterID: UUID?
    var round: Int = 1
    var winner: String?
    
    var host: GamePlayer? {
        players.first(where: \.isHost)
    }
    
    var imposter: GamePlayer? {
        players.first(where: { $0.id == imposterID })
    }
}
