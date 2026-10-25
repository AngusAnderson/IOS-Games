import SwiftUI

struct ClueEntryCard: View {
    @Binding var clue: String

    let hasSubmitted: Bool
    let isSending: Bool
    let onSubmit: () -> Void

    private var isEmpty: Bool {
        clue.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
    }

    var body: some View {
        GamePanel {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeading(title: "Choose your words")

                if hasSubmitted {
                    Label(
                        "Your clue is sealed.",
                        systemImage: "checkmark.circle"
                    )
                    .foregroundStyle(GameTheme.accentLight)

                    Text("Wait for the rest of the room.")
                        .font(.subheadline)
                        .foregroundStyle(GameTheme.muted)
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
                        subtitle: "Your clue cannot be changed",
                        icon: "envelope",
                        isPrimary: true,
                        action: onSubmit
                    )
                    .disabled(isEmpty || isSending)
                    .opacity(isEmpty || isSending ? 0.45 : 1)
                }
            }
        }
    }
}