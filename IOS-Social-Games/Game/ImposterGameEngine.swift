import Foundation
import SwiftUI
import UIKit

@MainActor
@Observable
final class ImposterGameEngine {
    var state = GameState()

    var myID = UUID()
    var myName = UIDevice.current.name
    var myIsImposter = false
    var myPrompt: String?
    var myCategory: String?

    var isHost: Bool {
        state.host?.id == myID
    }

    var me: GamePlayer? {
        state.players.first { $0.id == myID }
    }

    // MARK: - Incoming messages

    func handle(
        _ message: GameMessage,
        from senderID: UUID?,
        network: NearbyGameNetwork
    ) async {
        switch message {
        case .join(let name):
            guard isHost,
                  state.phase == .lobby,
                  let senderID,
                  !state.players.contains(where: { $0.id == senderID })
            else {
                return
            }

            let player = GamePlayer(
                id: senderID,
                name: name
            )

            state.players.append(player)

            await broadcastPublicState(network: network)

        case .playerJoined(let player):
            guard !isHost else {
                return
            }

            if !state.players.contains(where: { $0.id == player.id }) {
                state.players.append(player)
            }

        case .startGame:
            break

        case .privateRole(
            let isImposter,
            let prompt,
            let category
        ):
            guard !isHost else {
                return
            }

            myIsImposter = isImposter
            myPrompt = prompt
            myCategory = category

        case .publicState(let newState):
            guard !isHost else {
                return
            }

            state = newState

            if newState.phase == .lobby {
                myIsImposter = false
                myPrompt = nil
                myCategory = nil
            }

        case .submitClue(let clue):
            guard isHost, let senderID else {
                return
            }

            submitClue(
                playerID: senderID,
                clue: clue,
                network: network
            )

        case .submitVote(let accusedID):
            guard isHost, let senderID else {
                return
            }

            submitVote(
                voterID: senderID,
                accusedID: accusedID,
                network: network
            )

        case .reveal:
            break

        case .leave:
            break
            
        case .completeSpokenTurn:
            guard isHost, let senderID else {
                return
            }

            completeSpokenTurn(
                playerID: senderID,
                network: network
            )
        }
    }

    // MARK: - Hosting

    func becomeHost(network: NearbyGameNetwork) {
        myID = network.localID

        state = GameState()
        state.players = [
            GamePlayer(
                id: myID,
                name: myName,
                isHost: true
            )
        ]

        myIsImposter = false
        myPrompt = nil
        myCategory = nil
    }

    // MARK: - Starting a round

    func startGame(network: NearbyGameNetwork) async {
        guard isHost,
              state.phase == .lobby,
              state.players.count >= 3,
              let imposter = state.players.randomElement()
        else {
            return
        }

        let selectedPrompt = PromptLibrary.random()

        state.imposterID = imposter.id
        state.prompt = selectedPrompt.text
        state.phase = .prompting

        state.clues = [:]
        state.votes = [:]
        state.winner = nil
        state.currentPlayerID = nil

        for index in state.players.indices {
            state.players[index].isImposter = false
            state.players[index].hasSubmittedClue = false
            state.players[index].hasVoted = false
        }

        state.currentPlayerID = state.players.randomElement()?.id

        for player in state.players {
            let isImposter = player.id == imposter.id

            let privatePrompt: String? = isImposter
                ? nil
                : selectedPrompt.text

            let category = selectedPrompt.category.rawValue

            if player.id == myID {
                myIsImposter = isImposter
                myPrompt = privatePrompt
                myCategory = category
            } else {
                await network.sendToPlayer(
                    .privateRole(
                        isImposter: isImposter,
                        prompt: privatePrompt,
                        category: category
                    ),
                    playerID: player.id
                )
            }
        }

        await broadcastPublicState(network: network)
    }

    // MARK: - Clues

    func submitClue(
        playerID: UUID,
        clue: String,
        network: NearbyGameNetwork
    ) {
        guard isHost,
              state.clueMode == .typed,
              state.phase == .prompting ||
              state.phase == .discussing,
              state.currentPlayerID == playerID,
              let index = state.players.firstIndex(
                  where: { $0.id == playerID }
              ),
              !state.players[index].hasSubmittedClue
        else {
            return
        }

        let text = clue.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !text.isEmpty else {
            return
        }

        state.clues[playerID] = text

        finishClueTurn(
            playerIndex: index,
            network: network
        )
    }

    // MARK: - Voting

