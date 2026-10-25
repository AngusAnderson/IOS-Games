import SwiftUI

struct HomeView: View {
    @Environment(ImposterGameEngine.self) private var game
    @Environment(NearbyGameNetwork.self) private var network

    @State private var playerName = ""
    @State private var showingHostLobby = false
    @State private var showingJoinLobby = false

    private var trimmedName: String {
        playerName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Your name") {
                    TextField("Enter your name", text: $playerName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }

                Section {
                    Button("Host a game") {
                        preparePlayer()
                        showingHostLobby = true
                    }
                    .disabled(trimmedName.isEmpty)

                    Button("Join a game") {

                        preparePlayer()
                        showingJoinLobby = true
                    }
                    .disabled(trimmedName.isEmpty)
                }

                if let error = network.connectionError {
                    Section("Connection error") {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Imposter")
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
    }

    private func preparePlayer() {
        game.myName = trimmedName
        network.localName = trimmedName
        network.connectionError = nil
    }
}
