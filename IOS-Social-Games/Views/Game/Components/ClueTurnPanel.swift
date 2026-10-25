import SwiftUI

struct ClueTurnPanel: View {
    let mode: ClueMode
    let currentPlayer: GamePlayer?
    let isMyTurn: Bool
    let hasCompletedTurn: Bool
    let isSending: Bool

    @Binding var clue: String

    let onSubmitTypedClue: () -> Void
    let onCompleteSpokenTurn: () -> Void

    private var trimmedClue: String {
        clue.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    var body: some View {
        GamePanel {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeading(
                    title: mode == .spoken
                        ? "Speak carefully"
                        : "Choose your words"
                )

                if isMyTurn {
                    activeTurn
                } else {
                    waitingTurn
                }
            }
        }
    }

    private var activeTurn: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label(
                "The room is listening.",
                systemImage: mode == .spoken
                    ? "waveform"
                    : "pencil.line"
            )
            .font(.system(.title2, design: .serif))
            .foregroundStyle(GameTheme.ivory)

            if mode == .spoken {
                Text(
                    "Say your clue aloud. When you are finished, "
                    + "pass the turn to the next player."
                )
                .font(.subheadline)
                .foregroundStyle(GameTheme.muted)

                GameActionButton(
                    title: isSending
                        ? "Passing the turn…"
                        : "My turn is finished",
                    subtitle: "Choose the next player",
                    icon: "arrow.right",
                    isPrimary: true,
                    action: onCompleteSpokenTurn
                )
                .disabled(isSending)
                .opacity(isSending ? 0.45 : 1)
            } else {
                TextField(
                    "A subtle clue…",
                    text: $clue,
                    axis: .vertical
                )
                .lineLimit(2...4)
                .font(.system(.title3, design: .serif))
                .foregroundStyle(GameTheme.ivory)
                .disabled(isSending)

                GameActionButton(
                    title: isSending
                        ? "Sending…"
                        : "Seal your clue",
                    subtitle: "Then pass the turn",
                    icon: "envelope",
                    isPrimary: true,
                    action: onSubmitTypedClue
                )
                .disabled(trimmedClue.isEmpty || isSending)
                .opacity(
                    trimmedClue.isEmpty || isSending
                        ? 0.45
                        : 1
                )
            }
        }
    }

    private var waitingTurn: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(
                currentPlayer.map {
                    "\($0.name) has the floor."
                } ?? "Preparing the next turn…"
            )
            .font(.system(.title2, design: .serif))
            .foregroundStyle(GameTheme.ivory)

            Text(
                hasCompletedTurn
                    ? "Your turn is complete. Listen to the remaining clues."
                    : "Your turn is still to come. Listen carefully."
            )
            .font(.subheadline)
            .foregroundStyle(GameTheme.muted)

            Label(
                mode == .spoken
                    ? "Listen to their spoken clue"
                    : "Waiting for their written clue",
                systemImage: mode == .spoken
                    ? "ear"
                    : "text.bubble"
            )
            .font(.caption)
            .foregroundStyle(GameTheme.accentLight)
        }
    }
}
