import JavaScriptCore
import PromiseKit
@testable import ServiceWorker
import XCTest

class ServiceWorkerTests: XCTestCase {
    func testLoadContentFunction() {
        let sw = ServiceWorker.createTestWorker(id: name, content: "var testValue = 'hello';")

        return sw.evaluateScript("testValue")
            .map { (val: String?) -> Void in
                XCTAssertEqual(val, "hello")
            }
            .assertResolves()
    }

    func testThreadFreezing() {
        let sw = ServiceWorker.createTestWorker(id: name, content: "var testValue = 'hello';")

        sw.withJSContext { _ in

            let semaphore = DispatchSemaphore(value: 0)

            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                Log.info?("signalling")
                semaphore.signal()
            }

            DispatchQueue.global().async {
                Log.info?("doing this now")
            }

            Log.info?("waiting")
            semaphore.wait()
        }
        .assertResolves()
    }

    func testThreadFreezingInJS() {
        let sw = ServiceWorker.createTestWorker(id: name, content: "var testValue = 'hello';")

        let run: @convention(block) () -> Void = {
            let semaphore = DispatchSemaphore(value: 0)
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                _ = Promise.value
                    .map { () -> Void in
                        Log.info?("signalling")
                        semaphore.signal()
                    }
            }
            Log.info?("wait")
            semaphore.wait()
        }

        sw.withJSContext { context in

            context.globalObject.setValue(run, forProperty: "testFunc")
        }
        .then {
            sw.evaluateScript("testFunc()")
        }
        .map { () -> Void in
            // compiler needs this to be here
        }
        .assertResolves()
    }
}
