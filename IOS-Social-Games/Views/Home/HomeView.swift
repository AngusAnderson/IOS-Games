import SwiftUI

struct HomeView: View {
    @Environment(ImposterGameEngine.self) private var game
    @Environment(NearbyGameNetwork.self) private var network

    @AppStorage("playerDisplayName")
    private var playerName = ""

    @State private var showingHostLobby = false
    @State private var showingJoinLobby = false

    private var trimmedName: String {
        playerName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var validName: Bool {
        !trimmedName.isEmpty && trimmedName.count <= 40
    }

    var body: some View {
        NavigationStack {
            GameScreen {
                HomeIdentity()

                AliasCard(name: $playerName)

                VStack(spacing: 12) {
                    GameActionButton(
                        title: "Create a gathering",
                        subtitle: "Host a new game",
                        icon: "plus",
                        isPrimary: true
                    ) {
                        preparePlayer()
                        showingHostLobby = true
                    }

                    GameActionButton(
                        title: "Enter the room",
                        subtitle: "Join a nearby game",
                        icon: "door.left.hand.open",
                        isPrimary: false
                    ) {
                        preparePlayer()
                        showingJoinLobby = true
                    }
                }
                .disabled(!validName)
                .opacity(validName ? 1 : 0.45)

                HomeRules()

                if let error = network.connectionError {
                    ConnectionErrorCard(message: error)
                }

                Text("Nearby players · 3+ players")
                    .font(.caption)
                    .foregroundStyle(GameTheme.muted)
                    .frame(maxWidth: .infinity)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(
                isPresented: $showingHostLobby
            ) {
                LobbyView(isHost: true)
            }
            .navigationDestination(
                isPresented: $showingJoinLobby
            ) {
                LobbyView(isHost: false)
            }
        }
        .tint(GameTheme.accentLight)
    }

    private func preparePlayer() {
        game.myName = trimmedName
        network.localName = trimmedName
        network.connectionError = nil
    }
}
