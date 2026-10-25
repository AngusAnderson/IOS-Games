import SwiftUI

struct HomeIdentity: View {
    var body: some View {
        VStack(spacing: 26) {
            HStack {
                Text("A GAME OF DECEPTION")
                    .tracking(2)

                Spacer()

                Image(systemName: "eye")
            }
            .font(.caption2.monospaced())
            .foregroundStyle(GameTheme.muted)

            ZStack {
                Circle()
                    .stroke(
                        GameTheme.ivory.opacity(0.06),
                        lineWidth: 1
                    )
                    .frame(width: 128, height: 128)

                Circle()
                    .stroke(
                        GameTheme.accentLight.opacity(0.18),
                        lineWidth: 1
                    )
                    .frame(width: 108, height: 108)

                RoundedRectangle(cornerRadius: 20)
                    .fill(GameTheme.elevated)
                    .frame(width: 72, height: 72)
                    .rotationEffect(.degrees(45))

                Image(systemName: "eye")
                    .font(.system(size: 30, weight: .ultraLight))
                    .foregroundStyle(GameTheme.ivory)
            }
            .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text("IMPOSTER")
                    .font(
                        .system(
                            .largeTitle,
                            design: .serif,
                            weight: .regular
                        )
                    )
                    .tracking(5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(GameTheme.ivory)

                Text("SOMEONE DOESN’T BELONG")
                    .font(.caption2.monospaced())
                    .tracking(1.5)
                    .foregroundStyle(GameTheme.accentLight)

                Text("Keep your secret.\nQuestion everyone else.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .foregroundStyle(GameTheme.muted)
            }
        }
        .frame(maxWidth: .infinity)
    }
}