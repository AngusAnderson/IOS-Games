import SwiftUI

struct HostRoomPasswordCard: View {
    @Environment(NearbyGameNetwork.self) private var network

    @State private var isVisible = false

    var body: some View {
        GamePanel {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeading(title: "Room password")

                HStack {
                    Text(
                        isVisible
                            ? network.hostedRoomPassword ?? ""
                            : "••••••••••••••••"
                    )
                    .font(.body.monospaced())
                    .foregroundStyle(GameTheme.ivory)
                    .textSelection(.enabled)

                    Spacer()

                    Button {
                        isVisible.toggle()
                    } label: {
                        Image(
                            systemName: isVisible
                                ? "eye.slash"
                                : "eye"
                        )
                        .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(
                        isVisible
                            ? "Hide room password"
                            : "Reveal room password"
                    )
                }

                Text("Share this directly with the people in your room.")
                    .font(.caption)
                    .foregroundStyle(GameTheme.muted)
            }
        }
    }
}