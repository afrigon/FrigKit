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

public enum HTTPStatusCode: Int {
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
    isTeapot = 418,

    internalServerError = 500,
    notImplemented = 501,
    badGateway = 502,
    serviceUnavailable = 503,
    gatewayTimeout = 504,
    httpVersionNotSupported = 505,

    // Customs
    unknown = 1000,
    invalidURL = 1001,
    invalidURLRequest = 1002,
    invalidURLResponse = 1003,
    invalidData = 1004,
    URLSessionError = 1005,
    JSONparsingError = 1006,
    objectParsingError = 1007,
    imageParsingError = 1008,
    invalidResponseMimeType = 1009

    public var string: String {
        let s = String(describing: self)
        return try! NSRegularExpression(pattern: "([A-Z])").stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: " $0")
    }

    init(_ statusCode: Int = 1000) {
        self = HTTPStatusCode(rawValue: statusCode) ?? .unknown
    }
}

public enum RequestStatus {
    case pending, running, completed, errored, cancelled
}

public enum RequestLogLevel: UInt8 {
    case none = 0, error = 1, warning = 2, info = 3, debug = 4
}

fileprivate class RequestLogger {
    static func log(_ requiredLevel: RequestLogLevel, _ s: String) {
        guard Request.logLevel.rawValue >= requiredLevel.rawValue else { return }

        let logString = String(describing: requiredLevel).uppercased()
        print("(FrigKit-Request) \(logString): \(s)")
    }
}

public struct RequestError: CustomStringConvertible {
    public let url: String?
    public let method: String?
    public let statusCode: HTTPStatusCode

    public var description: String {
        if let url = self.url, let method = self.method {
            return "\(method) (\(url)): \(self.statusCode.rawValue) \(self.statusCode.string)"
        }

        return "\(self.statusCode.rawValue) \(self.statusCode.string)"
    }

    init(request: URLRequest, statusCode: HTTPStatusCode = HTTPStatusCode(), description: String = "") {
        self.init(url: request.url, method: request.method, statusCode: statusCode)
    }

    init(url: URL? = nil, method: HTTPMethod? = nil, statusCode: HTTPStatusCode = HTTPStatusCode()) {
        self.url = url != nil ? url!.absoluteString : nil
        self.method = method?.rawValue ?? nil
        self.statusCode = statusCode
    }
}

fileprivate protocol ParametersBuilder {
    func build(request: inout URLRequest)
}

public class RequestResponse {
    fileprivate var _statusCode: Int?
    public var statusCode: Int? { return self._statusCode }

    fileprivate var _error: RequestError?
    public var error: RequestError? { return self._error }

    private var _rawData: Data?
    public var rawData: Data? { return self._rawData }

    fileprivate func parse(data: Data?, error: RequestError?) {
        self._rawData = data
        self._error = error
    }
}

public class TextResponse: RequestResponse {
    private var _text: String?
    public var text: String? { return self._text }

    override func parse(data: Data?, error: RequestError?) {
        if let data = data {
            self._text = String(data: data, encoding: .utf8)
        }

        super.parse(data: data, error: error)
    }
}

public class JSONResponse: RequestResponse {
    private var _isArray: Bool = false
    public var isArray: Bool { return self._isArray }

    private var _json: Any?
    public var json: Any { return self._json as Any }

    override func parse(data: Data?, error: RequestError?) {
        if let data = data {
            do {
                self._json = try JSONSerialization.jsonObject(with: data)

                if self._json as? [[String: Any]] != nil {
                    self._isArray = true
                }
            } catch {
                self._error = RequestError(statusCode: .JSONparsingError)
            }
        }

        super.parse(data: data, error: error)
    }
}

public class ObjectResponse<T: Decodable>: JSONResponse {
    private var _object: T?
    public var object: T? { return self._object }

    override func parse(data: Data?, error: RequestError?) {
        if let data = data {
            do {
                self._object = try JSONDecoder().decode(T.self, from: data)
            } catch {
                self._error = RequestError(statusCode: .objectParsingError)
            }
        }

        super.parse(data: data, error: error)
    }
}

fileprivate struct RequestValidation {
    let range: Range<Int>?
    let mimeType: String?

    func validate(response: HTTPURLResponse) -> RequestError? {
        if let range = self.range {
            guard range.contains(response.statusCode) else {
                return RequestError(statusCode: HTTPStatusCode(response.statusCode))
            }
        }

        if let mimeType = self.mimeType, let responseMimeType = response.mimeType {
            guard mimeType == responseMimeType else {
                return RequestError(statusCode: .invalidResponseMimeType)
            }
        }

        return nil
    }
}

fileprivate extension URLRequest {
    fileprivate struct store {
        static var method: HTTPMethod = .get
    }

    fileprivate var method: HTTPMethod {
        get { return store.method }
        set {
            store.method = newValue
            self.httpMethod = newValue.rawValue
        }
    }
}

public class Request {
    public static var logLevel: RequestLogLevel = .warning
    public static var autoValidate: Bool = true

    private let requestId: String = NSUUID().uuidString

    private var _status: RequestStatus = .pending
    public var status: RequestStatus { return self._status }

    private var _error: RequestError?
    public var error: RequestError? { return self._error }

    private var validation: RequestValidation?

    fileprivate var urlRequest: URLRequest?
    fileprivate var response: RequestResponse?
    fileprivate var task: URLSessionTask?

    convenience init(_ url: String, method: HTTPMethod = .get, parameters: [String: String] = [:], headers: [String: String] = [:]) {
        self.init(URL(string: url), method: method, parameters: parameters, headers: headers)
    }

