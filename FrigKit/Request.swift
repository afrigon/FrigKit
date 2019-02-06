//
//    MIT License
//
//    Copyright (c) 2019 Alexandre Frigon
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.
//

import Foundation

public enum HTTPMethod: String {
    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"

    init(_ method: String?) {
        self = HTTPMethod(rawValue: (method ?? "GET").uppercased()) ?? .get
    }
}

public enum HTTPStatusCode: UInt16 {
    case
    `continue` = 100,
    switchingProtocols = 101,

    ok = 200,
    created = 201,
    accepted = 202,
    nonAuthoritativeInformation = 203,
    noContent = 204,
    resetContent = 205,
    partialContent = 206,

    multipleChoices = 300,
    movedPermanently = 301,
    found = 302,
    seeOther = 303,
    notModified = 304,
    useProxy = 305,
    unused = 306,
    temporaryRedirect = 307,

    badRequest = 400,
    unauthorized = 401,
    paymentRequired = 402,
    forbidden = 403,
    notFound = 404,
    methodNotAllowed = 405,
    notAcceptable = 406,
    proxyAuthenticationRequired = 407,
    requestTimeout = 408,
    conflict = 409,
    gone = 410,
    lengthRequired = 411,
    preconditionFailed = 412,
    requestEntityTooLarge = 413,
    requestUriTooLong = 414,
    unsupportedMediaType = 415,
    requestedRangeNotSatisfiable = 416,
    expectationFailed = 417,

    internalServerError = 500,
    notImplemented = 501,
    badGateway = 502,
    serviceUnavailable = 503,
    gatewayTimeout = 504,
    httpVersionNotSupported = 505,

    // Customs
    unknown = 1000,
    invalidURL = 1001

    public var string: String {
        let s = String(describing: self)
        return try! NSRegularExpression(pattern: "([A-Z])").stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: " $0")
    }

    init(_ statusCode: UInt16 = 1000) {
        self = HTTPStatusCode(rawValue: statusCode) ?? .unknown
    }
}

public enum RequestStatus {
    case pending, running, completed, errored, cancelled
}

public enum RequestLogLevel: UInt8 {
    case none = 0, error = 1, warning = 2, debug = 3
}

public struct RequestError {
    public let url: String
    public let method: String
    public let statusCode: HTTPStatusCode

    var string: String {
        return "\(self.method) (\(self.url)): \(self.statusCode.rawValue) \(self.statusCode.string)"
    }

    init(request: Request, statusCode: HTTPStatusCode = HTTPStatusCode(), description: String = "") {
        self.init(url: request.url, method: request.method, statusCode: statusCode)
    }

    init(url: URL? = nil, method: HTTPMethod = .get, statusCode: HTTPStatusCode = HTTPStatusCode()) {
        self.url = url != nil ? url!.absoluteString : "nil"
        self.method = method.rawValue
        self.statusCode = statusCode
    }
}

public class Response {
    let status: HTTPStatusCode
    let rawData: Data?

    init() {

    }
}

public class TextResponse: Response {

}

public class JSONResponse: Response {

}

public class ObjectResponse<T: Decodable>: Response {

}

public class ImageResponse: Response {
    let image: UIImage

    init?() {
        return nil
    }
}

public class Request {
    public static var logLevel: RequestLogLevel = .warning

    private let requestId: String = NSUUID().uuidString

    private var _status: RequestStatus = .pending
    public var status: RequestStatus { return self._status }

    private var _error: RequestError?
    public var error: RequestError? { return self._error }

    fileprivate var url: URL?
    fileprivate var method: HTTPMethod = .get
    private var headers = [String: String]()
    private var parameters = [String: String]()
    private var body: Data?

    convenience init(_ url: String, method: HTTPMethod = .get, parameters: [String: String] = [:], headers: [String: String] = [:]) {
        self.init(URL(string: url), method: method, parameters: parameters, headers: headers)
    }

    convenience init(request: URLRequest) {
        self.body = request.httpBody
        self.init(request.url, method: HTTPMethod(request.httpMethod), headers: request.allHTTPHeaderFields ?? [:])
    }

    init(_ url: URL?, method: HTTPMethod = .get, parameters: [String: String] = [:], headers: [String: String] = [:]) {
        guard let url = url else {
            self.set(error: RequestError())
            return
        }

        self.url = url
        self.method = method
        self.parameters = parameters
        self.headers = headers
    }

    public static func == (_ lhs: Request, _ rhs: Request) -> Bool { return lhs.requestId == rhs.requestId }
    public static func != (_ lhs: Request, _ rhs: Request) -> Bool { return (lhs == rhs) }

    private func set(error: RequestError) {
        self._error = error
        self._status = .errored
    }

    public func cancel() {
        guard ![RequestStatus.cancelled,
                RequestStatus.completed,
                RequestStatus.errored].contains(self.status) else {
            return
        }

        self._status = .cancelled
        // actually cancel
    }

    private func resume() {
        guard self.status == .pending else { return }
        self._status = .running

        URLSessionDataTask()
    }

    func text() {}
}
