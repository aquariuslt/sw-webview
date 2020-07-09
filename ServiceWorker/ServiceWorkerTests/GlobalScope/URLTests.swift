@testable import ServiceWorker
import XCTest

class URLTests: XCTestCase {
    func testURLExists() {
        let sw = ServiceWorker.createTestWorker(id: name)

        sw.evaluateScript("typeof(URL) != 'undefined' && self.URL == URL")
            .map { (val: Bool?) in

                XCTAssertEqual(val, true)
            }
            .assertResolves()
    }

    func testURLHashExists() {
        let sw = ServiceWorker.createTestWorker(id: name)

        sw.evaluateScript("new URL('http://www.example.com/#test').hash")
            .map { (val: String?) in

                XCTAssertEqual(val, "#test")
            }
            .assertResolves()
    }

    func testURLHashCanBeSet() {
        let sw = ServiceWorker.createTestWorker(id: name)

        sw.evaluateScript("let url = new URL('http://www.example.com/#test'); url.hash = 'test2'; url.hash")
            .map { (val: String?) in

                XCTAssertEqual(val, "#test2")
            }
            .assertResolves()
    }
}
