import Foundation

postfix operator %

public struct Percent: Sendable, Hashable {
    public let value: Double

    public init(value: Double) {
        self.value = value
    }
}

extension Percent: Comparable {
    public static func < (lhs: Percent, rhs: Percent) -> Bool {
        lhs.value < rhs.value
    }
}

extension Percent: AdditiveArithmetic {
    public static let zero: Percent = .init(value: 0.0)

    public static func + (lhs: Percent, rhs: Percent) -> Percent {
        .init(value: lhs.value + rhs.value)
    }

    public static func - (lhs: Percent, rhs: Percent) -> Percent {
        .init(value: lhs.value - rhs.value)
    }

    public static prefix func - (percent: Percent) -> Percent {
        .init(value: -percent.value)
    }

    public static func * (lhs: Percent, rhs: Percent) -> Percent {
        .init(value: lhs.value * rhs.value)
    }
}

extension Percent: CustomStringConvertible {
    public var description: String {
        value.formatted(
            .percent
                .precision(.fractionLength(0...2))
                .locale(.current)
        )
    }
}

extension Percent: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

extension Percent: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try container.decode(Double.self)
    }
}

public extension Double {
    static postfix func % (value: Self) -> Percent {
        .init(value: value / 100.0)
    }
}

public extension BinaryInteger {
    static postfix func % (value: Self) -> Percent {
        .init(value: Double(value) / 100.0)
    }
}
