import SwiftUI

extension Text {
    public static func optional(_ text: String?, size: Int) -> any View {
        text.map(Text.init) ?? Text(String(repeating: " ", count: size)).redacted(reason: .placeholder)
    }
}
