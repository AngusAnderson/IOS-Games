import SwiftUI

struct LobbyContent: View {
    @Environment(ImposterGameEngine.self) private var game
    @Environment(NearbyGameNetwork.self) private var network

    let isHost: Bool

    private var status: String {
        if isHost {
            return network.isHosting
                ? "The room is open"
                : "Preparing the room…"
        }

        if network.isConnected {
            return "You’re in the room"
        }

        return network.isJoining
            ? "Entering the room…"
            : "Find your gathering"
    }

    var body: some View {
        GameScreen {
            SectionHeading(
                title: "The gathering",
                detail: "\(game.state.players.count) players"
            )

            Text(status)
                .font(.system(.largeTitle, design: .serif))
                .foregroundStyle(GameTheme.ivory)

            Text("Among familiar faces, someone will hide a secret.")
                .font(.subheadline)
                .foregroundStyle(GameTheme.muted)

            GamePanel {
                HStack(spacing: 12) {
                    if network.isJoining {
                        ProgressView()
                            .tint(GameTheme.accentLight)
                    } else {
                        Image(systemName: "wifi")
                            .foregroundStyle(GameTheme.accentLight)
                    }

                    Text(connectionDescription)
                        .font(.subheadline)
                        .foregroundStyle(GameTheme.ivory)
                }
            }

            if !game.state.players.isEmpty {
                SectionHeading(title: "Those present")

                GamePanel {
                    VStack(spacing: 12) {
                        ForEach(game.state.players) { player in
                            PlayerRow(
                                player: player,
                                isYou: player.id == game.myID
                            )
                        }
                    }
                }
            }

            if isHost {
                GameActionButton(
                    title: "Begin the deception",
                    subtitle: "Assign everyone a secret role",
                    icon: "eye",
                    isPrimary: true
                ) {
                    Task {
                        await game.startGame(network: network)
                    }
                }
                .disabled(
                    !network.isHosting ||
                    game.state.players.count < 3
                )
                .opacity(
                    network.isHosting &&
                    game.state.players.count >= 3
                        ? 1
                        : 0.45
                )

                Text("At least three players must be present.")
                    .font(.caption)
                    .foregroundStyle(GameTheme.muted)
            } else if network.isConnected {
                Text("Waiting for the host to begin.")
                    .font(.subheadline)
                    .foregroundStyle(GameTheme.muted)
            } else {
                nearbyGames
            }

            if let error = network.connectionError {
                ConnectionErrorCard(message: error)
            }
        }
        .navigationTitle("The gathering")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var connectionDescription: String {
        if isHost {
            return network.isHosting
                ? "Advertising on the local network"
                : "Starting host"
        }

        return network.isConnected
            ? "Connected to the host"
            : "Searching the local network"
    }

    private var nearbyGames: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(title: "Nearby rooms")

            if network.discoveredHosts.isEmpty {
                Text("No gatherings discovered yet.")
                    .font(.subheadline)
                    .foregroundStyle(GameTheme.muted)
            }

            ForEach(network.discoveredHosts) { host in
                GameActionButton(
                    title: host.name,
                    subtitle: "Enter this gathering",
                    icon: "door.left.hand.open",
                    isPrimary: false
                ) {
                    Task {
                        await network.join(host: host)
                    }
                }
                .disabled(network.isJoining)
            }

            Button("Search again") {
                game.state = GameState()
                network.startBrowsing()
            }
            .font(.subheadline)
            .foregroundStyle(GameTheme.accentLight)
            .disabled(network.isJoining)
            .padding(.vertical, 10)
        }
    }
}