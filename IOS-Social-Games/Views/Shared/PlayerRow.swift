import SwiftUI

struct PlayerRow: View {
    let player: GamePlayer

    var isYou = false
    var detail: String? = nil
    var isComplete = false

    private var initial: String {
        String(player.name.prefix(1)).uppercased()
    }

    var body: some View {
        HStack(spacing: 14) {
            Text(initial)
                .font(.title3.weight(.medium))
                .foregroundStyle(GameTheme.ivory)
                .frame(width: 44, height: 44)
                .background(
                    GameTheme.elevated,
                    in: RoundedRectangle(cornerRadius: 13)
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(player.name)
                        .font(.subheadline.weight(.semibold))

                    if isYou {
                        Text("(You)")
                            .font(.caption)
                            .foregroundStyle(GameTheme.muted)
                    }
                }

                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(GameTheme.muted)
                } else if player.isHost {
                    Text("Host")
                        .font(.caption)
                        .foregroundStyle(GameTheme.accentLight)
                }
            }

            Spacer(minLength: 8)

            if isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(GameTheme.accentLight)
                    .accessibilityLabel("Complete")
            }
        }
        .foregroundStyle(GameTheme.ivory)
        .padding(.vertical, 5)
    }
}