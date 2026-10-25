import SwiftUI

struct LobbyView: View {
    @Environment(ImposterGameEngine.self) private var game
    @Environment(NearbyGameNetwork.self) private var network

    @State private var didStart = false

    let isHost: Bool

    var body: some View {
        VStack(spacing: 0) {
            if game.state.phase == .lobby {
                lobbyContent
            } else {
                GameView()
            }
        }
        .onAppear {
            startSessionIfNeeded()
        }
        .onDisappear {
            // This runs when leaving the session screen,
            // not when swapping lobbyContent for GameView.
            network.stopNetworking()
            network.onMessage = nil
            network.onAssignedID = nil

            didStart = false
        }
    }

    // MARK: - Lobby

    private var lobbyContent: some View {
        List {
            Section("Connection") {
                if isHost {
                    Label(
                        network.isHosting
                            ? "Hosting"
                            : "Starting host…",
                        systemImage: "wifi"
                    )
                } else if network.isConnected {
                    Label(
                        "Connected to host",
                        systemImage: "checkmark.circle.fill"
                    )
                    .foregroundStyle(.green)
                } else if network.isJoining {
                    HStack {
                        ProgressView()
                        Text("Joining…")
                    }
                } else {
                    Text("Choose a nearby game")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Players") {
                ForEach(game.state.players) { player in
                    HStack {
                        Text(player.name)

                        if player.id == game.myID {
                            Text("(You)")
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if player.isHost {
                            Text("Host")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if isHost {
                Section {
                    Button("Start Game") {
                        Task { @MainActor in
                            print(
                                "GAME: Start pressed.",
                                "isHost:", game.isHost,
                                "players:", game.state.players.count,
                                "phase:", game.state.phase.rawValue
                            )

                            await game.startGame(
                                network: network
                            )

                            print(
                                "GAME: Phase after start:",
                                game.state.phase.rawValue
                            )
                        }
                    }
                    .disabled(
                        !network.isHosting ||
                        game.state.players.count < 3
                    )
                } footer: {
                    Text("You need at least 3 players.")
                }
            } else if !network.isConnected {
                Section("Nearby games") {
                    if network.discoveredHosts.isEmpty {
                        Text("Searching for nearby games…")
                            .foregroundStyle(.secondary)
                    }

                    ForEach(network.discoveredHosts) { host in
                        Button {
                            Task {
                                await network.join(host: host)
                            }
                        } label: {
                            HStack {
                                Text(host.name)

                                Spacer()

                                Image(
                                    systemName: "arrow.right.circle"
                                )
                            }
                            .contentShape(Rectangle())
                        }
                        .disabled(network.isJoining)
                    }

                    if !network.isJoining {
                        Button("Search again") {
                            game.state = GameState()
                            network.startBrowsing()
                        }
                    }
                }
            }

            if let error = network.connectionError {
                Section("Connection error") {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Lobby")
    }

    // MARK: - Session lifecycle

    private func startSessionIfNeeded() {
        guard !didStart else {
            return
        }

        didStart = true

        network.onAssignedID = { playerID in
            game.myID = playerID
        }

        network.onMessage = { message, senderID in
            Task { @MainActor in
                await game.handle(
                    message,
                    from: senderID,
                    network: network
                )
            }
        }

        if isHost {
            game.becomeHost(network: network)
            network.startHosting()
        } else {
            game.state = GameState()
            network.startBrowsing()
        }
    }
}
