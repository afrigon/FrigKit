import SwiftUI
import NukeUI

public struct RemoteImage<Placeholder: View>: View {
    let url: URL?
    let resizingMode: ImageResizingMode
    let placeholder: () -> Placeholder

    public var body: some View {
        if let url {
            LazyImage(url: url) { state in
                if let image = state.image {
                    image.resizingMode(resizingMode)
                } else {
                    placeholder()
                }
            }
        } else {
            placeholder()
        }
    }

    public init(
        _ url: URL?,
        resizingMode: ImageResizingMode = .aspectFill
    ) where Placeholder == Color {
        self.url = url
        self.resizingMode = resizingMode
        self.placeholder = { Color.clear }
    }

    public init(
        _ url: URL?,
        resizingMode: ImageResizingMode = .aspectFill,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.resizingMode = resizingMode
        self.placeholder = placeholder
    }
}
