import SwiftUI

struct HomeView: View {
    @Environment(ImposterGameEngine.self) private var game
    @Environment(NearbyGameNetwork.self) private var network
    
    @State private var playerName = UIDevice.current.name
    
    var body: some view {
        NavigationStack {
            Form {
                Section("Your name") {
                    TextField("Name", text:$playerName)
                }
                
                section {
                    NavigationLink("Host a game") {
                        LobbyView(isHost: true)
                    }
                    .disabled(playerName.isEmpty)
                    
                    NavigationLink("Joing a game") {
                        LobbyView(isHost: false)
                    }
                    .disabled(playerName.isEmpty)
                }
                
                if let error = network.connectionError {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Imposter")
            .onAppear {
                game.myName = playerName
            }
        }
    }
}
