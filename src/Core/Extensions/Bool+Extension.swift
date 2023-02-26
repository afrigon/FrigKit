extension Bool {
    @inlinable public init<T: BinaryInteger>(_ value: T) {
        self = value != 0
    }
}
