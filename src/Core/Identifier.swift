public protocol Identifier: Identifiable, Codable, Sendable, Equatable, Hashable, CustomStringConvertible where ID: Codable & CustomStringConvertible {
    init(id: ID)
}

public extension Identifier {
    var description: String {
        id.description
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(id: try container.decode(ID.self))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.id)
    }
}

public protocol StringIdentifier: Identifier, ExpressibleByStringLiteral where ID == String { }

public extension StringIdentifier {
    init(stringLiteral value: ID) {
        self.init(id: value)
    }
}

public protocol IntegerIdentifier: Identifier, ExpressibleByIntegerLiteral where ID: BinaryInteger { }

public extension IntegerIdentifier {
    init(integerLiteral value: ID) {
        self.init(id: value)
    }
}
