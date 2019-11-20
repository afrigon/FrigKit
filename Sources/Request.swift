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

public class Request {
    public static var logLevel: LogLevel = .warning
    public static var autoValidate: Bool = true
    public static var useDefaultHeaders: Bool = true

    private let requestId: String = NSUUID().uuidString

    private var _status: Status = .pending
    public var status: Status { return self._status }

    private var _error: Error?
    public var error: Error? { return self._error }

    private var validation: Validation?

    fileprivate var urlRequest: URLRequest?
    fileprivate var response: Response?
    fileprivate var task: URLSessionTask?

    public var cachePolicy: URLRequest.CachePolicy {
        get { return self.urlRequest?.cachePolicy ?? .reloadRevalidatingCacheData }
        set { self.urlRequest?.cachePolicy = newValue }
    }

    public var timeoutInterval: TimeInterval {
        get { return self.urlRequest?.timeoutInterval ?? 0 }
        set { self.urlRequest?.timeoutInterval = newValue }
    }

    convenience init(_ url: String,
                     method: Method = .get,
                     parameters: [String: String] = [:],
                     headers: Headers = Headers()) {
        self.init(URL(string: url),
                  method: method,
                  parameters: parameters,
                  headers: headers)
    }

    init(request: URLRequest) {
        Logger.log(.debug, requestId, "init from URLRequest")

        let method: Method = Method(request.httpMethod)
        guard request.url != nil else {
            self.set(error: Error(method: method, statusCode: .invalidUrl))
            return
        }

        self.urlRequest = request
        self.urlRequest!.method = method

        if Request.autoValidate { self.validate() }
    }

    init(_ url: URL?,
         method: Method = .get,
         parameters: [String: String] = [:],
         headers: Headers = Headers()) {
        Logger.log(.debug, requestId, "init from arguments")

        guard let url = url else {
            self.set(error: Error(method: method, statusCode: .invalidUrl))
            return
        }

        self.urlRequest = URLRequest(url: url)
        self.urlRequest?.headers = headers
        self.urlRequest!.method = method
        self.urlRequest!.cachePolicy = .reloadRevalidatingCacheData

        if Request.autoValidate { self.validate() }
    }

    public static func == (_ lhs: Request, _ rhs: Request) -> Bool {
        return lhs.requestId == rhs.requestId
    }

    public static func != (_ lhs: Request, _ rhs: Request) -> Bool {
        return (lhs == rhs)
    }

    private func set(error: Error) {
        self._error = error
        self._status = .errored
        Logger.log(.error, requestId, "\(error.description)")
    }

    @discardableResult
    public func validate(range: Range<Int>? = nil, mimeType: String? = nil) -> Request {
        let range = range == nil && mimeType == nil ? 200..<300 : range
        self.validation = Validation(range: range, mimeType: mimeType)

        Logger.log(.info, requestId, self.validation!.description)

        return self
    }

    public func addHeader(_ header: Header) {
        self.urlRequest?.addHeader(header)
    }

    public func cancel() {
        Logger.log(.info, requestId, "cancelling request")
        guard !self.status.in([.cancelled, .completed, .errored]) else { return }

        self._status = .cancelled
        self.task?.cancel()

        Logger.log(.info, requestId, "cancelled request")
    }

    private func setRunningState() -> Bool {
        guard !self.status.in([.running, .cancelled]) else {
            Logger.log(.warning, requestId, "not running request, status was: \(self._status)")
            return false
        }

        guard self.urlRequest != nil else {
            self.set(error: Error(statusCode: .invalidUrlRequest))
            return false
        }

        self._status = .running
        return true
    }

    private func setCompletedState(error: Error?) {
        if let error = error {
            Logger.log(.info, self.requestId, "completed request with error")
            Logger.log(.error, self.requestId, String(describing: error.errorObject))
            self._status = .errored
        } else {
            Logger.log(.info, self.requestId, "completed request")
            self._status = .completed
        }
    }

