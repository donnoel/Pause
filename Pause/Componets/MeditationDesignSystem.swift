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
            Color(red: 0xF8/255.0, green: 0xFB/255.0, blue: 0xFF/255.0), // #F8FBFF
            Color(red: 0xF2/255.0, green: 0xF5/255.0, blue: 0xFF/255.0), // #F2F5FF
            Color(red: 0xEC/255.0, green: 0xE9/255.0, blue: 0xFF/255.0)  // #ECE9FF
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
                    Color(red: 0x06/255.0, green: 0x0A/255.0, blue: 0x12/255.0),
                    Color(red: 0x10/255.0, green: 0x14/255.0, blue: 0x24/255.0),
                    Color(red: 0x14/255.0, green: 0x18/255.0, blue: 0x30/255.0)
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
    static let backgroundSecondary: Color = Color.white.opacity(0.22)

    static func surfacePrimary(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(0.10)
        default:
            return Color.white.opacity(0.30)
        }
    }

    static func surfaceStroke(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(0.14)
        default:
            return Color.white.opacity(0.45)
        }
    }

    static func orbOuterGradient(for colorScheme: ColorScheme) -> RadialGradient {
        switch colorScheme {
        case .dark:
            return RadialGradient(
                colors: [
                    Color(red: 0x2B/255.0, green: 0x35/255.0, blue: 0x54/255.0),
                    Color(red: 0x16/255.0, green: 0x1D/255.0, blue: 0x34/255.0)
                ],
                center: .center,
                startRadius: 0,
                endRadius: 180
            )
        default:
            return RadialGradient(
                colors: [
                    Color(red: 0xFA/255.0, green: 0xFD/255.0, blue: 0xFF/255.0),
                    Color(red: 0xE8/255.0, green: 0xF0/255.0, blue: 0xFF/255.0)
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
                    accentPrimary.opacity(0.36),
                    accentPrimary.opacity(0.16)
                ],
                center: .center,
                startRadius: 0,
                endRadius: 120
            )
        default:
            return RadialGradient(
                colors: [
                    accentPrimary.opacity(0.34),
                    accentPrimary.opacity(0.12)
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
            return Color.white.opacity(0.20)
        default:
            return Color.white.opacity(0.60)
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
    static var textPrimary: Color { Color.primary.opacity(0.9) }
    static var textSecondary: Color { Color.secondary.opacity(0.85) }
}

/// Primary large button used for the main Call To Action (Start / Pause / Resume).
/// This is a calm, slightly elevated capsule with a gentle press animation.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(
                Capsule(style: .continuous)
                    .fill(MeditationColors.accentPrimary)
                    .shadow(
                        color: MeditationColors.accentPrimary.opacity(configuration.isPressed ? 0.15 : 0.30),
                        radius: configuration.isPressed ? 8 : 16,
                        x: 0,
                        y: configuration.isPressed ? 4 : 10
                    )
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
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(minWidth: 44, minHeight: 44) // tap target
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? MeditationColors.accentSoft : MeditationColors.backgroundSecondary)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(
                            isSelected
                            ? MeditationColors.accentPrimary.opacity(0.75)
                            : Color.white.opacity(0.22),
                            lineWidth: isSelected ? 1.5 : 1
                        )
                )
                .foregroundColor(isSelected ? MeditationColors.accentPrimary : MeditationColors.textPrimary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
    }
}