    init(request: URLRequest) {
        RequestLogger.log(.debug, "creating (\(self.requestId)) from URLRequest object")

        let method: HTTPMethod = HTTPMethod(request.httpMethod)

        guard let url = request.url else {
            self.set(error: RequestError(method: method, statusCode: .invalidURL))
            return
        }

        self.urlRequest = request
        self.urlRequest!.method = method

        if Request.autoValidate { self.validate() }

        RequestLogger.log(.debug, "\(method.rawValue) \(url)")
    }

    init(_ url: URL?, method: HTTPMethod = .get, parameters: [String: String] = [:], headers: [String: String] = [:]) {
        RequestLogger.log(.debug, "creating (\(self.requestId)) from arguments")

        guard let url = url else {
            self.set(error: RequestError(method: method, statusCode: .invalidURL))
            return
        }

        self.urlRequest = URLRequest(url: url)
        self.urlRequest!.allHTTPHeaderFields = headers
        self.urlRequest!.method = method
        self.urlRequest!.cachePolicy = .reloadRevalidatingCacheData

        if Request.autoValidate { self.validate() }

        RequestLogger.log(.debug, "\(method.rawValue) \(url)")
    }

    public static func == (_ lhs: Request, _ rhs: Request) -> Bool { return lhs.requestId == rhs.requestId }
    public static func != (_ lhs: Request, _ rhs: Request) -> Bool { return (lhs == rhs) }

    private func set(error: RequestError) {
        self._error = error
        self._status = .errored
        RequestLogger.log(.error, "\(error.description)")
    }

    @discardableResult
    public func validate(range: Range<Int>? = nil, mimeType: String? = nil) -> Request {
        if self.validation == nil {
            RequestLogger.log(.debug, "turning on validation module")
        }

        if range == nil && mimeType == nil {
            self.validation = RequestValidation(range: 200..<300, mimeType: mimeType)
        } else {
            self.validation = RequestValidation(range: range, mimeType: mimeType)
        }


        if let mimeType = mimeType {
            RequestLogger.log(.debug, "using \(mimeType) as validation mime type")
        }

        if let range = self.validation!.range {
            RequestLogger.log(.debug, "using \(range) as validation range")
        }

        return self
    }

    @discardableResult
    public func cache(policy: URLRequest.CachePolicy) -> Request {
        guard self.urlRequest != nil else { return self }

        RequestLogger.log(.debug, "changing cache policy to \(String(describing: policy))")
        self.urlRequest!.cachePolicy = policy
        return self
    }

    @discardableResult
    public func timeout(in timeout: TimeInterval) -> Request {
        guard self.urlRequest != nil else { return self }

        RequestLogger.log(.debug, "changing timeout to \(timeout)")
        self.urlRequest!.timeoutInterval = timeout
        return self
    }

    public func cancel() {
        RequestLogger.log(.info, "cancelling (\(self.requestId))")

        guard ![RequestStatus.cancelled,
                RequestStatus.completed,
                RequestStatus.errored].contains(self.status) else {
                    return
        }

        self._status = .cancelled
        self.task?.cancel()

        RequestLogger.log(.info, "cancelled query to \(self.urlRequest!.method.rawValue) \(self.urlRequest!.url?.absoluteString ?? "nil")")
    }

    private func resume(callback: @escaping () -> Void) {
        RequestLogger.log(.debug, "sending (\(self.requestId))")

        guard self.urlRequest != nil else {
            self.set(error: RequestError(statusCode: .invalidURLRequest))
            return callback()
        }

        guard ![RequestStatus.running, RequestStatus.cancelled].contains(self._status) else {
            RequestLogger.log(.warning, "stoped sending (\(self.requestId)) because it's status was \(self._status)")
            return callback()
        }
        self._status = .running

        RequestLogger.log(.info, "\(self.urlRequest!.method.rawValue) \(self.urlRequest!.url?.absoluteString ?? "nil")")

        self.task = URLSession.shared.dataTask(with: self.urlRequest!) { (data, response, error) in
            RequestLogger.log(.debug, "response from (\(self.requestId))")

            if error != nil {
                self.set(error: RequestError(url: self.urlRequest!.url, method: self.urlRequest!.method, statusCode: .URLSessionError))
                self.response!.parse(data: data, error: self._error)
                return callback()
            }

            if let response = response as? HTTPURLResponse {
                self.response!._statusCode = response.statusCode

                if let error = self.validation?.validate(response: response) {
                    self.set(error: error)
                    self.response?.parse(data: data, error: self._error)
                }
            }

            guard let data = data else {
                self.set(error: RequestError(url: self.urlRequest!.url, method: self.urlRequest!.method, statusCode: .invalidData))
                self.response!.parse(data: nil, error: self._error)
                return callback()
            }

            RequestLogger.log(.debug, "parsing (\(self.requestId))")

            self.response!.parse(data: data, error: self._error)
            DispatchQueue.main.async { return callback() }
        }

        self.task!.resume()
    }

    func raw(callback: @escaping (RequestResponse) -> Void) {
        RequestLogger.log(.debug, "requested raw data for (\(self.requestId))")
        self.response = RequestResponse()
        self.resume { callback(self.response!) }
    }

    func text(callback: @escaping (TextResponse) -> Void) {
        RequestLogger.log(.debug, "requested text data for (\(self.requestId))")
        self.response = TextResponse()
        self.resume { callback(self.response as! TextResponse) }
    }

    func json(callback: @escaping (JSONResponse) -> Void) {
        RequestLogger.log(.debug, "requested json data for (\(self.requestId))")
        self.response = JSONResponse()
        self.resume { callback(self.response as! JSONResponse) }
    }

    func object<T>(callback: @escaping (ObjectResponse<T>) -> Void) {
        RequestLogger.log(.debug, "requested object data for (\(self.requestId))")
        self.response = ObjectResponse<T>()
        self.resume { callback(self.response as! ObjectResponse<T>) }
    }
}
