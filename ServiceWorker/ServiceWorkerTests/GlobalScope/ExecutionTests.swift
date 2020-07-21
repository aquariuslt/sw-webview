@testable import ServiceWorker
import XCTest

class ExecutionTests: XCTestCase {
    func testAsyncDispatch() {
        // Trying to work out why variables sometimes don't exist

        let worker = ServiceWorker.createTestWorker(id: name, content: """
                var test = "hello"
            """)

        worker.evaluateScript("test")
            .map { (jsVal: String) -> Void in
                XCTAssertEqual(jsVal, "hello")
            }
            .assertResolves()
    }
}
