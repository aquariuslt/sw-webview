import PromiseKit
@testable import ServiceWorker
import XCTest

class FetchEventTests: XCTestCase {
    func testRespondWithString() {
        let sw = ServiceWorker.createTestWorker(id: name, content: """
            self.addEventListener('fetch',(e) => {
                e.respondWith(new Response("hello"));
            });
        """)

        let request = FetchRequest(url: URL(string: "https://www.example.com")!)

        let fetch = FetchEvent(request: request)

        sw.dispatchEvent(fetch)
            .then {
                try fetch.resolve(in: sw)
            }
            .then { res -> Promise<String> in
                XCTAssertNotNil(res)
                return res!.text()
            }
            .map { responseText in
                XCTAssertEqual(responseText, "hello")
            }
            .assertResolves()
    }

    func testRespondWithPromise() {
        let sw = ServiceWorker.createTestWorker(id: name, content: """
            self.addEventListener('fetch',(e) => {
                e.respondWith(new Promise((fulfill) => {
                    fulfill(new Response("hello"))
                }));
            });
        """)

        let request = FetchRequest(url: URL(string: "https://www.example.com")!)

        let fetch = FetchEvent(request: request)

        sw.dispatchEvent(fetch)
            .then {
                try fetch.resolve(in: sw)
            }
            .then { res -> Promise<String> in
                XCTAssertNotNil(res)
                return res!.text()
            }
            .compactMap { responseText in
                XCTAssertEqual(responseText, "hello")
            }
            .assertResolves()
    }
}
