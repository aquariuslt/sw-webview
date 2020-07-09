@testable import ServiceWorker
import XCTest

class PerformanceTests: XCTestCase {
    func testPerformanceExample() {
        self.measure {
            let testSw = ServiceWorker.createTestWorker(id: "PERFORMANCE")
            testSw.evaluateScript("console.log('hi'); 'succeed!'")
                .map { (result: String) -> Void in
                    XCTAssertEqual(result, "succeed!")
                }
                .assertResolves()
        }
    }
}