    private func parseBody(_ data: Data) -> String {
        guard let type = self.response!.headers["Content-Type"] else {
            return String(data: data, encoding: .utf8) ?? ""
        }

        switch type {
        case ContentType.json.rawValue:
            if let object = try? JSONSerialization.jsonObject(with: data, options: []),
                let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
                let json = String(data: data, encoding: .utf8) {
                return json
            }

            fallthrough
        case ContentType.jpeg.rawValue, ContentType.png.rawValue, ContentType.bmp.rawValue, ContentType.gif.rawValue, ContentType.mp3.rawValue, ContentType.mpeg.rawValue, ContentType.binary.rawValue:
            return ""
        default:
            return String(data: data, encoding: .utf8) ?? ""
        }

    }

    private func resume(callback: @escaping () -> Void) {
        guard self.setRunningState() else { return callback() }

        Logger.log(.info, requestId, "starting request")
        var debugInfo: String = ""

        debugInfo += String(describing: self.urlRequest!.method).uppercased() + " "
        debugInfo += self.urlRequest!.url?.absoluteString ?? ""

        Logger.log(.info, requestId, debugInfo)

        if Request.logLevel == .debug {
            debugInfo = "\n\n\n\(debugInfo)\n\n\(self.urlRequest!.headers.description)"
        }

        self.task = URLSession.shared.dataTask(with: self.urlRequest!) { (data, response, error) in
            if let error = error {
                self.set(error: Error(url: self.urlRequest!.url,
                                      method: self.urlRequest!.method,
                                      statusCode: .urlSessionError,
                                      error: error))
                self.response!.parse(data: data, error: self._error)

                Logger.log(.debug, self.requestId, debugInfo)

                return DispatchQueue.main.async { return callback() }
            }

            if let response = response as? HTTPURLResponse {
                let code = StatusCode(response.statusCode)
                let headers = response.allHeaderFields as? [String: String] ?? [:]

                self.response!._statusCode = response.statusCode
                self.response!._headers = headers

                if Request.logLevel == .debug {
                    debugInfo += "\n\n\n\(code.rawValue) \(code.string)"
                    debugInfo += "\n\n\(headers.map { "\($0.0): \($0.1)" }.joined(separator: "\n"))\n"
                }

                if let error = self.validation?.validate(response: response) {
                    self.set(error: error)
                    self.response?.parse(data: data, error: self._error)
                }
            }

            guard let data = data else {
                self.set(error: Error(url: self.urlRequest!.url,
                                      method: self.urlRequest!.method,
                                      statusCode: .invalidData))
                self.response!.parse(data: nil, error: self._error)

                Logger.log(.debug, self.requestId, debugInfo)

                return DispatchQueue.main.async { return callback() }
            }

            Logger.log(.info, self.requestId, "parsing data")

            if Request.logLevel == .debug {
                debugInfo += "\n\(self.parseBody(data))\n"
                Logger.log(.debug, self.requestId, debugInfo)
            }


            self.response!.parse(data: data, error: self._error)

            self.setCompletedState(error: self.response!.error)

            DispatchQueue.main.async { return callback() }
        }

        self.task!.resume()
    }
}

extension Request {
    func send(callback: ((Response) -> Void)? = nil) {
        if let callback = callback {
            self.raw(callback: callback)
        } else {
            self.response = Response()
            self.resume {}
        }
    }

    func raw(callback: @escaping (Response) -> Void) {
        self.response = Response()
        self.resume { callback(self.response!) }
    }

    func text(callback: @escaping (Response.Text) -> Void) {
        self.response = Response.Text()
        self.resume { callback(self.response as! Response.Text) }
    }

    func json(callback: @escaping (Response.JSON) -> Void) {
        self.response = Response.JSON()
        self.resume { callback(self.response as! Response.JSON) }
    }

    func object<T>(callback: @escaping (Response.Object<T>) -> Void) {
        self.response = Response.Object<T>()
        self.resume { callback(self.response as! Response.Object<T>) }
    }
}

