import SwiftUI

struct GameScreen<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            PartyBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    content
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 36)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .preferredColorScheme(.dark)
        .foregroundStyle(GameTheme.ivory)
        .tint(GameTheme.accentLight)
    }
}