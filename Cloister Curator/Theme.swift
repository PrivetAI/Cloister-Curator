import SwiftUI

// MARK: - Palette
// Theme-independent palette. All colors are RGB-defined; the app forces light mode at root.
enum CloisterPalette {
    static let parchment   = Color(red: 0.965, green: 0.922, blue: 0.816) // #F6EBD0
    static let parchmentDeep = Color(red: 0.913, green: 0.860, blue: 0.740)
    static let stone       = Color(red: 0.616, green: 0.628, blue: 0.545) // #9DA08B
    static let stoneLight  = Color(red: 0.760, green: 0.770, blue: 0.700)
    static let stoneDark   = Color(red: 0.460, green: 0.470, blue: 0.405)
    static let moss        = Color(red: 0.368, green: 0.455, blue: 0.267) // #5E7444
    static let mossLight   = Color(red: 0.510, green: 0.600, blue: 0.380)
    static let mossDark    = Color(red: 0.250, green: 0.330, blue: 0.180)
    static let ink         = Color(red: 0.290, green: 0.220, blue: 0.146) // #4A3825
    static let inkSoft     = Color(red: 0.380, green: 0.290, blue: 0.205)
    static let gilded      = Color(red: 0.788, green: 0.640, blue: 0.250) // #C9A340
    static let gildedLight = Color(red: 0.890, green: 0.785, blue: 0.420)
    static let reliquary   = Color(red: 0.557, green: 0.216, blue: 0.216) // #8E3737
    static let reliquaryLight = Color(red: 0.700, green: 0.330, blue: 0.330)

    // Functional roles
    static let background     = parchment
    static let surface        = parchmentDeep
    static let surfaceRaised  = Color(red: 0.985, green: 0.955, blue: 0.870)
    static let textPrimary    = ink
    static let textSecondary  = inkSoft
    static let textMuted      = Color(red: 0.530, green: 0.440, blue: 0.330)
    static let accent         = moss
    static let highlight      = gilded
    static let danger         = reliquary
    static let divider        = Color(red: 0.760, green: 0.700, blue: 0.580)
}

// MARK: - Typography helper
enum CloisterFont {
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        return .system(size: size, weight: weight, design: .serif)
    }
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .system(size: size, weight: weight, design: .serif)
    }
    static func ui(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        return .system(size: size, weight: weight, design: .default)
    }
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Card style modifier
struct CloisterCardModifier: ViewModifier {
    var padding: CGFloat = 14
    var corner: CGFloat = 14
    var border: Bool = true
    var elevated: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(elevated ? CloisterPalette.surfaceRaised : CloisterPalette.surface)
            )
            .overlay(
                Group {
                    if border {
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .stroke(CloisterPalette.divider, lineWidth: 1)
                    }
                }
            )
    }
}

extension View {
    func cloisterCard(padding: CGFloat = 14, corner: CGFloat = 14, border: Bool = true, elevated: Bool = false) -> some View {
        modifier(CloisterCardModifier(padding: padding, corner: corner, border: border, elevated: elevated))
    }
}

// MARK: - Page background
struct CloisterPageBackground: View {
    var body: some View {
        ZStack {
            CloisterPalette.background.ignoresSafeArea()
            // Subtle parchment grain via overlapping radial gradients
            GeometryReader { proxy in
                let w = proxy.size.width
                let h = proxy.size.height
                ZStack {
                    RadialGradient(colors: [CloisterPalette.parchmentDeep.opacity(0.4), .clear],
                                   center: .topLeading, startRadius: 0, endRadius: max(w, h) * 0.7)
                    RadialGradient(colors: [CloisterPalette.gildedLight.opacity(0.10), .clear],
                                   center: .bottomTrailing, startRadius: 0, endRadius: max(w, h) * 0.6)
                }
                .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Section header
struct CloisterSectionHeader: View {
    let title: String
    let subtitle: String?
    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(CloisterFont.ui(11, weight: .heavy))
                .tracking(1.4)
                .foregroundColor(CloisterPalette.textMuted)
            if let s = subtitle {
                Text(s)
                    .font(CloisterFont.body(13))
                    .foregroundColor(CloisterPalette.textSecondary)
            }
        }
    }
}

// MARK: - Primary button style
struct CloisterPrimaryButton: ViewModifier {
    var enabled: Bool = true
    func body(content: Content) -> some View {
        content
            .font(CloisterFont.ui(15, weight: .bold))
            .foregroundColor(CloisterPalette.parchment)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(enabled ? CloisterPalette.moss : CloisterPalette.stone)
            )
    }
}
struct CloisterSecondaryButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(CloisterFont.ui(14, weight: .semibold))
            .foregroundColor(CloisterPalette.textPrimary)
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(CloisterPalette.surfaceRaised)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(CloisterPalette.divider, lineWidth: 1)
            )
    }
}
extension View {
    func cloisterPrimary(enabled: Bool = true) -> some View { modifier(CloisterPrimaryButton(enabled: enabled)) }
    func cloisterSecondary() -> some View { modifier(CloisterSecondaryButton()) }
}

// MARK: - Pill/badge
struct CloisterBadge: View {
    let text: String
    var color: Color = CloisterPalette.moss
    var body: some View {
        Text(text)
            .font(CloisterFont.ui(10, weight: .heavy))
            .tracking(0.8)
            .foregroundColor(.white)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Capsule().fill(color))
    }
}
