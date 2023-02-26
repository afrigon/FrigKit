import UIKit
import SwiftUI

public struct SnapshotConfig {
    let layout: Layout
    let direction: Direction
    let appearance: Appearance
    let contrast: Contrast
    let size: Size

    public init(
        layout: Layout,
        direction: Direction = .leftToRight,
        appearance: Appearance = .light,
        contrast: Contrast = .normal,
        size: Size = .regular
    ) {
        self.layout = layout
        self.direction = direction
        self.appearance = appearance
        self.contrast = contrast
        self.size = size
    }

    public static var phone: SnapshotConfig {
        SnapshotConfig(layout: .device(.phone(orientation: .portrait)))
    }

    public static var phoneLandscape: SnapshotConfig {
        SnapshotConfig(layout: .device(.phone(orientation: .landscape)))
    }

    public static var tablet: SnapshotConfig {
        SnapshotConfig(layout: .device(.tablet(orientation: .portrait)))
    }

    public static var tabletLandscape: SnapshotConfig {
        SnapshotConfig(layout: .device(.tablet(orientation: .landscape)))
    }

    public static var tv: SnapshotConfig {
        SnapshotConfig(layout: .device(.tv))
    }

    public static func fixed(width: CGFloat, height: CGFloat) -> SnapshotConfig {
        SnapshotConfig(layout: .fixed(width: width, height: height))
    }

    public static var fit: SnapshotConfig {
        SnapshotConfig(layout: .fit)
    }

    public var rtl: SnapshotConfig {
        SnapshotConfig(layout: layout, direction: .rightToLeft)
    }

    public var dark: SnapshotConfig {
        SnapshotConfig(layout: layout, appearance: .dark)
    }

    public var highContrast: SnapshotConfig {
        SnapshotConfig(layout: layout, contrast: .high)
    }

    public var smallText: SnapshotConfig {
        SnapshotConfig(layout: layout, size: .small)
    }

    public var largeText: SnapshotConfig {
        SnapshotConfig(layout: layout, size: .large)
    }

    var snapshotLayout: SwiftUISnapshotLayout {
        switch self.layout {
            case .device(let device):
                return .device(config: .init(
                    safeArea: device.safeArea,
                    size: device.size,
                    traits: traits
                ))
            case .fixed(let width, let height):
                return .fixed(width: width, height: height)
            case .fit:
                return .sizeThatFits
        }
    }

    var traits: UITraitCollection {
        var traits: UITraitCollection = .init()

        if case let .device(device) = layout {
            traits = .init(traitsFrom: [
                .init(displayGamut: device.gamut),
                .init(displayScale: device.scale),
                .init(userInterfaceIdiom: device.idiom),
                .init(horizontalSizeClass: device.sizeClass)
            ])
        }

        return .init(traitsFrom: [
            traits,
            .init(layoutDirection: direction.asLayoutDirection),
            .init(activeAppearance: .active),
            .init(forceTouchCapability: .unavailable),
            .init(legibilityWeight: .regular),
            .init(accessibilityContrast: contrast.asAccessibilityContrast),
            .init(userInterfaceStyle: appearance.asInterfaceStyle),
            .init(verticalSizeClass: .regular),
            .init(preferredContentSizeCategory: size.asContentSizeCategory)
        ])
    }
}

extension SnapshotConfig {
    public enum Layout {
        case device(Device)
        case fixed(width: CGFloat, height: CGFloat)
        case fit
    }

    public enum Device {
        /// iPhone 14 Pro
        case phone(orientation: Orientation = .portrait)
        /// iPad 10th generation
        case tablet(orientation: Orientation = .portrait)
        /// apple TV 4k
        case tv

        public var safeArea: UIEdgeInsets {
            switch self {
                case .phone(let orientation):
                    switch orientation {
                        case .portrait:
                            return .init(top: 59, left: 0, bottom: 34, right: 0)
                        case .landscape:
                            return .init(top: 0, left: 59, bottom: 21, right: 59)
                    }
                case .tablet:
                    return .init(top: 24, left: 0, bottom: 20, right: 0)
                case .tv:
                    return .init(top: 60, left: 80, bottom: 60, right: 80)
            }
        }

        public var size: CGSize {
            switch self {
                case .phone(let orientation):
                    switch orientation {
                        case .portrait:
                            return .init(width: 393, height: 852)
                        case .landscape:
                            return .init(width: 852, height: 393)
                    }
                case .tablet(let orientation):
                    switch orientation {
                        case .portrait:
                            return .init(width: 820, height: 1180)
                        case .landscape:
                            return .init(width: 1180, height: 820)
                    }
                case .tv:
                    return .init(width: 1920, height: 1080)
            }
        }

        public var orientation: Orientation? {
            switch self {
                case .phone(let orientation), .tablet(let orientation):
                    return orientation
                default:
                    return nil
            }
        }

        public var gamut: UIDisplayGamut {
            switch self {
                case .phone:
                    return .P3
                case .tablet, .tv:
                    return .SRGB
            }
        }

        public var scale: CGFloat {
            switch self {
                case .tv:
                    return 1.0
                case .tablet:
                    return 2.0
                case .phone:
                    return 3.0
            }
        }

        public var idiom: UIUserInterfaceIdiom {
            switch self {
                case .phone:
                    return .phone
                case .tablet:
                    return .pad
                case .tv:
                    return .tv
            }
        }

        public var sizeClass: UIUserInterfaceSizeClass {
            switch self {
                case .phone:
                    return .compact
                default:
                    return .regular
            }
        }
    }

    public enum Orientation {
        case portrait
        case landscape
    }

    public enum Direction {
        case leftToRight
        case rightToLeft

        var asLayoutDirection: UITraitEnvironmentLayoutDirection {
            switch self {
                case .leftToRight:
                    return .leftToRight
                case .rightToLeft:
                    return .rightToLeft
            }
        }
    }

    public enum Appearance {
        case light
        case dark

        var asInterfaceStyle: UIUserInterfaceStyle {
            switch self {
                case .light:
                    return .light
                case .dark:
                    return .dark
            }
        }
    }

    public enum Contrast {
        case normal
        case high

        var asAccessibilityContrast: UIAccessibilityContrast {
            switch self {
                case .normal:
                    return .normal
                case .high:
                    return .high
            }
        }
    }

    public enum Size {
        case regular
        case small
        case large

        var asContentSizeCategory: UIContentSizeCategory {
            switch self {
                case .regular:
                    return .large
                case .small:
                    return .small
                case .large:
                    return .extraExtraExtraLarge
            }
        }
    }
}

extension SnapshotConfig: CustomStringConvertible {
    public var description: String {
        var components: [String] = []

        switch layout {
            case .device(let device):
                switch device {
                    case .phone(let orientation):
                        components.append("phone")

                        if orientation == .landscape {
                            components.append("landscape")
                        }
                    case .tablet(let orientation):
                        components.append("tablet")

                        if orientation == .landscape {
                            components.append("landscape")
                        }

                    case .tv:
                        components.append("tv")

                }
            case .fixed(let width, let height):
                components.append("\(Int(width))x\(Int(height))")
            case .fit:
                components.append("fit")
        }

        if direction == .rightToLeft {
            components.append("rtl")
        }

        if appearance == .dark {
            components.append("dark")
        }

        if contrast == .high {
            components.append("high-contrast")
        }

        if size == .small {
            components.append("small-font")
        }

        if size == .large {
            components.append("large-font")
        }

        return components.joined(separator: "-")
    }
}
