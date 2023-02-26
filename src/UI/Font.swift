import SwiftUI

extension Font.Weight: CustomStringConvertible {
    public var description: String {
        switch self {
            case .thin:
                return "Thin"
            case .ultraLight:
                return "ExtraLight"
            case .light:
                return "Light"
            case .regular:
                return "Regular"
            case .medium:
                return "Medium"
            case .semibold:
                return "SemiBold"
            case .bold:
                return "Bold"
            case .heavy:
                return "ExtraBold"
            case .black:
                return "Black"
            default:
                return "Regular"
        }
    }
}

extension Font {
    private static func custom(
        _ name: String,
        size: CGFloat,
        weight: Weight = .regular,
        italic: Bool = false
    ) -> Font {
        let weightString = weight == .regular && italic ? "" : weight.description
        let italicString = italic ? "Italic" : ""

        return .custom("\(name)-\(weightString)\(italicString)", size: size)
    }
}
