import SwiftUI

extension View {
    @ViewBuilder
    public func redacted(if condition: @autoclosure () -> Bool) -> some View {
        redacted(reason: condition() ? .placeholder : [])
    }
}
