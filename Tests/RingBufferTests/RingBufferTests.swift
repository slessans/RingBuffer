import XCTest
@testable import RingBuffer

class RingBufferTests: XCTestCase {
    
    func testEmpty() {
        let rb = RingBuffer(bufferSize: 5, initialValue: 0)
        XCTAssertEqual(rb.isEmpty, true)
        XCTAssertEqual(rb.isFull, false)
        XCTAssertEqual(rb.count, 0)
        XCTAssertEqual(rb.bufferSize, 5)
        XCTAssertEqual(Array(rb), [])
    }
    
    func testPushOut() {
        var rb = RingBuffer(bufferSize: 2, initialValue: 0)
        XCTAssertEqual(rb.push(element: 1), nil)
        XCTAssertEqual(rb.push(element: 2), nil)
        XCTAssertEqual(Array(rb), [1, 2])
        XCTAssertEqual(rb.push(element: 3), 1)
        XCTAssertEqual(Array(rb), [2, 3])
        XCTAssertEqual(rb.pop(), 2)
        XCTAssertEqual(Array(rb), [3])
        XCTAssertEqual(rb.pop(), 3)
        XCTAssertEqual(Array(rb), [])
        XCTAssertEqual(rb.isEmpty, true)
    }
    
    func testEquality() {
        var rb = RingBuffer(bufferSize: 2, initialValue: 0)
        rb.push(element: 1)
        rb.push(element: 2)
        XCTAssertEqual(rb.elementsEqual([1, 2]), true)
    }

    static var allTests : [(String, (RingBufferTests) -> () throws -> Void)] {
        return [
            ("testEmpty", testEmpty),
            ("testPushOut", testPushOut),
            ("testEquality", testEquality),
        ]
    }
}
