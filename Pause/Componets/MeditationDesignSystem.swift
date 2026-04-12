import SwiftUI

/// Central color & component system for the Pause app.
/// Implements the "Air Quartz" visual style:
/// - Soft blue → lilac inspired background
/// - Accent pulled from the PauseAccent asset
/// - Simple, quiet components with good tap targets
enum MeditationColors {
    /// Air Quartz background – used as the main screen backdrop.
    /// This is a very soft blue-to-lilac vertical gradient.
    static let backgroundPrimary: LinearGradient = LinearGradient(
        colors: [
            Color(red: 0xF1/255.0, green: 0xF5/255.0, blue: 0xFB/255.0), // #F1F5FB
            Color(red: 0xE9/255.0, green: 0xEE/255.0, blue: 0xF7/255.0)  // #E9EEF7
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Dark-mode aware variant, so views can opt into a richer dark appearance.
    static func backgroundPrimary(for colorScheme: ColorScheme) -> LinearGradient {
        switch colorScheme {
        case .dark:
            return LinearGradient(
                colors: [
                    Color(red: 0x08/255.0, green: 0x0E/255.0, blue: 0x1A/255.0),
                    Color(red: 0x11/255.0, green: 0x18/255.0, blue: 0x29/255.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        default:
            return backgroundPrimary
        }
    }

    /// Soft surface color used for rings, pill backgrounds, etc.
    /// This is intentionally subtle so the timer ring and chips feel calm.
    static let backgroundSecondary: Color = Color.white.opacity(0.24)

    static func surfacePrimary(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(0.10)
        default:
            return Color.white.opacity(0.74)
        }
    }

    static func surfaceStroke(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(0.20)
        default:
            return Color.black.opacity(0.10)
        }
    }

    static func surfaceElevated(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(0.06)
        default:
            return Color.white.opacity(0.54)
        }
    }

    static func surfaceElevatedStroke(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(0.18)
        default:
            return Color.black.opacity(0.10)
        }
    }

    static func orbOuterGradient(for colorScheme: ColorScheme) -> RadialGradient {
        switch colorScheme {
        case .dark:
            return RadialGradient(
                colors: [
                    Color(red: 0x4D/255.0, green: 0x59/255.0, blue: 0x79/255.0),
                    Color(red: 0x1B/255.0, green: 0x25/255.0, blue: 0x3F/255.0)
                ],
                center: .center,
                startRadius: 0,
                endRadius: 180
            )
        default:
            return RadialGradient(
                colors: [
                    Color(red: 0xFF/255.0, green: 0xFF/255.0, blue: 0xFF/255.0),
                    Color(red: 0xC8/255.0, green: 0xD9/255.0, blue: 0xF7/255.0)
                ],
                center: .center,
                startRadius: 0,
                endRadius: 180
            )
        }
    }

    static func orbInnerGradient(for colorScheme: ColorScheme) -> RadialGradient {
        switch colorScheme {
        case .dark:
            return RadialGradient(
                colors: [
                    accentPrimary.opacity(0.34),
                    accentPrimary.opacity(0.10)
                ],
                center: .center,
                startRadius: 0,
                endRadius: 120
            )
        default:
            return RadialGradient(
                colors: [
                    accentPrimary.opacity(0.30),
                    accentPrimary.opacity(0.08)
                ],
                center: .center,
                startRadius: 0,
                endRadius: 120
            )
        }
    }

    static func ringTrack(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(0.26)
        default:
            return Color.black.opacity(0.12)
        }
    }

    /// Primary accent for interactive elements, tied to the PauseAccent color asset.
    /// If the asset is missing, this will gracefully fall back to system accent.
    static let accentPrimary: Color = Color("PauseAccent")

    /// Soft accent used for fills behind selected pills and buttons.
    /// Derived from `accentPrimary` so changes to the accent asset stay in sync.
    static let accentSoft: Color = accentPrimary.opacity(0.16)

    /// Text colors follow system dynamic colors so they remain legible
    /// in both light and dark appearances.
    static var textPrimary: Color { Color.primary.opacity(0.96) }
    static var textSecondary: Color { Color.secondary.opacity(0.82) }
}

/// Primary large button used for the main Call To Action (Start / Pause / Resume).
/// This is a calm, slightly elevated capsule with a gentle press animation.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .padding(.horizontal, 24)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(
                Capsule(style: .continuous)
                    .fill(MeditationColors.accentPrimary)
                    .shadow(
                        color: MeditationColors.accentPrimary.opacity(configuration.isPressed ? 0.08 : 0.16),
                        radius: configuration.isPressed ? 5 : 8,
                        x: 0,
                        y: configuration.isPressed ? 2 : 4
                    )
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(configuration.isPressed ? 0.14 : 0.24), lineWidth: 1)
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}

/// A soft pill used for duration selection chips.
/// Selected state uses a gentle accent fill and a subtle outline.
struct DurationPill: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            Text(title)
                .font(.body.weight(isSelected ? .semibold : .regular))
                .lineLimit(1)
                .minimumScaleFactor(0.92)
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .frame(minWidth: 44, minHeight: 44) // tap target
                .background(
                    Capsule(style: .continuous)
                        .fill(
                            isSelected
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [
                                        MeditationColors.accentPrimary.opacity(colorScheme == .dark ? 0.88 : 0.92),
                                        MeditationColors.accentPrimary.opacity(colorScheme == .dark ? 0.72 : 0.80)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            : AnyShapeStyle(MeditationColors.surfaceElevated(for: colorScheme))
                        )
                )
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(
                            isSelected
                            ? Color.white.opacity(colorScheme == .dark ? 0.16 : 0.30)
                            : MeditationColors.surfaceElevatedStroke(for: colorScheme),
                            lineWidth: 1
                        )
                )
                .foregroundColor(isSelected ? .white : MeditationColors.textPrimary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
    }
}
