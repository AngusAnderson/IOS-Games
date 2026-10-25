import SwiftUI

@main
struct ImposterGameApp: App {
    @State private var game = ImposterGameEngine()
    @State private var network = NearbyGameNetwork()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(game)
                .environment(network)
        }
    }
}
