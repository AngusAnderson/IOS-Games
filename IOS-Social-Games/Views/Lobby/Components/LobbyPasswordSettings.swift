import SwiftUI

struct LobbyPasswordSettings: View {
    @Environment(NearbyGameNetwork.self) private var network

    @State private var password = ""
    @State private var isVisible = false
    @State private var localError: String?

    private var canOpen: Bool {
        RoomSecurity.isValidPassword(password) &&
        !network.isPreparingHost
    }

    var body: some View {
        GamePanel {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeading(title: "Protect the gathering")

                Text("Set the room password.")
                    .font(.system(.title2, design: .serif))
                    .foregroundStyle(GameTheme.ivory)

                Text(
                    "Share it directly with your friends. "
                    + "The room opens once you confirm."
                )
                .font(.subheadline)
                .foregroundStyle(GameTheme.muted)

                HStack {
                    Group {
                        if isVisible {
                            TextField(
                                "Room password",
                                text: $password
                            )
                        } else {
                            SecureField(
                                "Room password",
                                text: $password
                            )
                        }
                    }
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.body.monospaced())
                    .foregroundStyle(GameTheme.ivory)
                    .disabled(network.isPreparingHost)

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
                            ? "Hide password"
                            : "Show password"
                    )
                }

                Divider()

                Button("Generate a random password") {
                    generatePassword()
                }
                .font(.subheadline)
                .foregroundStyle(GameTheme.accentLight)
                .disabled(network.isPreparingHost)

                Text(
                    "4-128 characters. "
                    + "The generated password is recommended."
                )
                .font(.caption)
                .foregroundStyle(GameTheme.muted)

                GameActionButton(
                    title: network.isPreparingHost
                        ? "Preparing…"
                        : "Open protected room",
                    subtitle: "Players will need this password",
                    icon: "lock",
                    isPrimary: true
                ) {
                    let submittedPassword = password

                    Task {
                        await network.startHosting(
                            password: submittedPassword
                        )
                    }
                }
                .disabled(!canOpen)
                .opacity(canOpen ? 1 : 0.45)

                if let localError {
                    Text(localError)
                        .font(.caption)
                        .foregroundStyle(GameTheme.accentLight)
                }
            }
        }
        .onAppear {
            if password.isEmpty {
                generatePassword()
            }
        }
    }

    private func generatePassword() {
        do {
            password = try RoomSecurity.generatePassword()
            localError = nil
        } catch {
            localError = error.localizedDescription
        }
    }
}