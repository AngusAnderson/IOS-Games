import SwiftUI

struct GameView: View {
    @Environment(ImposterGameEngine.self) private var game
    @Environment(NearbyGameNetwork.self) private var network
    @Environment(\.scenePhase) private var scenePhase

    @State private var clue = ""
    @State private var selectedVote: UUID?
    @State private var roleIsRevealed = false
    @State private var isSending = false

    private var isMyTurn: Bool {
        game.state.currentPlayerID == game.myID
    }

    private var canAct: Bool {
        game.isHost || network.isConnected
    }

    private var hasPrivateRole: Bool {
        game.myCategory != nil
    }

    private var completedTurns: Int {
        game.state.players.filter {
            $0.hasSubmittedClue
        }.count
    }

    private var completedVotes: Int {
        game.state.players.filter {
            $0.hasVoted
        }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            switch game.state.phase {
            case .prompting, .discussing:
                cluePhase

            case .voting:
                votingPhase

            case .revealing, .finished:
                ResultsView()

            case .lobby:
                GameScreen {
                    Text("Returning to the gathering…")
                        .foregroundStyle(GameTheme.muted)
                }
            }
        }
        .navigationTitle("Round \(game.state.round)")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                roleIsRevealed = false
            }
        }
        .onChange(of: game.state.phase) { _, _ in
            roleIsRevealed = false
        }
        .onChange(of: game.state.currentPlayerID) { _, _ in
            clue = ""
        }
    }

    // MARK: - Clue phase

    private var cluePhase: some View {
        GameScreen {
            SectionHeading(
                title: "Round \(game.state.round)",
                detail: game.state.clueMode == .spoken
                    ? "Spoken clues"
                    : "Written clues"
            )

            // Visible to every player, not just the active one.
            privateRoleSection

            // Controls appear inside this panel only
            // when it is this player's turn.
            ClueTurnPanel(
                mode: game.state.clueMode,
                currentPlayer: game.state.currentPlayer,
                isMyTurn: isMyTurn,
                hasCompletedTurn:
                    game.me?.hasSubmittedClue == true,
                isSending: isSending,
                clue: $clue,
                onSubmitTypedClue: submitClue,
                onCompleteSpokenTurn: completeSpokenTurn
            )
            .disabled(!canAct)

            // Show submitted clues during the round,
            // not just once voting starts.
            if game.state.clueMode == .typed {
                ClueHistoryView(
                    players: game.state.players,
                    clues: game.state.clues
                )
            }

            progressPanel(isVoting: false)

            connectionFeedback
        }
    }

    // MARK: - Role information

    @ViewBuilder
    private var privateRoleSection: some View {
        if hasPrivateRole {
            RoleCard(
                isImposter: game.myIsImposter,
                prompt: game.myPrompt,
                category: game.myCategory,
                isRevealed: $roleIsRevealed
            )
        } else {
            GamePanel {
                HStack(spacing: 12) {
                    ProgressView()
                        .tint(GameTheme.accentLight)

                    Text("Waiting for your private role…")
                        .font(.subheadline)
                        .foregroundStyle(GameTheme.muted)
                }
            }
        }
    }

    // MARK: - Voting phase

    private var votingPhase: some View {
        GameScreen {
            SectionHeading(
                title: "Round \(game.state.round)",
                detail: "The accusations"
            )

            if game.state.clueMode == .typed {
                ClueHistoryView(
                    players: game.state.players,
                    clues: game.state.clues
                )
            } else {
                GamePanel {
                    Text(
                        "Everyone has spoken. "
                        + "Think about the clues you heard."
                    )
                    .font(.subheadline)
                    .foregroundStyle(GameTheme.muted)
                }
            }

            VotingPanel(
                players: game.state.players,
                currentPlayerID: game.myID,
                hasVoted: game.me?.hasVoted == true,
                isSending: isSending,
                selectedID: $selectedVote,
                onConfirm: submitVote
            )
            .disabled(!canAct)

            progressPanel(isVoting: true)

            connectionFeedback
        }
    }

    // MARK: - Progress

    private func progressPanel(
        isVoting: Bool
    ) -> some View {
        let completed = isVoting
            ? completedVotes
            : completedTurns

        return VStack(alignment: .leading, spacing: 14) {
            SectionHeading(
                title: isVoting
                    ? "Votes sealed"
                    : "Turns completed",
                detail:
                    "\(completed) / \(game.state.players.count)"
            )

            ProgressView(
                value: Double(completed),
                total: Double(max(game.state.players.count, 1))
            )
            .tint(GameTheme.accentLight)

            GamePanel {
                VStack(spacing: 10) {
                    ForEach(game.state.players) { player in
                        PlayerRow(
                            player: player,
                            isYou: player.id == game.myID,
                            detail: !isVoting &&
                                player.id == game.state.currentPlayerID
                                    ? "Has the floor"
                                    : nil,
                            isComplete: isVoting
                                ? player.hasVoted
                                : player.hasSubmittedClue
                        )
                    }
                }
            }
        }
    }

    // MARK: - Connection feedback

    @ViewBuilder
    private var connectionFeedback: some View {
        if let error = network.connectionError {
            ConnectionErrorCard(message: error)
        }

        if !canAct {
            Text("You are no longer connected to the host.")
                .font(.caption)
                .foregroundStyle(GameTheme.accentLight)
        }
    }

    // MARK: - Typed clue

    private func submitClue() {
        let text = clue.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard canAct,
              isMyTurn,
              !isSending,
              game.state.clueMode == .typed,
              game.me?.hasSubmittedClue != true,
              !text.isEmpty
        else {
            return
        }

        roleIsRevealed = false
        isSending = true

        Task { @MainActor in
            defer {
                isSending = false
            }

            if game.isHost {
                game.submitClue(
                    playerID: game.myID,
                    clue: text,
                    network: network
                )
            } else {
                await network.sendToHost(
                    .submitClue(text)
                )
            }
        }
    }

    // MARK: - Spoken turn

    private func completeSpokenTurn() {
        guard canAct,
              isMyTurn,
              !isSending,
              game.state.clueMode == .spoken,
              game.me?.hasSubmittedClue != true
        else {
            return
        }

        roleIsRevealed = false
        isSending = true

        Task { @MainActor in
            defer {
                isSending = false
            }

            if game.isHost {
                game.completeSpokenTurn(
                    playerID: game.myID,
                    network: network
                )
            } else {
                await network.sendToHost(
                    .completeSpokenTurn
                )
            }
        }
    }

    // MARK: - Voting

    private func submitVote() {
        guard canAct,
              let selectedVote,
              !isSending,
              game.state.phase == .voting,
              game.me?.hasVoted != true
        else {
            return
        }

        isSending = true

        Task { @MainActor in
            defer {
                isSending = false
            }

            if game.isHost {
                game.submitVote(
                    voterID: game.myID,
                    accusedID: selectedVote,
                    network: network
                )
            } else {
                await network.sendToHost(
                    .submitVote(accusedID: selectedVote)
                )
            }
        }
    }
}
