import Foundation
import PromiseKit
import ServiceWorker

public class TestBootstrap: NSObject {
    override init() {
        super.init()
        //        Log.enable()

        Log.debug = { print("DEBUG: \($0)") }
        Log.info = { print("INFO: \($0)") }
        Log.warn = { print("WARN: \($0)") }
        Log.error = { print("ERROR: \($0)") }
    }
}
