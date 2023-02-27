import SwiftUI

extension Text {
    public static func optional(_ text: String?, size: Int) -> Text {
        text.map(Text.init) ?? Text(String(repeating: " ", count: size))
    }
}
