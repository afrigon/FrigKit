import Foundation

extension IntegerFormatStyle {
    public var binary: RadixFormatStyle<Value> {
        RadixFormatStyle(radix: 2)
    }

    public var octal: RadixFormatStyle<Value> {
        RadixFormatStyle(radix: 8)
    }

    public var hexadecimal: RadixFormatStyle<Value> {
        RadixFormatStyle(radix: 16)
    }
}

public struct RadixFormatStyle<Value>: FormatStyle where Value: BinaryInteger {
    public typealias FormatInput = Value
    public typealias FormatOutput = String

    private let radix: Int
    private let prefix: String?
    private let uppercase: Bool
    private let padding: Int?

    public init(
        radix: Int,
        prefix: String? = nil,
        uppercase: Bool = false,
        padding: Int? = nil
    ) {
        guard (2...36).contains(radix) else {
            fatalError("Radix must be between 2 and 36")
        }

        self.radix = radix
        self.prefix = prefix
        self.uppercase = uppercase
        self.padding = padding
    }

    public func format(_ value: Value) -> String {
        var value = String(
            value,
            radix: radix,
            uppercase: uppercase
        )

        if let padding {
            value = String(repeating: "0", count: max(0, padding - value.count)) + value
        }

        if let prefix {
            return prefix + value
        }

        return value
    }

    public var uppercased: Self {
        RadixFormatStyle(
            radix: radix,
            prefix: prefix,
            uppercase: true,
            padding: padding
        )
    }

    public var prefixed: Self {
        switch radix {
            case 2:
                return prefix("0b")
            case 8:
                return prefix("0o")
            case 16:
                return prefix("0x")
            default:
                return self
        }
    }

    public func prefix(_ value: String) -> Self {
        RadixFormatStyle(
            radix: radix,
            prefix: value,
            uppercase: uppercase,
            padding: padding
        )
    }

    public func pad(to length: Int) -> Self {
        RadixFormatStyle(
            radix: radix,
            prefix: prefix,
            uppercase: uppercase,
            padding: length
        )
    }
}
