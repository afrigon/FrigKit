public struct StandardOutputLogger: LoggerBackend {
    public func log<S>(_ s: S) where S: StringProtocol {
        print(s)
    }
}

extension LoggerBackend where Self == StandardOutputLogger {
    public static var stdout: Self {
        StandardOutputLogger()
    }
}
