import PromiseKit
@testable import ServiceWorker
import XCTest

class StreamPipeTests: XCTestCase {
    func testPipingAStream() {
        let testData = "THIS IS TEST DATA".data(using: String.Encoding.utf8)!

        let inputStream = InputStream(data: testData)
        let outputStream = OutputStream.toMemory()

        StreamPipe.pipe(from: inputStream, to: outputStream, bufferSize: 1)
            .map { _ -> Void in

                let transferredData = outputStream.property(forKey: Stream.PropertyKey.dataWrittenToMemoryStreamKey) as! Data

                let str = String(data: transferredData, encoding: String.Encoding.utf8)

                XCTAssertEqual(str, "THIS IS TEST DATA")
            }
            .assertResolves()
    }

    func testPipingAStreamOffMainThread() {
        let testData = "THIS IS TEST DATA".data(using: String.Encoding.utf8)!

        let inputStream = InputStream(data: testData)
        let outputStream = OutputStream.toMemory()

        let (promise, resolver) = Promise<Void>.pending()

        let queue = DispatchQueue.global()

        DispatchQueue.global().async {
            StreamPipe.pipe(from: inputStream, to: outputStream, bufferSize: 1)
                .map { _ -> Void in

                    let transferredData = outputStream.property(forKey: Stream.PropertyKey.dataWrittenToMemoryStreamKey) as! Data

                    let str = String(data: transferredData, encoding: String.Encoding.utf8)

                    XCTAssertEqual(str, "THIS IS TEST DATA")
                    resolver.fulfill(())
                }
                .catch { error in
                    resolver.reject(error)
                }
        }

        promise.assertResolves()
    }

    func testPipingToMultipleStreams() {
        let testData = "THIS IS TEST DATA".data(using: String.Encoding.utf8)!

        let inputStream = InputStream(data: testData)
        let outputStream = OutputStream.toMemory()
        let outputStream2 = OutputStream.toMemory()

        let streamPipe = StreamPipe(from: inputStream, bufferSize: 1)
        XCTAssertNoThrow(try streamPipe.add(stream: outputStream))
        XCTAssertNoThrow(try streamPipe.add(stream: outputStream2))

        streamPipe.pipe()
            .map { () -> Void in
                [outputStream, outputStream2].forEach { stream in
                    let transferredData = stream.property(forKey: Stream.PropertyKey.dataWrittenToMemoryStreamKey) as! Data

                    let str = String(data: transferredData, encoding: String.Encoding.utf8)

                    XCTAssertEqual(str, "THIS IS TEST DATA")
                }
            }
            .assertResolves()
    }
}