extension Request {
    public func params(_ params: [String: Any]) -> Request {
        if self.urlRequest!.method.in([.get, .options, .trace]) {
            self.encodeQueryUrl(params: params)
            return self
        }

        self.encodeBodyUrl(params: params)
        return self
    }

    private func encodeQueryUrl(params: [String: Any]) {
        guard let url = self.urlRequest?.url else { return }

        let query = params.map { "\($0.0)=\($0.1)" }.joined(separator: "&")
        self.urlRequest?.url = URL(string: "\(url)\(url.query == nil ? "?" : "&")\(query)")
    }

    private func encodeBodyUrl(params: [String: Any]) {
        let body = params.map { "\($0.0)=\($0.1)" }.joined(separator: "&")
        self.urlRequest?.httpBody = body.data(using: .utf8)

        self.urlRequest?.addHeader(ContentType.formUrlencoded.header())
    }

    public func params(json: Any) -> Request {
        do {
            self.urlRequest?.httpBody = try JSONSerialization.data(withJSONObject: json)
            self.urlRequest?.addHeader(ContentType.json.header())
        } catch {
            self.set(error: Error(statusCode: .jsonParsingError))
        }

        return self
    }

    public func params<T: Encodable>(object: T) -> Request {
        do {
            self.urlRequest?.httpBody = try JSONEncoder().encode(object)
            self.urlRequest?.addHeader(ContentType.json.header())
        } catch {
            self.set(error: Error(statusCode: .jsonParsingError))
        }

        return self
    }
}

extension Request {
    public enum LogLevel: UInt8 {
        case none = 0, error = 1, warning = 2, info = 3, debug = 4
    }
}

extension Request {
    public enum StatusCode: Int {
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
        tooManyRequest = 429,

        internalServerError = 500,
        notImplemented = 501,
        badGateway = 502,
        serviceUnavailable = 503,
        gatewayTimeout = 504,
        httpVersionNotSupported = 505,

        // Customs
        unknown = 1000,
        invalidUrl = 1001,
        invalidUrlRequest = 1002,
        invalidUrlResponse = 1003,
        invalidData = 1004,
        urlSessionError = 1005,
        jsonParsingError = 1006,
        objectParsingError = 1007,
        imageParsingError = 1008,
        invalidResponseMimeType = 1009

        public var string: String {
            let s = String(describing: self)
            return try! NSRegularExpression(pattern: "([A-Z])")
                .stringByReplacingMatches(in: s,
                                          range: NSRange(s.startIndex...,
                                                         in: s),
                                          withTemplate: " $0")
        }

        init(_ statusCode: Int = 1000) {
            self = StatusCode(rawValue: statusCode) ?? .unknown
        }
    }
}

extension Request {
    public enum Method: String {
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
            self = Method(rawValue: (method ?? "GET").uppercased()) ?? .get
        }

        public func `in`(_ methods: [Method]) -> Bool {
            return methods.contains(self)
        }
    }
}

extension Request {
    public enum Status {
        case pending, running, completed, errored, cancelled

        public func `in`(_ statuses: [Status]) -> Bool {
            return statuses.contains(self)
        }
    }
}

extension Request {
    public struct Error: CustomStringConvertible {
        public let url: String?
        public let method: String?
        public let statusCode: StatusCode
        public let errorObject: Swift.Error?

        public var description: String {
            if let url = self.url, let method = self.method {
                return "\(method) (\(url)): \(self.statusCode.rawValue) \(self.statusCode.string)"
            }

            return "\(self.statusCode.rawValue) \(self.statusCode.string)"
        }

        init(url: URL? = nil,
             method: Method? = nil,
             statusCode: StatusCode = StatusCode(),
             error: Swift.Error? = nil) {
            self.url = url != nil ? url!.absoluteString : nil
            self.method = method?.rawValue ?? nil
            self.statusCode = statusCode
            self.errorObject = error
        }
    }
}

