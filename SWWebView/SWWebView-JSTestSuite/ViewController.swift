import GCDWebServers
import PromiseKit
import ServiceWorker
import ServiceWorkerContainer
import SWWebView
import UIKit
import WebKit

class ViewController: UIViewController, WKNavigationDelegate {
    var coordinator: SWWebViewCoordinator?

    private var swView: SWWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.addStubs()
        let config = WKWebViewConfiguration()
        let preferences = WKPreferences()

        preferences.javaScriptEnabled = true;

        config.preferences = preferences;

        Log.info = {
            print("INFO: \($0)")
        }
        Log.debug = {
            print("DEBUG: \($0)")
        }
        Log.error = {
            print("ERROR: \($0)")
        }
        Log.warn = {
            print("WARN: \($0)")
        }

        let storageURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                .appendingPathComponent("testapp-db", isDirectory: true)

        do {
            if FileManager.default.fileExists(atPath: storageURL.path) {
                try FileManager.default.removeItem(at: storageURL)
            }
            try FileManager.default.createDirectory(at: storageURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            fatalError()
        }

        self.coordinator = SWWebViewCoordinator(storageURL: storageURL)

        self.view.backgroundColor = UIColor.white
        self.swView = SWWebView(frame: self.view.frame, configuration: config)
        // This will move to a delegate method eventually
        self.swView.containerDelegate = self.coordinator!
        self.view.addSubview(self.swView)

        self.swView.navigationDelegate = self

        title = "SWWebView"

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(refresh))
        navigationItem.leftBarButtonItem = UIBarButtonItem.init(title: "Back", style: .plain, target: self, action: #selector(back))

        // MARK: - Home URL

//        let urlString = "sw://tytx.m.cn.miaozhen.com/r/k=2184908&p=7caxc&dx=__IPDX__&rt=2&pro=s&ns=__IP__&ni=__IESID__&v=__LOC__&xa=__ADPLATFORM__&tr=__REQUESTID__&ro=sm&txp=__TXP__&o=https://m.buick.com.cn/envisions/?utm_source=qqnews&utm_medium=APP&utm_term=SP-BU2000478_HS-202007791_MOB32-2_32650925&utm_content=SGMMRK2020000157&utm_campaign=2020envisions"
//        let urlString = "http://tytx.m.cn.miaozhen.com/r/k=2119286&p=7OO87&dx=__IPDX__&rt=2&ns=__IP__&ni=__IESID__&v=__LOC__&xa=__ADPLATFORM__&tr=__REQUESTID__&mo=__OS__&m0=__OPENUDID__&m0a=__DUID__&m1=__ANDROIDID1__&m1a=__ANDROIDID__&m2=__IMEI__&m4=__AAID__&m5=__IDFA__&m6=__MAC1__&m6a=__MAC__&txp=__TXP__&vo=3a0882f9c&vr=2&o=https%3A%2F%2Fwww.tiffany.cn%2F%3Fomcid%3Ddis-cn_tencentvideo_openingpage_2019%2Bspring%2Bbrand%26utm_medium%3Ddisplay-cn%26utm_source%3Dtencentvideo_openingpage%26utm_campaign%3D2019%2Bspring%2Bbrand"

        let urlString = "sw://www.tiffany.cn/?omcid=dis-cn_tencentvideo_openingpage_2019+spring+brand&utm_medium=display-cn&utm_source=tencentvideo_openingpage&utm_campaign=2019+spring+brand"
//        let urlString = "sw://localhost:5000"
//        let urlString = "sw://localhost:4567"
//        let urlString = "sw://m.baidu.com"

        guard let urlComps = URLComponents(string: urlString), let host = urlComps.host else {
            fatalError("must provide a valid url")
        }

        let domain: String = {
            if let port = urlComps.port, port != 80 && port != 443 {
                return "\(host):\(port)"
            }
            return host
        }()

        swView.serviceWorkerPermittedDomains.append(domain)
        URLCache.shared.removeAllCachedResponses()
        print("[swift: JSTestSuite/ViewController] Loading: \(urlComps.url!.absoluteString)")
        _ = self.swView.load(URLRequest(url: urlComps.url!))
    }

    @objc private func back() {
        if swView.canGoBack {
            swView.goBack()
        }
    }

    @objc private func refresh() {
        swView.reload()
    }

    func addStubs() {
        SWWebViewBridge.routes["/ping"] = { _, _ in

            Promise.value([
                "pong": true
            ])
        }

        SWWebViewBridge.routes["/ping-with-body"] = { _, json in

            let responseText = json?["value"] as? String ?? "no body found"

            return Promise.value([
                "pong": responseText
            ])
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("[swift: ViewController] didFinish for url: \(webView.url?.absoluteString ?? "none(default)")")
        webView.evaluateJavaScript("eruda.init();") { initResult, error in
            print("[swift: ViewController] init eruda result: \(initResult)")
        }

    }
}
