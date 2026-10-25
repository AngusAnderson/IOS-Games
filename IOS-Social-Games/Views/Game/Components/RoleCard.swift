import SwiftUI

struct RoleCard: View {
    let isImposter: Bool
    let prompt: String?
    @Binding var isRevealed: Bool

    var body: some View {
        GamePanel {
            VStack(spacing: 20) {
                SectionHeading(title: "For your eyes only")

                Image(
                    systemName: isRevealed
                        ? "eye"
                        : "eye.slash"
                )
                .font(.system(size: 36, weight: .ultraLight))
                .foregroundStyle(GameTheme.accentLight)
                .accessibilityHidden(true)

                if isRevealed {
                    Text(
                        isImposter
                            ? "You are the imposter."
                            : "You belong here."
                    )
                    .font(.system(.title2, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(GameTheme.ivory)

                    if isImposter {
                        Text(
                            "You have no prompt. "
                            + "Listen carefully and blend in."
                        )
                        .font(.subheadline)
                        .foregroundStyle(GameTheme.muted)
                        .multilineTextAlignment(.center)
                    } else {
                        Text(prompt ?? "Waiting for your prompt…")
                            .font(
                                .system(
                                    .title,
                                    design: .serif,
                                    weight: .medium
                                )
                            )
                            .foregroundStyle(GameTheme.accentLight)
                            .multilineTextAlignment(.center)

                        Text("Give a clue, not the answer.")
                            .font(.caption)
                            .foregroundStyle(GameTheme.muted)
                    }
                } else {
                    Text("Your secret is waiting.")
                        .font(.system(.title2, design: .serif))
                        .foregroundStyle(GameTheme.ivory)

                    Text("Make sure no one else can see your screen.")
                        .font(.caption)
                        .foregroundStyle(GameTheme.muted)
                        .multilineTextAlignment(.center)
                }

                Button {
                    isRevealed.toggle()
                } label: {
                    Label(
                        isRevealed ? "Hide role" : "Reveal role",
                        systemImage: isRevealed
                            ? "eye.slash"
                            : "eye"
                    )
                    .font(.subheadline.weight(.medium))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 18)
                    .background(
                        GameTheme.elevated,
                        in: Capsule()
                    )
                }
                .foregroundStyle(GameTheme.ivory)
            }
            .frame(maxWidth: .infinity)
        }
    }
}