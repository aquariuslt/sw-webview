import ServiceWorker
import XCTest

class PassthroughStreamTests: XCTestCase {
    func testPassthroughStream() {
        let originalData = "TEST DATA".data(using: String.Encoding.utf8)!

        let originalInput = InputStream(data: originalData)

        let (passthroughInput, passthroughOutput) = PassthroughStream.create()

        let finalOutput = OutputStream.toMemory()

        StreamPipe.pipe(from: originalInput, to: passthroughOutput, bufferSize: originalData.count)
            .then { _ in

                StreamPipe.pipe(from: passthroughInput, to: finalOutput, bufferSize: originalData.count)
            }
            .map { () -> Void in

                let data = finalOutput.property(forKey: Stream.PropertyKey.dataWrittenToMemoryStreamKey) as! Data
                let str = String(data: data, encoding: String.Encoding.utf8)

                XCTAssertEqual(str, "TEST DATA")
            }
            .assertResolves()
    }
}
