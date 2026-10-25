import SwiftUI

struct SectionHeading: View {
    let title: String
    var detail: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .tracking(2)

            Spacer()

            if let detail {
                Text(detail)
            }
        }
        .font(.caption2.monospaced().weight(.medium))
        .foregroundStyle(GameTheme.muted)
    }
}