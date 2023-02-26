public protocol LoggerBackend {
    func log<S: StringProtocol>(_ s: S)
}
