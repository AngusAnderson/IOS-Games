import SwiftUI

struct LobbyContent: View {
    @Environment(ImposterGameEngine.self) private var game
    @Environment(NearbyGameNetwork.self) private var network

    let isHost: Bool
    @State private var playerToRemove: GamePlayer?
    @State private var showingRemovalConfirmation = false

    @State private var selectedHost: NearbyGameNetwork.HostInfo?

    private var status: String {
        if isHost {
            if network.isHosting {
                return "The room is open"
            }

            return network.isPreparingHost
                ? "Preparing the room…"
                : "Set the room's secret"
        }

        if network.isConnected {
            return "You're in the room"
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

            if isHost {
                if network.isHosting {
                    HostRoomPasswordCard()
                } else {
                    LobbyPasswordSettings()
                }
            }

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
                            LobbyPlayerRow(
                                player: player,
                                isYou: player.id == game.myID,
                                canRemove:
                                    game.isHost &&
                                    game.state.phase == .lobby &&
                                    !player.isHost &&
                                    player.id != game.myID
                            ) {
                                playerToRemove = player
                                showingRemovalConfirmation = true
                            }
                        }
                    }
                }
            }

            if isHost {
                
                if isHost || network.isConnected {
                    ClueModeSettingsCard()
                }
                
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
        .confirmationDialog(
            "Remove \(playerToRemove?.name ?? "player")?",
            isPresented: $showingRemovalConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                "Remove from gathering",
                role: .destructive
            ) {
                guard game.isHost,
                      game.state.phase == .lobby,
                      let player = playerToRemove,
                      !player.isHost,
                      player.id != game.myID
                else {
                    return
                }

                network.removePlayer(player.id)
                playerToRemove = nil
            }

            Button("Cancel", role: .cancel) {
                playerToRemove = nil
            }
        } message: {
            Text(
                "They will be disconnected. "
                + "This does not permanently prevent them from joining again."
            )
        }
        .sheet(item: $selectedHost) { host in
            JoinPasswordSheet(hostName: host.name) { password in
                Task {
                    await network.join(
                        host: host,
                        password: password
                    )
                }
            }
        }
    }
    

    private var connectionDescription: String {
        if isHost {
            return network.isHosting
                ? "Visible to nearby players"
                : "Starting host"
        }

        return network.isConnected
            ? "Connected to the host"
            : "Searching for nearby gatherings"
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
                    subtitle: "Password-protected gathering",
                    icon: "lock",
                    isPrimary: false
                ) {
                    selectedHost = host
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
