extension Array {
    public subscript(i: UInt8) -> Element {
        get {
            self[Int(i)]
        }
        set {
            self[Int(i)] = newValue
        }
    }

    public subscript(i: UInt16) -> Element {
        get {
            self[Int(i)]
        }
        set {
            self[Int(i)] = newValue
        }
    }

    public subscript(i: UInt32) -> Element {
        get {
            self[Int(i)]
        }
        set {
            self[Int(i)] = newValue
        }
    }

    public subscript(i: UInt64) -> Element {
        get {
            self[Int(i)]
        }
        set {
            self[Int(i)] = newValue
        }
    }
}
