import SwiftUI

struct LobbyPlayerRow: View {
    let player: GamePlayer
    let isYou: Bool
    let canRemove: Bool
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            PlayerRow(
                player: player,
                isYou: isYou
            )

            if canRemove {
                Menu {
                    Button(
                        "Remove from gathering",
                        systemImage: "person.crop.circle.badge.minus",
                        role: .destructive,
                        action: onRemove
                    )
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.headline)
                        .foregroundStyle(GameTheme.muted)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(
                    "Options for \(player.name)"
                )
            }
        }
    }
}
