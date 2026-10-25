import SwiftUI

struct ClueModeSettingsCard: View {
    @Environment(ImposterGameEngine.self) private var game
    @Environment(NearbyGameNetwork.self) private var network

    private var spokenClues: Binding<Bool> {
        Binding(
            get: {
                game.state.clueMode == .spoken
            },
            set: { enabled in
                game.setClueMode(
                    enabled ? .spoken : .typed,
                    network: network
                )
            }
        )
    }

    var body: some View {
        GamePanel {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeading(title: "How the room speaks")

                if game.isHost {
                    Toggle(
                        "Say clues aloud",
                        isOn: spokenClues
                    )
                    .font(.subheadline.weight(.medium))
                    .tint(GameTheme.accentLight)
                } else {
                    Label(
                        game.state.clueMode == .spoken
                            ? "Spoken clues"
                            : "Typed clues",
                        systemImage:
                            game.state.clueMode == .spoken
                                ? "waveform"
                                : "keyboard"
                    )
                    .foregroundStyle(GameTheme.ivory)
                }

                Text(
                    game.state.clueMode == .spoken
                        ? "Each player speaks on their turn, then "
                            + "confirms they are finished."
                        : "Each player types a clue on their turn. "
                            + "Only the active player can submit."
                )
                .font(.caption)
                .foregroundStyle(GameTheme.muted)

                Text("Turn order is chosen randomly.")
                    .font(.caption)
                    .foregroundStyle(GameTheme.accentLight)
            }
        }
    }
}
