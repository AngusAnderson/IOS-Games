import SwiftUI

struct LobbyView: View {
    @Environment(ImposterGameEngine.self) private var game
    @Environment(NearbyGameNetwork.self) private var network

    @State private var didStart = false

    let isHost: Bool

    var body: some View {
        VStack(spacing: 0) {
            if game.state.phase == .lobby {
                LobbyContent(isHost: isHost)
            } else {
                GameView()
                    .id(game.state.round)
            }
        }
        .preferredColorScheme(.dark)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(
            GameTheme.background,
            for: .navigationBar
        )
        .toolbarBackground(
            .visible,
            for: .navigationBar
        )
        .tint(GameTheme.accentLight)
        .onAppear {
            startSessionIfNeeded()
        }
        .onDisappear {
            network.stopNetworking()

            network.onMessage = nil
            network.onAssignedID = nil
            network.onPlayerDisconnected = nil
            network.admissionRejection = nil

            didStart = false
        }
        .onChange(of: network.isConnected) { wasConnected, isConnected in
            guard !isHost,
                  wasConnected,
                  !isConnected
            else {
                return
            }

            game.state = GameState()
            game.myIsImposter = false
            game.myPrompt = nil
        }
    }

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

        network.onPlayerDisconnected = { playerID in
            game.playerDisconnected(
                playerID: playerID,
                network: network
            )
        }

        network.admissionRejection = { _ in
            guard game.isHost else {
                return "The host is not ready."
            }

            guard game.state.phase == .lobby else {
                return "This gathering already has a round in progress."
            }

            return nil
        }

        if isHost {
            game.becomeHost(network: network)
        } else {
            game.state = GameState()
            network.startBrowsing()
        }
    }
}