extension Request {
    private struct Validation: CustomStringConvertible {
        let range: Range<Int>?
        let mimeType: String?

        public var description: String {
            var str: String = ""
            str += "Validator "
            str += "<mime: \(self.mimeType ?? "nil")> "
            str += "<range: \(String(describing: self.range))>"
            return str
        }

        func validate(response: HTTPURLResponse) -> Error? {
            if let range = self.range {
                guard range.contains(response.statusCode) else {
                    return Error(statusCode: StatusCode(response.statusCode))
                }
            }

            if let mimeType = self.mimeType, let responseMimeType = response.mimeType {
                guard mimeType == responseMimeType else {
                    return Error(statusCode: .invalidResponseMimeType)
                }
            }

            return nil
        }
    }
}

extension Request {
    public class Headers: CustomStringConvertible {
        fileprivate var headers = [String: String]()

        public var description: String {
            self.headers.map { "\($0.0): \($0.1)" }.joined(separator: "\n")
        }

        init() {
            if Request.useDefaultHeaders { self.addDefaultHeaders() }
        }

        convenience init(_ headers: [String: String]) {
            self.init()
            for (key, value) in headers {
                self.headers[key] = value
            }
        }

        convenience init(_ headers: [Header]) {
            self.init()
            for header in headers {
                self.headers[header.name] = header.value
            }
        }

        subscript(name: String) -> String? {
            get { return self.headers[name] }
            set { self.headers[name] = newValue }
        }

        public func add(_ header: Header) {
            self.headers[header.name] = header.value
        }

        public func add(name: String, value: String) {
            self.headers[name] = value
        }

        private func addDefaultHeaders() {
            self.add(.defaultAcceptEncoding)
            self.add(.defaultAcceptLanguage)
            self.add(.defaultUserAgent)
        }
    }
}

extension Request {
    public struct Header: CustomStringConvertible {
        public var name: String
        public var value: String

        public var description: String {
            return "\(self.name): \(self.value)"
        }

        public static let defaultAcceptEncoding: Header = {
            var encodings = ["gzip", "deflate"]
            if #available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *) {
                encodings.insert("br", at: 0)
            }

            return Header(name: "Accept-Encoding", value: encodings.qualityEncoded)
        }()

        public static let defaultAcceptLanguage: Header = {
            Header(name: "Accept-Language",
                   value: Locale.preferredLanguages.prefix(6).qualityEncoded)
        }()

        public static let defaultUserAgent: Header = {
            let lib = "FrigKit"
            guard let info = Bundle.main.infoDictionary else {
                return Header(name: "User-Agent", value: lib)
            }

            let os: String = {
                #if os(iOS)
                return "iOS"
                #elseif os(watchOS)
                return "watchOS"
                #elseif os(macOS)
                return "macOS"
                #elseif os(tvOS)
                return "tvOS"
                #elseif os(Linux)
                return "Linux"
                #else
                return "Unknown"
                #endif
            }()
            let osInfo = ProcessInfo.processInfo.operatingSystemVersion

            var ua = ""
            // app name
            ua += info[kCFBundleExecutableKey as String] as? String ?? "Unknown"
            ua += "/"
            // app version
            ua += info["CFBundleShortVersionString"] as? String ?? "0.0"
            // bundle
            ua += " ("
            ua += info[kCFBundleIdentifierKey as String] as? String ?? "Unknown"
            ua += "; build:"
            // build version
            ua += info[kCFBundleVersionKey as String] as? String ?? "-1"
            ua += "; "
             // os info
            ua += "\(os) \(osInfo.majorVersion).\(osInfo.minorVersion).\(osInfo.patchVersion)"
            ua += ") "
            // lib info
            ua += lib

            return Header(name: "User-Agent", value: ua)
        }()

        public static func authorization(_ value: String) -> Header {
            return Header(name: "Authorization", value: value)
        }

