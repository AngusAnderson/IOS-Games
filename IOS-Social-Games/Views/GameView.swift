import SwiftUI

struct GameView: View {
    @Environment(ImposterGameEngine.self) private var game
    @Environment(NearbyGameNetwork.self) private var network
    
    @State private var clue = ""
    @State private var selectedVote: UUID?
    
    var body: some View {
        VStack(spacing: 24) {
            switch game.state.phase {
            case .lobby:
                Text("Waiting in the lobby...")
                
            case .prompting, .discussing:
                promptSection
                
            case .voting:
                votingSection
                
            case .revealing, .finished:
                ResultsView()
            }
        }
        .padding()
        .navigationTitle("Round \(game.state.round)")
    }
    
    private var promptSection: some View {
        VStack(spacing: 20) {
            if game.myIsImposter {
                Label("You are the imposter", systemImage: "spy")
                    .font(.title2.bold())
                    .foregroundStyle(.red)
                
                Text("Blend in. Do not reveal the prompt.")
                    .foregroundStyle(.secondary)
            } else {
                Label("You are innocent", systemImage: "person.3")
                    .font(.title2.bold())
                
                if let prompt = game.myPrompt {
                    Text(prompt)
                        .font(.largeTitle.bold())
                }
            }
            
            TextField("Give a subtle clue", text: $clue)
                .textFieldStyle(.roundedBorder)
            
            Button("Submit clue") {
                let submittedClue = clue.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

                guard !submittedClue.isEmpty else {
                    return
                }

                Task { @MainActor in
                    if game.isHost {
                        game.submitClue(
                            playerID: game.myID,
                            clue: submittedClue,
                            network: network
                        )
                    } else {
                        await network.sendToHost(
                            .submitClue(submittedClue)
                        )
                    }

                    clue = ""
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(
                clue.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).isEmpty ||
                game.me?.hasSubmittedClue == true
            )
            .buttonStyle(.borderedProminent)
            .disabled(clue.isEmpty || game.me?.hasSubmittedClue == true)
            
            List(game.state.players) { player in
                HStack {
                    Text(player.name)
                    Spacer()
                    
                    if player.hasSubmittedClue {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
        }
    }
    
    private var votingSection: some View {
        VStack(spacing: 16) {
            Text("Who is the imposter?")
                .font(.title.bold())
            
            List(game.state.players.filter { $0.id != game.myID }) { player in
                Button {
                    selectedVote = player.id

                    Task { @MainActor in
                        if game.isHost {
                            game.submitVote(
                                voterID: game.myID,
                                accusedID: player.id,
                                network: network
                            )
                        } else {
                            await network.sendToHost(
                                .submitVote(accusedID: player.id)
                            )
                        }
                    }
                } label: {
                    HStack {
                        Text(player.name)

                        Spacer()

                        if selectedVote == player.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .disabled(game.me?.hasVoted == true)
            }
        }
    }
}
