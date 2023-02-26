@testable import FrigKit
import FrigKitTestUtil

final class RadixFormatStyleTests: XCTestCase {
    func test_binary() {
        let value = 0b10011111.formatted(.number.binary)
        let expected = "10011111"

        expect(value).to(equal(expected))
    }

    func test_octal() {
        let value = 0o234.formatted(.number.octal)
        let expected = "234"

        expect(value).to(equal(expected))
    }

    func test_hexadecimal() {
        let value = 0x80FF00.formatted(.number.hexadecimal)
        let expected = "80ff00"

        expect(value).to(equal(expected))
    }

    func test_uppercased() {
        let value = 0x80FF00.formatted(.number.hexadecimal.uppercased)
        let expected = "80FF00"

        expect(value).to(equal(expected))
    }

    func test_prefix() {
        let value = 0x80FF00.formatted(.number.hexadecimal.prefix("#"))
        let expected = "#80ff00"

        expect(value).to(equal(expected))
    }

    func test_hexadecimal_prefixed() {
        let value = 0x80FF00.formatted(.number.hexadecimal.prefixed)
        let expected = "0x80ff00"

        expect(value).to(equal(expected))
    }

    func test_octal_prefixed() {
        let value = 0o234.formatted(.number.octal.prefixed)
        let expected = "0o234"

        expect(value).to(equal(expected))
    }

    func test_binary_prefixed() {
        let value = 0b10011111.formatted(.number.binary.prefixed)
        let expected = "0b10011111"

        expect(value).to(equal(expected))
    }

    func test_unknown_prefixed() {
        let value = 150.formatted(RadixFormatStyle(radix: 36).prefixed)
        let expected = "46"

        expect(value).to(equal(expected))
    }

    func test_pad() {
        let value = 0x0044.formatted(.number.hexadecimal.pad(to: 4))
        let expected = "0044"

        expect(value).to(equal(expected))
    }
}
