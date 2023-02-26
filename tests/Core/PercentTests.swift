@testable import SwiftnessFoundation
import SwiftnessTestKit

final class StringTests: XCTestCase {
    func test_empty_string_is_hexadecimal() {
        expect("".isHexadecimal).to(beTrue())
    }

    func test_numeric_is_hexadecimal() {
        expect("1234567890".isHexadecimal).to(beTrue())
    }

    func test_lowercase_is_hexadecimal() {
        expect("abcdef".isHexadecimal).to(beTrue())
    }

    func test_uppercase_is_hexadecimal() {
        expect("ABCDEF".isHexadecimal).to(beTrue())
    }

    func test_0x_prefix_is_not_hexadecimal() {
        expect("0x123456".isHexadecimal).to(beFalse())
        expect("0X123456".isHexadecimal).to(beFalse())
    }

    func test_invalid_characters_are_not_hexadecimal() {
        expect("z".isHexadecimal).to(beFalse())
    }
}
