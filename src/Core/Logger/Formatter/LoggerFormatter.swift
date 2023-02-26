public protocol LoggerFormatter {
    func format<S: StringProtocol>(level: LoggerLevel, _ s: S) -> String
}