    func submitVote(
        voterID: UUID,
        accusedID: UUID,
        network: NearbyGameNetwork
    ) {
        guard isHost, state.phase == .voting else {
            return
        }

        guard let voterIndex = state.players.firstIndex(
            where: { $0.id == voterID }
        ) else {
            return
        }

        guard state.players.contains(
            where: { $0.id == accusedID }
        ) else {
            return
        }

        guard voterID != accusedID,
              state.votes[voterID] == nil
        else {
            return
        }

        state.votes[voterID] = accusedID
        state.players[voterIndex].hasVoted = true

        if state.votes.count == state.players.count {
            finishRound()
        }

        schedulePublicStateBroadcast(network: network)
    }

    private func finishRound() {
        guard let imposterID = state.imposterID else {
            return
        }

        let votesForImposter = state.votes.values.filter {
            $0 == imposterID
        }.count

        let civiliansWin =
            votesForImposter > state.players.count / 2

        state.phase = .revealing
        state.winner = civiliansWin ? "Civilians" : "Imposter"

        for index in state.players.indices {
            state.players[index].isImposter =
                state.players[index].id == imposterID
        }
    }

    // MARK: - Replay

    func resetGame(network: NearbyGameNetwork) {
        guard isHost else {
            return
        }

        state.phase = .lobby
        state.prompt = ""
        state.clues = [:]
        state.votes = [:]
        state.imposterID = nil
        state.winner = nil
        state.round += 1
        state.currentPlayerID = nil

        myIsImposter = false
        myPrompt = nil
        myCategory = nil

        for index in state.players.indices {
            state.players[index].isImposter = false
            state.players[index].hasSubmittedClue = false
            state.players[index].hasVoted = false
        }

        schedulePublicStateBroadcast(network: network)
    }

    // MARK: - Public state

    private func makePublicState() -> GameState {
        var publicState = state

        let isRevealed =
            state.phase == .revealing ||
            state.phase == .finished

        if !isRevealed {
            publicState.prompt = ""
            publicState.imposterID = nil

            for index in publicState.players.indices {
                publicState.players[index].isImposter = false
            }

            publicState.votes = [:]
        }

        return publicState
    }

    private func broadcastPublicState(
        network: NearbyGameNetwork
    ) async {
        await network.broadcast(
            .publicState(makePublicState())
        )
    }

    private func schedulePublicStateBroadcast(
        network: NearbyGameNetwork
    ) {
        Task { [weak self] in
            guard let self else {
                return
            }

            await self.broadcastPublicState(network: network)
        }
    }
    
    // MARK: - Membership changes

    func playerDisconnected(
        playerID: UUID,
        network: NearbyGameNetwork
    ) {
        guard isHost,
              playerID != myID,
              state.players.contains(where: { $0.id == playerID })
        else {
            return
        }

        let interruptedRound =
            state.phase == .prompting ||
            state.phase == .discussing ||
            state.phase == .voting

        state.players.removeAll {
            $0.id == playerID
        }

        state.clues.removeValue(forKey: playerID)

        state.votes = state.votes.filter { entry in
            entry.key != playerID && entry.value != playerID
        }

        if interruptedRound {
            resetGame(network: network)

            network.connectionError =
                "A player disconnected. The round was cancelled."

            return
        }

        Task { @MainActor in
            await self.broadcastPublicState(network: network)
        }
    }
    
    // MARK: Answer mode changes
    
    func setClueMode(
        _ mode: ClueMode,
        network: NearbyGameNetwork
    ) {
        guard isHost, state.phase == .lobby else {
            return
        }

        state.clueMode = mode

        schedulePublicStateBroadcast(network: network)
    }
    
    // MARK: Complete turn
    
    func completeSpokenTurn(
        playerID: UUID,
        network: NearbyGameNetwork
    ) {
        guard isHost,
              state.clueMode == .spoken,
              state.phase == .prompting ||
              state.phase == .discussing,
              state.currentPlayerID == playerID,
              let index = state.players.firstIndex(
                  where: { $0.id == playerID }
              ),
              !state.players[index].hasSubmittedClue
        else {
            return
        }

        finishClueTurn(
            playerIndex: index,
            network: network
        )
    }
    
    // MARK: Shared turn
    
    private func finishClueTurn(
        playerIndex: Int,
        network: NearbyGameNetwork
    ) {
        state.players[playerIndex].hasSubmittedClue = true

        let remainingPlayers = state.players.filter {
            !$0.hasSubmittedClue
        }

        if let nextPlayer = remainingPlayers.randomElement() {
            state.currentPlayerID = nextPlayer.id
        } else {
            state.currentPlayerID = nil
            state.phase = .voting
        }

        schedulePublicStateBroadcast(network: network)
    }
}
