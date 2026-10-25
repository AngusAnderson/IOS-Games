import SwiftUI

struct ClueHistoryView: View {
    let players: [GamePlayer]
    let clues: [UUID: String]

    private var playersWithClues: [GamePlayer] {
        players.filter {
            clues[$0.id] != nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(
                title: "What has been said",
                detail: "\(playersWithClues.count) clues"
            )

            GamePanel {
                if playersWithClues.isEmpty {
                    Text(
                        "Written clues will appear here "
                        + "as each player takes their turn."
                    )
                    .font(.subheadline)
                    .foregroundStyle(GameTheme.muted)
                } else {
                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(playersWithClues) { player in
                            VStack(
                                alignment: .leading,
                                spacing: 7
                            ) {
                                Text(player.name)
                                    .font(
                                        .caption.monospaced()
                                    )
                                    .foregroundStyle(
                                        GameTheme.accentLight
                                    )

                                Text(clues[player.id] ?? "")
                                    .font(
                                        .system(
                                            .title3,
                                            design: .serif
                                        )
                                    )
                                    .foregroundStyle(
                                        GameTheme.ivory
                                    )
                                    .fixedSize(
                                        horizontal: false,
                                        vertical: true
                                    )
                            }
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                        }
                    }
                }
            }
        }
    }
}
