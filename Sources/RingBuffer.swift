import Foundation

// since struct has no deinit, we need to wrap it in a class object that
// is reference counted so it is cleaned up when struct is deinit
class WrappedBuffer<Element> {
    let buffer: UnsafeMutableBufferPointer<Element>
    
    init(bufferSize: Int) {
        let bufferStart: UnsafeMutablePointer<Element> = UnsafeMutablePointer.allocate(capacity: bufferSize)
        self.buffer = UnsafeMutableBufferPointer(
            start: bufferStart,
            count: bufferSize
        )
    }
    
    deinit {
        self.buffer.baseAddress!.deallocate(capacity: self.buffer.count)
    }
}

public struct RingBuffer<Element> {
    
    private var _wrappedBuffer: WrappedBuffer<Element>
    
    mutating var buffer: UnsafeMutableBufferPointer<Element> {
        if !isKnownUniquelyReferenced(&_wrappedBuffer) {
            
        }
    }
    
    // index of the first element (the oldest element)
    var bufferStartIndex: Int
    
    // index of the next empty element, unless the buffer is full in which case
    // this points to the first element. the order of elements in the buffer is
    // defined as the indices from bufferStartIndex to bufferEndIndex (non-inclusive) but this
    // may wrap around the end of the underlying buffer array
    var bufferEndIndex: Int
    
    // true if this is empty -- this is necessary since
    // both full and empty have _startIndex == _bufferEndIndex
    private(set) public var isEmpty: Bool
    
    public var isFull: Bool {
        return (self.bufferStartIndex == self.bufferEndIndex && !self.isEmpty)
    }
    
    // max elements this buffer can hold
    public var bufferSize: Int {
        return self.buffer.count
    }
    
    public init(bufferSize: Int) {
        self._wrappedBuffer = WrappedBuffer(bufferSize: bufferSize)
        self.bufferStartIndex = 0
        self.bufferEndIndex = 0
        self.isEmpty = true
    }
    
    public mutating func removeAll() {
        self.bufferStartIndex = 0
        self.bufferEndIndex = 0
        self.isEmpty = true
    }
    
    // number of valid element in the buffer
    public var count: Int {
        if self.bufferStartIndex == self.bufferEndIndex {
            // either empty or full
            return self.isEmpty ? 0 : self.bufferSize
        }
        
        if self.bufferStartIndex < self.bufferEndIndex {
            return self.bufferEndIndex - self.bufferStartIndex
        }
        
        // start > end
        return self.bufferSize - (self.bufferStartIndex + self.bufferEndIndex)
    }
    
    public func first() -> Element? {
        guard !self.isEmpty else {
            return nil
        }
        return self.buffer[self.bufferStartIndex]
    }
    
    // pops first element if it exists
    public mutating func pop() -> Element? {
        guard let first = self.first() else {
            return nil
        }
        self.bufferStartIndex = self.indexSucceeding(index: self.bufferStartIndex)
        self.isEmpty = (self.bufferStartIndex == self.bufferEndIndex)
        return first
    }
    
    // pushes element onto the end of the queue. If the queue is full, this
    // will pop off and return the oldest element. Otherwise, it will return nil
    @discardableResult
    public mutating func push(element: Element) -> Element? {
        let popped: Element?
        if self.isFull {
            popped = self.pop()
        } else {
            popped = nil
        }
        self.buffer[self.bufferEndIndex] = element
        self.bufferEndIndex = self.indexSucceeding(index: self.bufferEndIndex)
        self.isEmpty = false
        return popped
    }
    
    func indexSucceeding(index: Int) -> Int {
        let next = index + 1
        guard next < self.bufferSize else {
            return 0
        }
        return next
    }
}

extension RingBuffer: Collection {
    public var startIndex: Int {
        return 0
    }
    
    public var endIndex: Int {
        return self.count
    }
    
    /// Returns the position immediately after the given index.
    ///
    /// - Parameter i: A valid index of the collection. `i` must be less than
    ///   `endIndex`.
    /// - Returns: The index value immediately after `i`.
    public func index(after i: Int) -> Int {
        return i + 1
    }
    
    public subscript(position: Int) -> Element {
        if position < 0 || position >= self.count {
            fatalError("Index out of range: \(position)")
        }
        let idx = (self.bufferStartIndex + position) % self.bufferSize
        return self.buffer[idx]
    }
}
