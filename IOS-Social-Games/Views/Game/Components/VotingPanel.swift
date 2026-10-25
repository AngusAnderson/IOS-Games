import SwiftUI

struct VotingPanel: View {
    let players: [GamePlayer]
    let currentPlayerID: UUID
    let hasVoted: Bool
    let isSending: Bool

    @Binding var selectedID: UUID?

    let onConfirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeading(title: "Make your accusation")

            Text(
                hasVoted
                    ? "Your decision is sealed."
                    : "Who doesn’t belong?"
            )
            .font(.system(.title, design: .serif))
            .foregroundStyle(GameTheme.ivory)

            if hasVoted {
                Text("Waiting for the remaining votes.")
                    .font(.subheadline)
                    .foregroundStyle(GameTheme.muted)
            } else {
                ForEach(
                    players.filter { $0.id != currentPlayerID }
                ) { player in
                    Button {
                        selectedID = player.id
                    } label: {
                        GamePanel {
                            HStack {
                                PlayerRow(player: player)

                                Image(
                                    systemName: selectedID == player.id
                                        ? "checkmark.circle.fill"
                                        : "circle"
                                )
                                .foregroundStyle(
                                    selectedID == player.id
                                        ? GameTheme.accentLight
                                        : GameTheme.muted
                                )
                            }
                        }
                    }
                    .buttonStyle(GamePressStyle())
                    .disabled(isSending)
                    .accessibilityValue(
                        selectedID == player.id
                            ? "Selected"
                            : "Not selected"
                    )
                }

                GameActionButton(
                    title: isSending
                        ? "Sending…"
                        : "Confirm accusation",
                    subtitle: "Once cast, your vote cannot change",
                    icon: "checkmark.seal",
                    isPrimary: true,
                    action: onConfirm
                )
                .disabled(selectedID == nil || isSending)
                .opacity(
                    selectedID == nil || isSending
                        ? 0.45
                        : 1
                )
            }
        }
    }
}