        public static func authorization(username: String, password: String) -> Header {
            let credential = Data("\(username):\(password)".utf8).base64EncodedString()
            return Header.authorization("Basic \(credential)")
        }

        public static func authorization(token: String) -> Header {
            return Header.authorization("Bearer \(token)")
        }
    }

    public enum ContentType: String {
        case text = "text/plain"
        case binary = "application/octet-stream"
        case jpeg = "image/jpeg"
        case png = "image/png"
        case webp = "image/webp"
        case gif = "image/gif"
        case bmp = "image/bmp"
        case mp3 = "audio/mpeg"
        case mpeg = "video/mpeg"
        case js = "text/javascript"
        case json = "application/json"
        case xml = "application/xml"
        case yml = "application/x-yaml"
        case html = "text/html"
        case css = "text/css"
        case csv = "text/csv"
        case formUrlencoded = "application/x-www-form-urlencoded"

        func header() -> Header {
            return Header(name: "Content-Type", value: self.rawValue)
        }
    }
}

extension Request {
    private class Logger {
        static func log(_ requiredLevel: LogLevel, _ id: String, _ s: String) {
            guard Request.logLevel.rawValue >= requiredLevel.rawValue else { return }

            let logString = String(describing: requiredLevel).uppercased()
            print("Request (\(logString)) <\(id)>: \(s)")
        }
    }
}

public class Response {
    fileprivate var _statusCode: Int?
    public var statusCode: Int { return self._statusCode ?? 1000 }

    fileprivate var _headers: [String: String]?
    public var headers: [String: String] { return self._headers ?? [:] }

    fileprivate var _error: Request.Error?
    public var error: Request.Error? { return self._error }

    private var _rawData: Data?
    public var rawData: Data? { return self._rawData }

    fileprivate func parse(data: Data?, error: Request.Error?) {
        self._rawData = data
        self._error = error
    }

    public class Text: Response {
        private var _text: String?
        public var text: String? { return self._text }

        override func parse(data: Data?, error: Request.Error?) {
            if let data = data {
                self._text = String(data: data, encoding: .utf8)
            }

            super.parse(data: data, error: self._error ?? error)
        }
    }

    public class JSON: Response {
        private var _isArray: Bool = false
        public var isArray: Bool { return self._isArray }

        private var _json: Any?
        public var json: Any { return self._json as Any }

        override func parse(data: Data?, error: Request.Error?) {
            if let data = data {
                do {
                    self._json = try JSONSerialization.jsonObject(with: data)

                    if self._json as? [[String: Any]] != nil {
                        self._isArray = true
                    }
                } catch let error {
                    self._error = Request.Error(statusCode: .jsonParsingError, error: error)
                }
            }

            super.parse(data: data, error: self._error ?? error)
        }
    }

    public class Object<T: Decodable>: JSON {
        private var _object: T?
        public var object: T? { return self._object }

        override func parse(data: Data?, error: Request.Error?) {
            if let data = data {
                do {
                    self._object = try JSONDecoder().decode(T.self, from: data)
                } catch let error {
                    self._error = Request.Error(statusCode: .objectParsingError, error: error)
                }
            }

            super.parse(data: data, error: self.error ?? error)
        }
    }
}

private extension URLRequest {
    var headers: Request.Headers {
        get { return Request.Headers(self.allHTTPHeaderFields ?? [:]) }
        set { self.allHTTPHeaderFields = newValue.headers }
    }

    mutating func addHeader(_ header: Request.Header) {
        self.addValue(header.value, forHTTPHeaderField: header.name)
    }

    var method: Request.Method {
        get { return Request.Method(rawValue: self.httpMethod ?? "GET") ?? .get }
        set { self.httpMethod = newValue.rawValue }
    }
}

private extension Collection where Element == String {
    var qualityEncoded: String {
        return self.enumerated().map { "\($1);q=\(1.0 - (Double($0) * 0.1))" }.joined(separator: ", ")
    }
}
