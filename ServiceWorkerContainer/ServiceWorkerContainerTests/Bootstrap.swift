import Foundation
import ServiceWorker
import ServiceWorkerContainer
import XCTest

class TestBootstrap: NSObject {
    override init() {
        super.init()

        Log.error = { print($0) }
        Log.warn = { print($0) }
        Log.info = { print($0) }
        Log.debug = { print($0) }

        do {
            CoreDatabase.dbDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("testDB", isDirectory: true)
            if FileManager.default.fileExists(atPath: CoreDatabase.dbDirectory!.path) == false {
                try FileManager.default.createDirectory(at: CoreDatabase.dbDirectory!, withIntermediateDirectories: true, attributes: nil)
            }
        } catch {
            XCTFail("\(error)")
        }
    }
}
