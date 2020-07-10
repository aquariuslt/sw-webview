import GCDWebServers
import PromiseKit
import ServiceWorker
import ServiceWorkerContainer
import SWWebView
import UIKit
import WebKit

class ViewController: UIViewController {
    var coordinator: SWWebViewCoordinator?

    private var swView: SWWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.addStubs()
        let config = WKWebViewConfiguration()

        Log.info = { print("INFO: \($0)") }

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

        self.swView = SWWebView(frame: self.view.frame, configuration: config)
        // This will move to a delegate method eventually
        self.swView.serviceWorkerPermittedDomains.append("localhost:4567")
        self.swView.containerDelegate = self.coordinator!
        self.view.addSubview(self.swView)

        title = "SWWebView"

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(self.refresh))

        let url = URLComponents(string: "sw://localhost:4567/scope/")!
        URLCache.shared.removeAllCachedResponses()
        print("Loading \(url.url!.absoluteString)")
        _ = self.swView.load(URLRequest(url: url.url!))
    }

    @objc private func refresh() {
        self.swView.reload()
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
}
