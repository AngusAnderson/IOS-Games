import Foundation
import SwiftUI

@MainActor
@Observable
final class ImposterGameEngine {
    var state = GameState()
    var myID = UUID()
    var myName = UIDevice.current.name
    var myIsImposter = false
    var myPrompt: String?
    
    var isHost: Bool {
        state.host?.id == myID
    }
    
    var me: GamePlayer? {
        state.players.first(where: { $0.id == myId })
    }
    
    func handle(
        _ message: GameMessage,
        from senderID: UUID?,
        network: NearbyGameNetwork
    ) async {
        switch message {
        case .join(let name):
            guard isHost else { return }
            
            let player = GamePlayer(name: name)
            state.players.append(player)
            
            await network.broadcast(.playerJoined(player))
            await network.broadcast(.publicState(state))
            
        case .playerJoined(let player):
            if !state.players.contains(where: { $0.id == player.id }) {
                state.players.append(player)
            }
            
        case .startGame:
            guard isHost else { return }
            await startGame(network: network)
            
        case .privateRole(let isImposter, let prompt):
            myIsImposter = isImposter
            myPrompt = prompt
        
        case .publicState(let newState):
            state = newState
            
        case .submitClue(let newState):
            guard isHost, let senderID else { return }
            submitClue(playerID: senderID, clue: clue, network: network)
            
        case .reveal:
            state.phase = .revealing
            
        case .leave:
            break
        }
    }
    
    func becomeHost(network: NearbyGameNetwork) {
        state = GameState()
        state.players = [
            GamePlayer(
                id: myID,
                name: myName,
                isHost: true
            )
        ]
    }
    
    func startGame(network: NearbyGameNetwork) async {
        guard state.players.count >= 3 else { return }
        
        let imposter = state.players.randomElement();
        state.imposterID = imposter?.id
        state.phase = .prompting
        state.prompt = PromptLibrary.random()
        state.clues = [:]
        state.votes = [:]
        state.winner = nil
        
        for player in state.players {
            let isImposter = player.id == imposter.id
            let prompt = isImposter ? nil : state.prompt
            
            await network.sendToPlayer(
                .privateRole(isImposter: isImposter, prompt: prompt),
                playerID: player.id
            )
        }
        
        await network.broadcast(.publicState(state))
    }
    
    func sumbitClue(
        playerID: UUID,
        clue: String,
        network: NearbyGameNetwork
    ) {
        state.clues[playerID] = clue
        
        if let index = state.players.firstIndex(where: { $0.id == playerID }) {
            state.players[index].hasSumbittedClue = true
        }
        
        if state.clues.count == state.players.count {
            state.phase = .voting
        }
        
        Task {
            await network.broadcast(.publicState(state))
        }
    }
    
    func submitVote(
        voterID: UUID,
        accusedID: UUID,
        network: NearbyGameNetwork
    ) {
        state.votes[voterID] = accusedID
        
        if let index = state.players.firstIndex(where: { $0.id == voterID }) {
            state.players[index].hasVoted = true
        }
        
        if state.votes.count == state.players.count {
            finishRound(network: network)
        }
        
        Task {
            await network.broadcast(.publicState(state))
        }
    }
    
    private func finshRound(network: NearbyGameNetwork) {
        guard let imposterID = state.imposterID else { return }
        
        let votesForImposter = state.votes.values.filter( $0.id == imposterID).count
        
        let civiliansWin = votesForImposter > state.players.count / 2
        
        state.phase = .revealing
        state.winner = civiliansWin ? "Civillians" : "Imposter"
        
        Task {
            await network.broadcast(.publicState(state))
        }
    }
    
    func resetGame(network: NearbyNetworkGame) {
        guard isHost else { return }
        
        state.phase = .lobby
        state.prompt = ""
        state.clues = [:]
        state.votes = [:]
        state.imposterID = nil
        state.winner = nil
        state.round += 1
        
        for index in state.players.indices {
            state.players[index].isImposter = false
            state.players[index].hasSumbittedClue = false
            state.players[index].hasVoted = false
        }
        
        Task {
            await network.broadcast(.publicState(state))
        }
    }
}

enum PromptLibrary {
    // Temp test prompts
    static let prompts = [
        "Beach holiday",
        "Coffee shop",
        "Football match",
        "Guitar practice",
        "Late-night gaming",
        "Cooking dinner",
        "Road trip",
        "Music festival",
        "Shopping centre",
        "University lecture"
    ]
    
    static func random() -> String {
        prompts.randomElement()!
    }
}
