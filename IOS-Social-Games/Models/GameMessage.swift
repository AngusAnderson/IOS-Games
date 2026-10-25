import Foundation

enum GameMessage: Codable, Sendable {
    case join(name: String)
    case playerJoined(GamePlayer)
    case startGame
    case privateRole(isImposter: Bool, prompt: String?)
    case publicState(GameState)
    case submitClue(String)
    case submitVote(accusedID: UUID)
    case reveal
    case leave
}
