import SwiftUI

public struct ResponsiveValue {
    var compact: CGFloat
    var regular: CGFloat

    public func value(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        guard let sizeClass else {
            return regular
        }

        switch sizeClass {
            case .regular:
                return regular
            case .compact:
                return compact
            @unknown default:
                return regular
        }
    }
}
