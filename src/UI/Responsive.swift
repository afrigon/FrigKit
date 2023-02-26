import SwiftUI

public struct ResponsiveValue {
    public var compact: CGFloat
    public var regular: CGFloat

    public init(compact: CGFloat, regular: CGFloat) {
        self.compact = compact
        self.regular = regular
    }

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
