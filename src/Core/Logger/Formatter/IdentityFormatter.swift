public struct IdentityLoggerFormatter: LoggerFormatter {
    public func format<S>(level: LoggerLevel, _ s: S) -> String where S: StringProtocol {
        String(s)
    }
}

extension LoggerFormatter where Self == IdentityLoggerFormatter {
    public static var none: Self {
        IdentityLoggerFormatter()
    }
}
