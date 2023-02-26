import XCTest
import Nimble
@testable import FrigKit
import FrigKitTestUtil

final class ChecksumTests: XCTestCase {
    func test_description() {
        let checksum = "1".data(using: .utf8)!.checksum
        let expected = "6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b"

        expect(checksum.description).to(equal(expected))
    }

    func test_description_init() {
        let value = "6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b"
        let checksum = Checksum(value)!

        expect(checksum.value).to(equal(value))
    }

    func test_equatable() throws {
        let a = "1".data(using: .utf8)!.checksum
        let b = try decode("6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b")
        let c = "2".data(using: .utf8)!.checksum

        expect(a).to(equal(b))
        expect(a).toNot(equal(c))
    }

    func test_encode() throws {
        let checksum = "test".data(using: .utf8)!.checksum
        let encoded = try JSONEncoder().encode(checksum)
        let expected = "\"9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08\"".data(using: .utf8)!

        expect(encoded).to(equal(expected))
    }

    private func decode(_ data: String) throws -> Checksum {
        let data = "\"\(data)\"".data(using: .utf8)!
        return try JSONDecoder().decode(Checksum.self, from: data)
    }

    func test_decode() throws {
        let checksum = "796e43a5a8cdb73b92b5f59eb50610cea3efa8ce229cd7f0557983091b2b4552"
        let decoded = try decode(checksum)

        expect(decoded.value).to(equal(checksum))
    }

    func test_init_validation() {
        let valid     = "796e43a5a8cdb73b92b5f59eb50610cea3efa8ce229cd7f0557983091b2b4552"
        let short     = "796e43a5a8cdb73b92b5f59eb50610cea3efa8ce229cd7f0557983091b2b455"
        let long      = "796e43a5a8cdb73b92b5f59eb50610cea3efa8ce229cd7f0557983091b2b45522"
        let invalid   = "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
        let uppercase = "796E43A5A8CDB73B92B5F59EB50610CEA3EFA8CE229CD7F0557983091B2B4552"

        expect { Checksum(short) }.to(beNil())
        expect { Checksum(long) }.to(beNil())
        expect { Checksum(invalid) }.to(beNil())

        expect { Checksum(valid) }.toNot(beNil())
        expect { Checksum(uppercase) }.toNot(beNil())
    }

    func test_decode_validation() {
        let valid     = "796e43a5a8cdb73b92b5f59eb50610cea3efa8ce229cd7f0557983091b2b4552"
        let short     = "796e43a5a8cdb73b92b5f59eb50610cea3efa8ce229cd7f0557983091b2b455"
        let long      = "796e43a5a8cdb73b92b5f59eb50610cea3efa8ce229cd7f0557983091b2b45522"
        let invalid   = "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
        let uppercase = "796E43A5A8CDB73B92B5F59EB50610CEA3EFA8CE229CD7F0557983091B2B4552"

        expect { [weak self] in try self?.decode(short) }.to(throwError())
        expect { [weak self] in try self?.decode(long) }.to(throwError())
        expect { [weak self] in try self?.decode(invalid) }.to(throwError())

        expect { [weak self] in try self?.decode(valid) }.toNot(throwError())
        expect { [weak self] in try self?.decode(uppercase) }.toNot(throwError())
    }
}
