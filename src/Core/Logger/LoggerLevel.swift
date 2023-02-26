public enum LoggerLevel: Sendable, Hashable, Equatable, Codable, Comparable {
    case debug
    case info
    case warn
    case error
    case none
}

extension LoggerLevel: CustomStringConvertible {
    public var description: String {
        switch self {
            case .debug:
                return "DEBUG"
            case .info:
                return "INFO"
            case .warn:
                return "WARN"
            case .error:
                return "ERROR"
            case .none:
                return "NONE"
        }
    }
}
