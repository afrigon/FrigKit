extension String {
    public var isHexadecimal: Bool {
        let pattern = "^[0-9a-fA-F]*$"

        return range(of: pattern, options: .regularExpression) != nil
    }

    public static func placeholder(size: Int) -> String {
        String(repeating: "X", count: size)
    }
}
