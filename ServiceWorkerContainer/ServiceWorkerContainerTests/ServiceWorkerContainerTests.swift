import PromiseKit
@testable import ServiceWorker
@testable import ServiceWorkerContainer
import XCTest

class ServiceWorkerContainerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        CoreDatabase.clearForTests()

        CoreDatabase.dbDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("testDB", isDirectory: true)
        do {
            if FileManager.default.fileExists(atPath: CoreDatabase.dbDirectory!.path) == false {
                try FileManager.default.createDirectory(at: CoreDatabase.dbDirectory!, withIntermediateDirectories: true, attributes: nil)
            }
        } catch {
            fatalError()
        }

        factory.workerFactory.serviceWorkerDelegateProvider = ServiceWorkerStorageProvider(storageURL: CoreDatabase.dbDirectory!)
        CoreDatabase.inConnection { connection -> Promise<Bool> in
            return .value(connection.open)
        }.assertResolves()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    let factory = WorkerRegistrationFactory(withWorkerFactory: WorkerFactory())

    func testContainerCreation() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.

        XCTAssertNoThrow(try {
            let testContainer = try ServiceWorkerContainer(forURL: URL(string: "https://www.example.com")!, withFactory: factory)
            XCTAssert(testContainer.url.absoluteString == "https://www.example.com")
        }())
    }

    func testGetRegistrations() {
        firstly { () -> Promise<Void> in
            let reg1 = try factory.create(scope: URL(string: "https://www.example.com/scope1")!)
            let reg2 = try factory.create(scope: URL(string: "https://www.example.com/scope2")!)
            let container = try ServiceWorkerContainer(forURL: URL(string: "https://www.example.com/scope3")!, withFactory: factory)
            return container.getRegistrations()
                .map { registrations -> Void in
                    XCTAssertEqual(registrations.count, 2)
                    XCTAssertEqual(registrations[0], reg1)
                    XCTAssertEqual(registrations[1], reg2)
                }
        }
        .assertResolves()
    }

    func testGetRegistration() {
        firstly { () -> Promise<Void> in
            _ = try factory.create(scope: URL(string: "https://www.example.com/scope1/")!)
            let reg1 = try factory.create(scope: URL(string: "https://www.example.com/scope1/scope2/")!)
            _ = try factory.create(scope: URL(string: "https://www.example.com/scope1/scope2/file2.html")!)
            let container = try ServiceWorkerContainer(forURL: URL(string: "https://www.example.com/scope1/scope2/file.html")!, withFactory: factory)
            return container.getRegistration()
                .map { registration -> Void in
                    XCTAssertEqual(registration, reg1)
                }
        }
        .assertResolves()
    }
}
