import Foundation

public struct SimpleLoggerFormatter: LoggerFormatter {
    public func format<S>(level: LoggerLevel, _ s: S) -> String where S: StringProtocol {
        let date = Date.now.formatted(.dateTime
            .year(.defaultDigits)
            .month(.twoDigits)
            .day(.twoDigits)
            .hour(.twoDigits(amPM: .omitted))
            .minute(.twoDigits)
            .second(.twoDigits)
            .locale(.init(identifier: "fr_CA"))
        )

        return "\(date) \(level): \(s)"
    }
}

extension LoggerFormatter where Self == SimpleLoggerFormatter {
    public static var simple: Self {
        SimpleLoggerFormatter()
    }
}
