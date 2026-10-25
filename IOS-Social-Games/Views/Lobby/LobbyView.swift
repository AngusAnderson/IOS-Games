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
            didStart = false
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

        if isHost {
            game.becomeHost(network: network)
            network.startHosting()
        } else {
            game.state = GameState()
            network.startBrowsing()
        }
    }
}