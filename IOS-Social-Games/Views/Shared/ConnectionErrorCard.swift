import SwiftUI

struct ConnectionErrorCard: View {
    let message: String

    var body: some View {
        GamePanel {
            Label {
                Text(message)
                    .font(.subheadline)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            } icon: {
                Image(systemName: "exclamationmark.circle")
            }
            .foregroundStyle(GameTheme.accentLight)
        }
    }
}