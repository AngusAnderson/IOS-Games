import SwiftUI

struct HomeRules: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeading(title: "The rules")

            rule(
                "I",
                title: "Receive your secret",
                detail: "One player is left in the dark."
            )

            rule(
                "II",
                title: "Speak carefully",
                detail: "Give a clue without giving too much away."
            )

            rule(
                "III",
                title: "Make your accusation",
                detail: "Find the imposter before they fool the room."
            )
        }
    }

    private func rule(
        _ number: String,
        title: String,
        detail: String
    ) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(number)
                .font(.system(.subheadline, design: .serif))
                .foregroundStyle(GameTheme.accentLight)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(GameTheme.ivory)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(GameTheme.muted)
            }
        }
    }
}