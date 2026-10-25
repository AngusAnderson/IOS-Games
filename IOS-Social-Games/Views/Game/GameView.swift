import SwiftUI

struct GameView: View {
    @Environment(ImposterGameEngine.self) private var game
    @Environment(NearbyGameNetwork.self) private var network
    @Environment(\.scenePhase) private var scenePhase

    @State private var clue = ""
    @State private var selectedVote: UUID?
    @State private var roleIsRevealed = false
    @State private var isSending = false

    private var isVoting: Bool {
        game.state.phase == .voting
    }

    private var completedCount: Int {
        game.state.players.filter {
            isVoting ? $0.hasVoted : $0.hasSubmittedClue
        }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            if game.state.phase == .revealing ||
                game.state.phase == .finished {
                ResultsView()
            } else {
                roundContent
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
    }

    private var roundContent: some View {
        GameScreen {
            SectionHeading(
                title: "Round \(game.state.round)",
                detail: isVoting ? "Accusations" : "The clues"
            )

            if isVoting {
                clueSummary

                VotingPanel(
                    players: game.state.players,
                    currentPlayerID: game.myID,
                    hasVoted: game.me?.hasVoted == true,
                    isSending: isSending,
                    selectedID: $selectedVote,
                    onConfirm: submitVote
                )
            } else {
                RoleCard(
                    isImposter: game.myIsImposter,
                    prompt: game.myPrompt,
                    category: game.myCategory,
                    isRevealed: $roleIsRevealed
                )

                ClueEntryCard(
                    clue: $clue,
                    hasSubmitted:
                        game.me?.hasSubmittedClue == true,
                    isSending: isSending,
                    onSubmit: submitClue
                )
            }

            progressPanel

            if let error = network.connectionError {
                ConnectionErrorCard(message: error)
            }
        }
    }

    private var progressPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(
                title: isVoting ? "Votes sealed" : "Clues sealed",
                detail:
                    "\(completedCount) / \(game.state.players.count)"
            )

            ProgressView(
                value: Double(completedCount),
                total: Double(max(game.state.players.count, 1))
            )
            .tint(GameTheme.accentLight)

            GamePanel {
                VStack(spacing: 10) {
                    ForEach(game.state.players) { player in
                        PlayerRow(
                            player: player,
                            isYou: player.id == game.myID,
                            isComplete: isVoting
                                ? player.hasVoted
                                : player.hasSubmittedClue
                        )
                    }
                }
            }
        }
    }

    private var clueSummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(title: "What everyone said")

            GamePanel {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(game.state.players) { player in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(player.name)
                                .font(.caption)
                                .foregroundStyle(GameTheme.muted)

                            Text(game.state.clues[player.id] ?? "—")
                                .font(
                                    .system(
                                        .body,
                                        design: .serif
                                    )
                                )
                                .foregroundStyle(GameTheme.ivory)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func submitClue() {
        let text = clue.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !text.isEmpty, !isSending else {
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

    private func submitVote() {
        guard let selectedVote, !isSending else {
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
