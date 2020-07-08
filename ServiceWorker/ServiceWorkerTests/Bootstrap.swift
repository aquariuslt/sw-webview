import Foundation
import ServiceWorker
import PromiseKit

public class TestBootstrap: NSObject {
    override init() {
        super.init()
        //        Log.enable()

        Log.debug = { print($0) }
        Log.info = { print($0) }
        Log.warn = { print($0) }
        Log.error = { print($0) }
    }
}
