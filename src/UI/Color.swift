import SwiftUI

extension Color {
    public init(hex: String, opacity: Double = 1.0) {
        var int: UInt64 = 0

        guard Scanner(string: hex).scanHexInt64(&int) else {
            self = Color.white

            return
        }

        let r, g, b: UInt64

        var count = hex.count
        if hex.hasPrefix("0x") || hex.hasPrefix("0X") {
            count -= 2
        }

        switch count {
            case 3:
                r = (int >> 8 & 0xf) * 17
                g = (int >> 4 & 0xf) * 17
                b = (int & 0xf) * 17
            case 6:
                r = int >> 16 & 0xff
                g = int >> 8 & 0xff
                b = int & 0xff
            default:
                self = Color.white

                return
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: opacity
        )
    }
}

public struct ColorSet: View {
    @Environment(\.colorScheme) private var colorScheme

    /// the color used for the light color scheme
    let light: Color

    /// the color used for the dark color scheme
    let dark: Color

    public var body: some View {
        switch colorScheme {
            case .light:
                return light
            case .dark:
                return dark
            @unknown default:
                return light
        }
    }

    /// a color set
    public init(light: Color, dark: Color) {
        self.light = light
        self.dark = dark
    }

    /// a color set where both dark and light component uses the same color
    public init(_ color: Color) {
        self.light = color
        self.dark = color
    }

    /// a color set where the dark and light components are inversed
    var inverse: ColorSet {
        ColorSet(light: dark, dark: light)
    }

    /// returns the most contrasting component with the given color
    /// note: assumes dark and light are black and white
    func contrasting(with color: Color) -> Color {
        guard let components = color.cgColor?.components, components.count >= 3 else {
            return light
        }

        var r: CGFloat = components[0]
        var g: CGFloat = components[1]
        var b: CGFloat = components[2]

        // https://en.wikipedia.org/wiki/Luma_(video)
        let luma: CGFloat = 0.299 * r + 0.587 * g + 0.114 * b
        let threshold: CGFloat = 0.5

        return luma > threshold ? dark : light
    }
}

struct ForegroundColorSetModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    var light: Color
    var dark: Color

    func body(content: Content) -> some View {
        switch colorScheme {
            case .light:
                return content.foregroundColor(light)
            case .dark:
                return content.foregroundColor(dark)
            @unknown default:
                return content.foregroundColor(light)
        }
    }
}

extension View {
    func foregroundColor(_ color: ColorSet) -> some View {
        modifier(ForegroundColorSetModifier(
            light: color.light,
            dark: color.dark
        ))
    }
}
