import SwiftUI

struct RoleCard: View {
    let isImposter: Bool
    let prompt: String?
    let category: String?

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
                .font(
                    .system(
                        size: 36,
                        weight: .ultraLight
                    )
                )
                .foregroundStyle(GameTheme.accentLight)
                .accessibilityHidden(true)

                if isRevealed {
                    revealedContent
                } else {
                    concealedContent
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

    private var revealedContent: some View {
        VStack(spacing: 18) {
            Text(
                isImposter
                    ? "You are the imposter."
                    : "You belong here."
            )
            .font(.system(.title2, design: .serif))
            .foregroundStyle(GameTheme.ivory)
            .multilineTextAlignment(.center)

            if let category {
                categoryHint(category)
            }

            if isImposter {
                Text(
                    "You know the category, but not the exact prompt. "
                    + "Listen to the clues and blend in."
                )
                .font(.subheadline)
                .foregroundStyle(GameTheme.muted)
                .multilineTextAlignment(.center)
            } else {
                VStack(spacing: 10) {
                    Text("THE SECRET PROMPT")
                        .font(.caption2.monospaced())
                        .tracking(1.5)
                        .foregroundStyle(GameTheme.muted)

                    Text(prompt ?? "Waiting for your prompt…")
                        .font(
                            .system(
                                .title,
                                design: .serif,
                                weight: .medium
                            )
                        )
                        .foregroundStyle(GameTheme.ivory)
                        .multilineTextAlignment(.center)

                    Text("Give a clue, not the answer.")
                        .font(.caption)
                        .foregroundStyle(GameTheme.muted)
                }
            }
        }
    }

    private var concealedContent: some View {
        VStack(spacing: 12) {
            Text("Your secret is waiting.")
                .font(.system(.title2, design: .serif))
                .foregroundStyle(GameTheme.ivory)

            Text("Make sure no one else can see your screen.")
                .font(.caption)
                .foregroundStyle(GameTheme.muted)
                .multilineTextAlignment(.center)
        }
    }

    private func categoryHint(_ category: String) -> some View {
        VStack(spacing: 8) {
            Text(isImposter ? "YOUR HINT" : "CATEGORY")
                .font(.caption2.monospaced())
                .tracking(1.5)
                .foregroundStyle(GameTheme.muted)

            Label(
                category,
                systemImage: "square.grid.2x2"
            )
            .font(.subheadline.weight(.medium))
            .foregroundStyle(GameTheme.accentLight)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(
            GameTheme.elevated,
            in: RoundedRectangle(cornerRadius: 14)
        )
    }
}
