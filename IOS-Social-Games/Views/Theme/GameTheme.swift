import SwiftUI

enum GameTheme {
    static let background = Color(
        red: 0.025,
        green: 0.025,
        blue: 0.032
    )

    static let surface = Color(
        red: 0.065,
        green: 0.060,
        blue: 0.072
    )

    static let elevated = Color(
        red: 0.105,
        green: 0.090,
        blue: 0.105
    )

    static let accent = Color(
        red: 0.48,
        green: 0.16,
        blue: 0.23
    )

    static let accentLight = Color(
        red: 0.77,
        green: 0.43,
        blue: 0.48
    )

    static let ivory = Color(
        red: 0.91,
        green: 0.88,
        blue: 0.84
    )

    static let muted = Color(
        red: 0.65,
        green: 0.62,
        blue: 0.65
    )

    // Compatibility with any screens using the previous theme.
    static let purple = accentLight
    static let lime = ivory
}

// MARK: - Background

struct PartyBackground: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                GameTheme.background

                Ellipse()
                    .fill(GameTheme.accent.opacity(0.16))
                    .frame(
                        width: geometry.size.width * 1.2,
                        height: 350
                    )
                    .blur(radius: 100)
                    .position(
                        x: geometry.size.width * 0.85,
                        y: geometry.size.height * 0.2
                    )

                Ellipse()
                    .fill(
                        Color(
                            red: 0.18,
                            green: 0.16,
                            blue: 0.24
                        )
                        .opacity(0.15)
                    )
                    .frame(width: 300, height: 400)
                    .blur(radius: 100)
                    .position(
                        x: geometry.size.width * 0.1,
                        y: geometry.size.height * 0.75
                    )

                LinearGradient(
                    colors: [
                        .black.opacity(0.1),
                        .clear,
                        .black.opacity(0.6)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

// MARK: - Panel

struct GamePanel<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                GameTheme.surface.opacity(0.95),
                in: RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .strokeBorder(
                    GameTheme.ivory.opacity(0.08),
                    lineWidth: 1
                )
            }
    }
}

// MARK: - Action button

struct GameActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let isPrimary: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(
                        isPrimary
                            ? GameTheme.ivory
                            : GameTheme.accentLight
                    )
                    .frame(width: 42, height: 42)
                    .background(
                        Color.black.opacity(0.16),
                        in: RoundedRectangle(cornerRadius: 12)
                    )

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(GameTheme.ivory)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(
                            isPrimary
                                ? GameTheme.ivory.opacity(0.8)
                                : GameTheme.muted
                        )
                }

                Spacer(minLength: 8)

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(
                        GameTheme.ivory.opacity(0.7)
                    )
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .fill(
                    LinearGradient(
                        colors: isPrimary
                            ? [
                                GameTheme.accent,
                                GameTheme.accent.opacity(0.7)
                            ]
                            : [
                                GameTheme.elevated,
                                GameTheme.surface
                            ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
            .overlay {
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .strokeBorder(
                    isPrimary
                        ? GameTheme.accentLight.opacity(0.3)
                        : GameTheme.ivory.opacity(0.09),
                    lineWidth: 1
                )
            }
            .contentShape(
                RoundedRectangle(cornerRadius: 18)
            )
        }
        .buttonStyle(GamePressStyle())
    }
}

struct GamePressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(
                configuration.isPressed && !reduceMotion
                    ? 0.985
                    : 1
            )
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(
                reduceMotion
                    ? nil
                    : .easeOut(duration: 0.18),
                value: configuration.isPressed
            )
    }
}
