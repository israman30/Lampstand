import SwiftUI
import UIKit

enum LampstandAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var systemImage: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max"
        case .dark: "moon.stars"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum LampstandTheme {
    enum Palette {
        static let parchment = Color(
            uiColor: UIColor { traits in
                if traits.userInterfaceStyle == .dark {
                    return UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0)
                }
                return UIColor(red: 0.99, green: 0.97, blue: 0.93, alpha: 1.0)
            }
        )

        static let parchmentTint = Color(
            uiColor: UIColor { traits in
                if traits.userInterfaceStyle == .dark {
                    return UIColor(red: 0.10, green: 0.10, blue: 0.11, alpha: 1.0)
                }
                return UIColor(red: 0.98, green: 0.95, blue: 0.89, alpha: 1.0)
            }
        )

        static let surface = Color(
            uiColor: UIColor { traits in
                if traits.userInterfaceStyle == .dark {
                    return UIColor(red: 0.12, green: 0.12, blue: 0.13, alpha: 1.0)
                }
                return UIColor(red: 1.00, green: 0.99, blue: 0.97, alpha: 1.0)
            }
        )

        static let stroke = Color(
            uiColor: UIColor { traits in
                if traits.userInterfaceStyle == .dark {
                    return UIColor(white: 1.0, alpha: 0.08)
                }
                return UIColor(white: 0.0, alpha: 0.06)
            }
        )

        static let ink = Color(
            uiColor: UIColor { traits in
                if traits.userInterfaceStyle == .dark {
                    return UIColor(white: 0.92, alpha: 1.0)
                }
                return UIColor(white: 0.12, alpha: 1.0)
            }
        )

        static let inkSecondary = Color(
            uiColor: UIColor { traits in
                if traits.userInterfaceStyle == .dark {
                    return UIColor(white: 0.76, alpha: 1.0)
                }
                return UIColor(white: 0.30, alpha: 1.0)
            }
        )

        static let accent = Color(
            uiColor: UIColor { traits in
                if traits.userInterfaceStyle == .dark {
                    return UIColor(red: 0.95, green: 0.74, blue: 0.34, alpha: 1.0)
                }
                return UIColor(red: 0.74, green: 0.46, blue: 0.14, alpha: 1.0)
            }
        )

        static let highlight = Color(
            uiColor: UIColor { traits in
                if traits.userInterfaceStyle == .dark {
                    return UIColor(red: 0.95, green: 0.74, blue: 0.34, alpha: 0.18)
                }
                return UIColor(red: 0.96, green: 0.82, blue: 0.38, alpha: 0.22)
            }
        )
    }

    enum Typography {
        static let title: Font = .system(.title3, design: .serif).weight(.semibold)
        static let headline: Font = .system(.headline, design: .serif).weight(.semibold)
        static let body: Font = .system(.body, design: .serif)
        static let bodyEmphasis: Font = .system(.body, design: .serif).weight(.semibold)
        static let caption: Font = .system(.caption, design: .serif)
        static let verseNumber: Font = .system(.footnote, design: .rounded).weight(.semibold)
    }
}

struct LampstandScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: [LampstandTheme.Palette.parchment, LampstandTheme.Palette.parchmentTint],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
    }
}

extension View {
    func lampstandScreenBackground() -> some View {
        modifier(LampstandScreenBackground())
    }

    func lampstandCard(isHighlighted: Bool = false) -> some View {
        self
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isHighlighted ? LampstandTheme.Palette.highlight : LampstandTheme.Palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(LampstandTheme.Palette.stroke, lineWidth: 1)
            )
    }
}

