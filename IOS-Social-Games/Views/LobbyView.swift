import SwiftUI

struct LobbyView: View {
    @Environment(ImposterGameEngine.self) private var game
    @Environment(NearbyGameNetwork.self) private var network
    
    let isHost: Bool
    
    var body: some View {
        List {
            Section("Players") {
                ForEach(game.state.players) { player in
                    HStack {
                        Text(player.name)
                        
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
                        Task {
                            await game.startGame(network: network)
                        }
                    }
                    .disabled(game.state.players.count < 3)
                } footer: {
                    Text("You need at least 3 players.")
                }
            } else {
                Section("Nearby games") {
                    if network.discoveredHosts.isEmpty {
                        Text("Searching for nearby games...")
                            .foregroundStyle(.secondary)
                    }
                    
                    ForEach(network.discoveredHosts) { host in
                        Button(host.name) {
                            Task {
                                await network.join(host: host)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Lobby")
        .onAppear {
            game.myName = network.localName
            
            if isHost {
                game.becomeHost(network: network)
                network.startHosting()
                
                network.onMessage = { message, senderID in
                    Task {
                        await game.handle(
                            message,
                            from: senderID,
                            network: network
                        )
                    }
                }
            }
        }
        .onDisappear {
            network.stopNetworking()
        }
    }
}
