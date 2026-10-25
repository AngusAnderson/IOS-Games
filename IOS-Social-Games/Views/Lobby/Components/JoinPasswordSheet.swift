import SwiftUI

struct JoinPasswordSheet: View {
    @Environment(\.dismiss) private var dismiss

    let hostName: String
    let onJoin: (String) -> Void

    @State private var password = ""

    private var canJoin: Bool {
        RoomSecurity.isValidPassword(password)
    }

    var body: some View {
        NavigationStack {
            GameScreen {
                SectionHeading(title: "Private gathering")

                Text("Enter the secret.")
                    .font(.system(.largeTitle, design: .serif))
                    .foregroundStyle(GameTheme.ivory)

                Text("A password is required to join \(hostName).")
                    .font(.subheadline)
                    .foregroundStyle(GameTheme.muted)

                GamePanel {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeading(title: "Room password")

                        SecureField(
                            "Enter the room password",
                            text: $password
                        )
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.body.monospaced())
                        .foregroundStyle(GameTheme.ivory)

                        Text("Passwords are case-sensitive.")
                            .font(.caption)
                            .foregroundStyle(GameTheme.muted)
                    }
                }

                GameActionButton(
                    title: "Enter the room",
                    subtitle: "Connect to the protected gathering",
                    icon: "lock.open",
                    isPrimary: true
                ) {
                    let submittedPassword = password

                    dismiss()
                    onJoin(submittedPassword)
                }
                .disabled(!canJoin)
                .opacity(canJoin ? 1 : 0.45)
            }
            .navigationTitle("Private room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .tint(GameTheme.accentLight)
    }
}