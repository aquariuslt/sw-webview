import Foundation
import ServiceWorker
import WebKit

/// Because of the URL and body mapping we do, we need to wrap the WKURLSchemeTask class.
public class SWURLSchemeTask {
    public let request: URLRequest
    fileprivate let underlyingTask: WKURLSchemeTask
    public var open: Bool = true
    //    public let origin:URL?
    public let referrer: URL?

    // We could use request.url?, but since we've already checked in the init()
    // that the URL exists, we can provide a non-optional var here.
    //    public let url:URL

    public var originalServiceWorkerURL: URL? {
        return self.underlyingTask.request.url
    }

    // There doesn't seem to be any built in functionality for tracking when
    // a task has stopped, internal to the task itself. So we use the scheme
    // handler with this dictionary to keep track.
    static var currentlyActiveTasks: [Int: SWURLSchemeTask] = [:]

    init(underlyingTask: WKURLSchemeTask) throws {
        self.underlyingTask = underlyingTask

        guard let requestURL = underlyingTask.request.url else {
            throw ErrorMessage("Incoming task must have a URL set")
        }

        // 此处 不应该直接使用 new URL(baseUrl, requestURL) 进行计算
        // 对于以下场景，需要做到
        guard let modifiedURL = URL(swWebViewString: requestURL.absoluteString) else {
            throw ErrorMessage("Could not parse incoming task URL")
        }

        //        self.url = modifiedURL

        var request = URLRequest(url: modifiedURL, cachePolicy: underlyingTask.request.cachePolicy, timeoutInterval: underlyingTask.request.timeoutInterval)

        request.httpMethod = underlyingTask.request.httpMethod
        request.allHTTPHeaderFields = underlyingTask.request.allHTTPHeaderFields

        // The mainDocumentURL is not accurate inside iframes, so we're deliberately removing it
        // here, to ensure we don't ever rely on it.
        request.mainDocumentURL = nil

        //        if let origin = underlyingTask.request.value(forHTTPHeaderField: "Origin") {
        //            // We use this to detect what our container scope is
        //
        //            guard let originURL = URL(swWebViewString: origin) else {
        //                throw ErrorMessage("Could not parse Origin header correctly")
        //            }
        //
        //            self.origin = originURL
        //
        //        } else {
        //            self.origin = nil
        //        }

        if let referer = underlyingTask.request.value(forHTTPHeaderField: "Referer") {
            guard let referrerURL = URL(swWebViewString: referer) else {
                throw ErrorMessage("Could not parse Referer header correctly")
            }
            self.referrer = referrerURL
            print("[swift: SWURLSchemeTask] set referer url to \(referrerURL) when request url is \(underlyingTask.request.url)")

        } else if let url = underlyingTask.request.url, url.path != "/" {
            let refererUrl = url.pathExtension.isEmpty ? url : url.deletingLastPathComponent()
            var refererUrlComponent = URLComponents(string: refererUrl.absoluteString)
            refererUrlComponent?.queryItems = nil

            self.referrer = refererUrlComponent?.url;

            print("[swift: SWURLSchemeTask] url.pathExtension.isEmpty : \(url.pathExtension.isEmpty)")
            print("[swift: SWURLSchemeTask] url.deletingLastPathComponent() : \(url.deletingLastPathComponent())")
            print("[swift: SWURLSchemeTask] set referer url to \(refererUrlComponent?.url) when request url is \(underlyingTask.request.url)")
        } else {
            self.referrer = nil
            print("[swift: SWURLSchemeTask] set referer url to nil when request url is \(underlyingTask.request.url)")
        }

        // Because WKURLSchemeTask doesn't receive POST bodies (rdar://33814386) we have to
        // graft them into a header. Gross. Hopefully this gets fixed.


        let graftedBody = underlyingTask.request.value(forHTTPHeaderField: SWWebViewBridge.graftedRequestBodyHeader)

        print("[swift: SWWebView] 开始从 header. X-Grafted-Request-Body 中读取数据, url:", requestURL, request.allHTTPHeaderFields);

        if let body = graftedBody {
            request.httpBody = body.data(using: .utf8)
            print("[swift: SWWebView] 成功获取 graftedBody: ", requestURL, body.data(using: .utf8))
        }

        self.request = request

        SWURLSchemeTask.currentlyActiveTasks[self.hash] = self
    }

    func close() {
        self.open = false
        SWURLSchemeTask.currentlyActiveTasks.removeValue(forKey: self.hash)
    }

    static func getExistingTask(for task: WKURLSchemeTask) -> SWURLSchemeTask? {
        return self.currentlyActiveTasks[task.hash]
    }

    public func didReceive(_ data: Data) throws {
        if self.open == false {
            Log.warn?("URL task trying to send data to a closed connection")
            return
        }
        self.underlyingTask.didReceive(data)
    }

    public func didReceiveHeaders(statusCode: Int, headers: [String: String] = [:]) throws {
        var modifiedHeaders = headers
        // Always want to make sure API responses aren't cached
        modifiedHeaders["Cache-Control"] = "no-cache"

        guard let originalWorkerURL = self.originalServiceWorkerURL else {
            throw ErrorMessage("No original service worker URL available")
        }

        guard let response = HTTPURLResponse(url: originalWorkerURL, statusCode: statusCode, httpVersion: nil, headerFields: modifiedHeaders) else {
            throw ErrorMessage("Was not able to create HTTPURLResponse, unknown reason")
        }

        if self.open == false {
            throw ErrorMessage("Task is no longer open")
        }


        let defaultURLHolder = "";
        print("[swift: SWURLSchemeTask]: did receive response with url: \(self.request.url?.absoluteString ?? defaultURLHolder)");
        self.underlyingTask.didReceive(response)
    }

    public func didFinish() throws {
        if self.open == false {
            Log.warn?("URL task trying to finish an already closed connection")
            return
        }
        self.underlyingTask.didFinish()
        self.close()
    }

    /// This doesn't throw because what's the point - if it fails, it fails
    public func didFailWithError(_ error: Error) {
        if self.open == false {
            Log.warn?("URL task trying to finish with error when it's already finished")
            return
        }
        self.underlyingTask.didFailWithError(error)
        self.close()
    }

    var hash: Int {
        return self.underlyingTask.hash
    }
}
