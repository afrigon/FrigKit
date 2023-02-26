import Foundation
import CryptoKit

extension DataProtocol {
    public var checksum: Checksum {
        .init(data: self)
    }
}

public struct Checksum: Sendable {
    let function: any HashFunction.Type = SHA256.self
    let value: String

    public init<D: DataProtocol>(data: D) {
        value = function
            .hash(data: data)
            .compactMap { String(format: "%02x", $0) }
            .joined()
    }
}

extension Checksum: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

extension Checksum: Equatable {
    public static func == (lhs: Checksum, rhs: Checksum) -> Bool {
        lhs.value == rhs.value
    }

    public static func == (lhs: Checksum, rhs: String) -> Bool {
        lhs.value == rhs.lowercased()
    }
}

extension String {
    public static func == (lhs: String, rhs: Checksum) -> Bool {
        lhs.lowercased() == rhs.value
    }
}

extension Checksum: LosslessStringConvertible {
    public var description: String {
        value
    }

    public init?(_ description: String) {
        guard description.isHexadecimal && description.count == function.blockByteCount else {
            return nil
        }

        value = description.lowercased()
    }
}

extension Checksum: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

extension Checksum: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)

        guard value.isHexadecimal && value.count == function.blockByteCount else {
            let context: DecodingError.Context = .init(
                codingPath: container.codingPath,
                debugDescription: "Checksum needs to be a hexadecimal string"
            )

            throw DecodingError.typeMismatch(String.self, context)
        }

        self.value = value.lowercased()
    }
}
