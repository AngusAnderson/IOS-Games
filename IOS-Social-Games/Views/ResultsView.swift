import SwiftUI

struct ResultsView: View {
    @Environment(ImposterGameEngine.self) private var game
    @Environment(NearbyGameNetwork.self) private var network
    
    var body: some View {
        VStack(spacing: 24) {
            if let imposter = game.state.imposter {
                Text("The imposter was")
                    .font(.headline)
                
                Text(imposter.name)
                    .font(.largeTitle.bold())
            }
            
            if let winner = game.state.winner {
                Text("\(winner) win!")
                    .font(.title.bold())
                    .foregroundStyle(winner == "Imposter" ? .red : .green)
            }
            
            List {
                ForEach(game.state.players) { player in
                    HStack {
                        Text(player.name)
                        Spacer()
                        Text("\(votes(for: player.id)) votes")
                    }
                }
            }
            .frame(maxWidth: 260)
            
            if game.isHost {
                Button("Play again") {
                    game.resetGame(network: network)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
    
    private func votes(for playerID: UUID) -> Int {
        game.state.votes.values.filter { $0 == playerID }.count
    }
}
