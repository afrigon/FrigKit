public struct Logger {
    let level: LoggerLevel
    let backend: LoggerBackend
    let formatter: LoggerFormatter

    public init(
        level: LoggerLevel? = nil,
        formatter: LoggerFormatter = .simple,
        backend: LoggerBackend = .stdout
    ) {
        if let level {
            self.level = level
        } else {
#if DEBUG
            self.level = .debug
#else
            self.level = .info
#endif
        }

        self.formatter = formatter
        self.backend = backend
    }

    public func log(level: LoggerLevel, _ items: Any..., separator: String = " ") {
        guard level >= self.level else {
            return
        }

        let s: String = items
            .map(String.init(describing:))
            .joined(separator: separator)

        guard !s.isEmpty else {
            return
        }

        backend.log(formatter.format(level: level, s))
    }

    public func debug(_ items: Any..., separator: String = " ") {
        log(level: .debug, items, separator: separator)
    }

    public func info(_ items: Any..., separator: String = " ") {
        log(level: .info, items, separator: separator)
    }

    public func warn(_ items: Any..., separator: String = " ") {
        log(level: .warn, items, separator: separator)
    }

    public func error(_ items: Any..., separator: String = " ") {
        log(level: .error, items, separator: separator)
    }
}

extension Logger {
    private static var loggers: [Logger] = []

    public static func log(level: LoggerLevel, _ items: Any..., separator: String = " ") {
        for logger in loggers {
            logger.log(level: level, items, separator: separator)
        }
    }

    public static func log(on logger: Logger) {
        log(on: [logger])
    }

    public static func log(on loggers: [Logger]) {
        self.loggers = loggers
    }

    public static func debug(_ items: Any..., separator: String = " ") {
        log(level: .debug, items, separator: separator)
    }

    public static func info(_ items: Any..., separator: String = " ") {
        log(level: .info, items, separator: separator)
    }

    public static func warn(_ items: Any..., separator: String = " ") {
        log(level: .warn, items, separator: separator)
    }

    public static func error(_ items: Any..., separator: String = " ") {
        log(level: .error, items, separator: separator)
    }
}
