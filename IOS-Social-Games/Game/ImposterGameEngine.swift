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

        case .privateRole(let isImposter, let prompt):
            guard !isHost else {
                return
            }

            myIsImposter = isImposter
            myPrompt = prompt

        case .publicState(let newState):
            guard !isHost else {
                return
            }

            state = newState

            if newState.phase == .lobby {
                myIsImposter = false
                myPrompt = nil
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
            // The host publishes the reveal through publicState.
            break

        case .leave:
            // Player removal/disconnection handling belongs
            // in the next networking milestone.
            break
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

        state.imposterID = imposter.id
        state.prompt = PromptLibrary.random()
        state.phase = .prompting

        state.clues = [:]
        state.votes = [:]
        state.winner = nil

        for index in state.players.indices {
            state.players[index].isImposter = false
            state.players[index].hasSubmittedClue = false
            state.players[index].hasVoted = false
        }

        for player in state.players {
            let isImposter = player.id == imposter.id
            let prompt: String? = isImposter ? nil : state.prompt

            if player.id == myID {
                // The host does not send a network message to itself.
                myIsImposter = isImposter
                myPrompt = prompt
            } else {
                await network.sendToPlayer(
                    .privateRole(
                        isImposter: isImposter,
                        prompt: prompt
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
              state.phase == .prompting ||
              state.phase == .discussing
        else {
            return
        }

        guard let index = state.players.firstIndex(
            where: { $0.id == playerID }
        ) else {
            return
        }

        guard state.clues[playerID] == nil else {
            return
        }

        let trimmedClue = clue.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedClue.isEmpty else {
            return
        }

        state.clues[playerID] = trimmedClue
        state.players[index].hasSubmittedClue = true

        if state.clues.count == state.players.count {
            state.phase = .voting
        }

        schedulePublicStateBroadcast(network: network)
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

        // This version uses a strict majority.
        // A tie or no majority means the imposter wins.
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

        myIsImposter = false
        myPrompt = nil

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

            // Keep individual choices private until voting ends.
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
}

// MARK: - Prompt library

enum PromptLibrary {
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
        prompts.randomElement() ?? "Coffee shop"
    }
}
