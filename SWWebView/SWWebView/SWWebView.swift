import Foundation
import ServiceWorker
import WebKit

public class SWWebView: WKWebView {
    static let ServiceWorkerScheme = "sw"

    public var serviceWorkerPermittedDomains: [String] = []
    fileprivate var swNavigationDelegate: SWWebViewNavigationDelegate?
    fileprivate var bridge: SWWebViewBridge!
    public weak var containerDelegate: SWWebViewContainerDelegate?

    fileprivate weak var outerNavigationDelegate: WKNavigationDelegate?

    /// Because we're doing all sorts of weird things with URLs, we have two
    /// navigation delegates - one internal, that handles the URL mapping,
    /// and one external, that in theory is ignorant of this not being a
    /// WKWebView.
    override public var navigationDelegate: WKNavigationDelegate? {
        get {
            return self.outerNavigationDelegate
        }
        set(value) {
            self.outerNavigationDelegate = value
        }
    }

    fileprivate static func addSWHooksToConfiguration(_ configuration: WKWebViewConfiguration, bridge: SWWebViewBridge) {
        let pathToJS = Bundle(for: SWWebView.self).bundleURL
            .appendingPathComponent("js-dist", isDirectory: true)
            .appendingPathComponent("runtime.js")

        print("开始注入 js-dist/runtime.js from \(pathToJS)")

        let jsRuntimeSource: String

        do {
            jsRuntimeSource = try String(contentsOf: pathToJS)
        } catch {
            Log.error?("Could not load SWWebKit runtime JS. Quitting.")

            // There's something very fundamentally wrong with the app if this happens,
            // so we hard exit.
            fatalError()
        }

        let userScript = WKUserScript(source: SWWebView.wrapScriptInWebviewSettings(jsRuntimeSource), injectionTime: .atDocumentStart, forMainFrameOnly: false)

        configuration.userContentController.addUserScript(userScript)

        configuration.userContentController.add(bridge, name: "SWWebView")

        configuration.setURLSchemeHandler(bridge, forURLScheme: SWWebView.ServiceWorkerScheme)
    }

    public static var javascriptConfigDictionary: String {
        return """
        {
        API_REQUEST_METHOD: "\(SWWebViewBridge.serviceWorkerRequestMethod)",
        SW_PROTOCOL: "\(SWWebView.ServiceWorkerScheme)",
        GRAFTED_REQUEST_HEADER: "\(SWWebViewBridge.graftedRequestBodyHeader)",
        EVENT_STREAM_PATH: "\(SWWebViewBridge.eventStreamPath)"
        }
        """
    }

    static func wrapScriptInWebviewSettings(_ script: String) -> String {
        return """
        (function() {
        var swwebviewSettings = \(self.javascriptConfigDictionary);
        \(script)
        })()
        """
    }

    override public init(frame: CGRect, configuration: WKWebViewConfiguration) {
        self.bridge = SWWebViewBridge()
        SWWebView.addSWHooksToConfiguration(configuration, bridge: self.bridge)
        self.swNavigationDelegate = SWWebViewNavigationDelegate()
        super.init(frame: frame, configuration: configuration)

        super.navigationDelegate = self.swNavigationDelegate
    }

    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @discardableResult
    override public func load(_ request: URLRequest) -> WKNavigation? {
        if request.url == nil {
            // not sure how this would happen, but still
            return super.load(request)
        }

        if let navigationDelegate = self.swNavigationDelegate {
            let transformedRequest = navigationDelegate.makeServiceWorkerSuitableURLRequest(self, request: request)
            return super.load(transformedRequest)
        } else {
            return super.load(request)
        }
    }

    /// We need to ensure that we return the non-SW scheme URL no matter what.
    override public var url: URL? {
        if let url = super.url {
            if let navigationDelegate = self.swNavigationDelegate, url.scheme == SWWebView.ServiceWorkerScheme {
                return navigationDelegate.makeNonServiceWorker(url: url)
            } else {
                return url
            }
        } else {
            return nil
        }
    }
}
