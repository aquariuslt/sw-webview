import PromiseKit
@testable import ServiceWorker
import XCTest

class TimeoutTests: XCTestCase {
    func promiseDelay(delay: Double) -> Promise<Void> {
        return Promise<Void> { resolver in
            DispatchQueue.main.asyncAfter(deadline: .now() + (delay / 1000)) {
                resolver.fulfill(())
            }
        }
    }

    func testSetTimeout() {
        let sw = ServiceWorker.createTestWorker(id: name)

        sw.evaluateScript("""

            var ticks = 0;

            setTimeout(function() {
                ticks++;
            }, 10);

            setTimeout(function() {
                ticks++;
            }, 30);

        """)
            .then {
                self.promiseDelay(delay: 20)
            }
            .then {
                sw.evaluateScript("ticks")
            }
            .map { (response: Int) -> Void in
                XCTAssertEqual(response, 1)
            }
            .assertResolves()
    }

    //    func testSetTimeoutWithArguments() {
    //        let sw = ServiceWorker.createTestWorker(id: name)
    //
    //        sw.evaluateScript("""
    //            new Promise((fulfill,reject) => {
    //                setTimeout(function(one,two) {
    //                    fulfill([one,two])
    //                },10,"one","two")
    //            });
    //
    //        """)
    //            .then { jsVal in
    //                return JSPromise.fromJSValue(jsVal!)
    //            }
    //            .then { (response: [String]?) -> Void in
    //                XCTAssertEqual(response?[0], "one")
    //                XCTAssertEqual(response?[1], "two")
    //            }
    //
    //            .assertResolves()
    //    }

    func testSetInterval() {
        let sw = ServiceWorker.createTestWorker(id: name)

        sw.evaluateScript("""

            var ticks = 0;

            var interval = setInterval(function() {
                ticks++;
            }, 10);

        """)
            .then {
                self.promiseDelay(delay: 25)
            }
            .then {
                sw.evaluateScript("clearInterval(interval); ticks")
            }
            .then { (response: Int?) -> Promise<Void> in
                XCTAssertEqual(response, 2)
                // check clearInterval works
                return self.promiseDelay(delay: 10)
            }
            .then { () -> Promise<Int> in
                sw.evaluateScript("ticks")
            }
            .map { (response: Int) -> Void in
                XCTAssertEqual(response, 2)
            }
            .assertResolves()
    }
}
