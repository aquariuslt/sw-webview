//
//  ClientsTests.swift
//  ServiceWorkerTests
//
//  Created by alastair.coote on 24/08/2017.
//  Copyright © 2017 Guardian Mobile Innovation Lab. All rights reserved.
//

import XCTest
@testable import ServiceWorker
import JavaScriptCore

class ClientsTests: XCTestCase {

    class TestClient: ClientProtocol {
        func postMessage(message _: Any?, transferable _: [Any]?) {
        }

        let id: String

        let type: ClientType

        let url: URL

        var isControlled: Bool = true

        init(id: String, type: ClientType, url: URL) {
            self.id = id
            self.type = type
            self.url = url
        }
    }

    class TestWindowClient: TestClient, WindowClientProtocol {
        func focus(_: (Error?, WindowClientProtocol?) -> Void) {
        }

        func navigate(to _: URL, _: (Error?, WindowClientProtocol?) -> Void) {
        }

        var focused: Bool

        var visibilityState: WindowClientVisibilityState

        init(id: String, type: ClientType, url: URL, focused: Bool, visibilityState: WindowClientVisibilityState) {
            self.focused = focused
            self.visibilityState = visibilityState
            super.init(id: id, type: type, url: url)
        }
    }

    class TestClients: WorkerClientsProtocol {

        var clients: [ClientProtocol] = []
        var claimFunc: (() -> Void)?

        func get(id: String, worker _: ServiceWorker, _ cb: (Error?, ClientProtocol?) -> Void) {
            cb(nil, self.clients.first(where: { $0.id == id }))
        }

        func matchAll(options: ClientMatchAllOptions, _ cb: (Error?, [ClientProtocol]?) -> Void) {
            cb(nil, self.clients.filter({ client in

                let asTestCase = client as! TestClient

                return (options.type == "all" || options.type == client.type.stringValue) &&
                    (options.includeUncontrolled == true || asTestCase.isControlled == true)

            }))
        }

        func openWindow(_ url: URL, _ cb: (Error?, ClientProtocol?) -> Void) {
            let newClient = TestWindowClient(id: "NEWCLIENT", type: .Window, url: url, focused: true, visibilityState: .Visible)
            self.clients.append(newClient)
            return cb(nil, newClient)
        }

        func claim(_ cb: (Error?) -> Void) {
            if let claim = self.claimFunc {
                claim()
            }
            cb(nil)
        }
    }

    func testShouldGetClientByID() {

        let testAPI = TestClients()
        testAPI.clients.append(TestClient(id: "TESTCLIENT", type: .Window, url: URL(string: "http://www.example.com")!))

        let worker = ServiceWorker.createTestWorker(id: self.name, implementations: WorkerImplementations(registration: nil, clients: testAPI))

        worker.evaluateScript("""
            Promise.all([
                self.clients.get("TESTCLIENT"),
                self.clients.get("TESTCLIENT2")
            ])
            .then(function(clients) {
                var client = clients[0];
                return [client.id, client.url, typeof client.postMessage, clients[1] === null]
            })
        """)
            .then { val in
                return JSPromise.fromJSValue(val!)
            }
            .then { val -> Void in
                let returnArray = val?.value.toArray()
                XCTAssertEqual(returnArray?.count, 4)
                XCTAssertEqual(returnArray?[0] as? String, "TESTCLIENT")
                XCTAssertEqual(returnArray?[1] as? String, "http://www.example.com")
                XCTAssertEqual(returnArray?[2] as? String, "function")
                XCTAssertEqual(returnArray?[3] as? Bool, true)
            }
            .assertResolves()
    }

    func testShouldMatchAllWithOptions() {

        let testAPI = TestClients()
        testAPI.clients.append(TestClient(id: "TESTCLIENT", type: .Window, url: URL(string: "http://www.example.com")!))
        testAPI.clients.append(TestClient(id: "TESTCLIENT2", type: .Worker, url: URL(string: "http://www.example.com")!))
        let controlled = TestClient(id: "TESTCLIENT3", type: .Window, url: URL(string: "http://www.example.com")!)
        controlled.isControlled = false
        testAPI.clients.append(controlled)

        let worker = ServiceWorker.createTestWorker(id: self.name, implementations:  WorkerImplementations(registration: nil, clients: testAPI))

        worker.evaluateScript("""
            Promise.all([
                self.clients.matchAll(),
                self.clients.matchAll({includeUncontrolled: true}),
                self.clients.matchAll({type: "window"}),
                self.clients.matchAll({type: "window", includeUncontrolled:true})
            ])
            .then(function(responses) {
                let ids = responses.map(function(array) {
                    return array.map(function(r) { return r.id; })
                })
                return {"all":ids[0],"uncontrolled":ids[1],"window":ids[2],"windowUncontrolled":ids[3]}
            })
        """)
            .then { val in
                return JSPromise.fromJSValue(val!)
            }
            .then { val -> Void in

                let all = val?.value.objectForKeyedSubscript("all").toArray() as? [String]
                let uncontrolled = val?.value.objectForKeyedSubscript("uncontrolled").toArray() as? [String]
                let window = val?.value.objectForKeyedSubscript("window").toArray() as? [String]
                let windowUncontrolled = val?.value.objectForKeyedSubscript("windowUncontrolled").toArray() as? [String]

                XCTAssertEqual(all?.count, 2)
                XCTAssertEqual(all?[0], "TESTCLIENT")
                XCTAssertEqual(all?[1], "TESTCLIENT2")

                XCTAssertEqual(uncontrolled?.count, 3)
                XCTAssertEqual(uncontrolled?[0], "TESTCLIENT")
                XCTAssertEqual(uncontrolled?[1], "TESTCLIENT2")
                XCTAssertEqual(uncontrolled?[2], "TESTCLIENT3")

                XCTAssertEqual(window?.count, 1)
                XCTAssertEqual(window?[0], "TESTCLIENT")

                XCTAssertEqual(windowUncontrolled?.count, 2)
                XCTAssertEqual(windowUncontrolled?[0], "TESTCLIENT")
                XCTAssertEqual(windowUncontrolled?[1], "TESTCLIENT3")
            }
            .assertResolves()
    }

    func testShouldRunClaim() {

        var claimed = false

        let testAPI = TestClients()
        testAPI.claimFunc = {
            claimed = true
        }

        let worker = ServiceWorker.createTestWorker(id: self.name, implementations: WorkerImplementations(registration: nil, clients: testAPI))

        worker.evaluateScript("""
            self.clients.claim()
        """)
            .then { val in
                return JSPromise.fromJSValue(val!)
            }
            .then { _ -> Void in
                XCTAssertEqual(claimed, true)
            }
            .assertResolves()
    }
}
