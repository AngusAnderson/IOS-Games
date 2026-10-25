import SwiftUI

struct AliasCard: View {
    @Binding var name: String

    @FocusState private var isFocused: Bool

    private var isTooLong: Bool {
        name.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).count > 40
    }

    var body: some View {
        GamePanel {
            VStack(alignment: .leading, spacing: 15) {
                SectionHeading(title: "Your alias")

                TextField("Enter a name", text: $name)
                    .font(
                        .system(
                            .title3,
                            design: .serif
                        )
                    )
                    .foregroundStyle(GameTheme.ivory)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($isFocused)
                    .onSubmit {
                        isFocused = false
                    }
                    .accessibilityLabel("Player name")

                Rectangle()
                    .fill(
                        isFocused
                            ? GameTheme.accentLight
                            : GameTheme.ivory.opacity(0.12)
                    )
                    .frame(height: 1)

                Text(
                    isTooLong
                        ? "Use 40 characters or fewer."
                        : "The others will know you by this name."
                )
                .font(.caption)
                .foregroundStyle(
                    isTooLong
                        ? GameTheme.accentLight
                        : GameTheme.muted
                )
            }
        }
    }
}