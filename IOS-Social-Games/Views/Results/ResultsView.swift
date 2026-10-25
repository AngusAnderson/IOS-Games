import SwiftUI

struct ResultsView: View {
    @Environment(ImposterGameEngine.self) private var game
    @Environment(NearbyGameNetwork.self) private var network

    private var imposterWon: Bool {
        game.state.winner == "Imposter"
    }

    var body: some View {
        GameScreen {
            SectionHeading(
                title: "The truth",
                detail: "Round \(game.state.round)"
            )

            VStack(spacing: 18) {
                Image(
                    systemName: imposterWon
                        ? "eye.slash"
                        : "eye"
                )
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundStyle(GameTheme.accentLight)
                .accessibilityHidden(true)

                Text(
                    imposterWon
                        ? "Deception prevails."
                        : "The mask has fallen."
                )
                .font(.system(.largeTitle, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundStyle(GameTheme.ivory)

                Text(
                    imposterWon
                        ? "The imposter fooled the room."
                        : "The innocent found the imposter."
                )
                .font(.subheadline)
                .foregroundStyle(GameTheme.muted)
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)

            GamePanel {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeading(title: "Behind the mask")

                    Text(game.state.imposter?.name ?? "Unknown")
                        .font(.system(.title, design: .serif))
                        .foregroundStyle(GameTheme.accentLight)

                    Text("The imposter")
                        .font(.caption)
                        .foregroundStyle(GameTheme.muted)

                    Divider()
                        .overlay(GameTheme.ivory.opacity(0.08))

                    SectionHeading(title: "The secret prompt")

                    Text(game.state.prompt)
                        .font(.system(.title3, design: .serif))
                        .foregroundStyle(GameTheme.ivory)
                }
            }

            SectionHeading(title: "The accusations")

            GamePanel {
                VStack(spacing: 12) {
                    ForEach(game.state.players) { player in
                        PlayerRow(
                            player: player,
                            isYou: player.id == game.myID,
                            detail: voteDescription(for: player.id),
                            isComplete:
                                player.id == game.state.imposterID
                        )
                    }
                }
            }

            Text(
                "The innocent needed a strict majority. "
                + "A tie or no majority lets the imposter win."
            )
            .font(.caption)
            .foregroundStyle(GameTheme.muted)

            if game.isHost {
                GameActionButton(
                    title: "Gather again",
                    subtitle: "Return everyone to the lobby",
                    icon: "arrow.clockwise",
                    isPrimary: true
                ) {
                    game.resetGame(network: network)
                }
            } else {
                Text("Waiting for the host to start another gathering.")
                    .font(.subheadline)
                    .foregroundStyle(GameTheme.muted)
            }

            if let error = network.connectionError {
                ConnectionErrorCard(message: error)
            }
        }
        .navigationTitle("The reveal")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func voteDescription(for playerID: UUID) -> String {
        let count = game.state.votes.values.filter {
            $0 == playerID
        }.count

        return "\(count) \(count == 1 ? "vote" : "votes") received"
    }
}
