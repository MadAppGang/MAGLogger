import XCTest
@testable import MAGLogger

final class MAGLoggerTests: XCTestCase {
    
    var instanceVar = "an instance variable"
    
    func testLoggingWithoutDestination() {
        let log = MAGLogger.self
        // no destination was set, yet
        log.verbose("MY_TAG", "Where do I log to?")
    }
    
    func testRemoveSender() {
        let log = MAGLogger.self
        let logSender = MockLogSender()
        log.logSender = logSender
        
        var counter: Int = 0
        
        var expectation = XCTestExpectation(description: "")
        logSender.didSend = {
            counter += 1
            expectation.fulfill()
        }
        log.verbose("MY_TAG", "Hi")
        wait(for: [expectation], timeout: 2)

        // Unlink logger
        log.logSender = nil
        XCTAssertNil(log.logSender)

        expectation = XCTestExpectation(description: "")
        logSender.didSend = {
            counter += 1
            expectation.fulfill()
        }
        let _ = XCTWaiter.wait(for: [expectation], timeout: 2)
        XCTAssertEqual(counter, 1)
    }
    
    func testLogPassParameters() {
        let log = MAGLogger.self
        let logSender = MockLogSender()
        log.logSender = logSender
        
        logSender.didSend = {
            XCTAssertEqual(logSender.didSendToLevel, MAGLogger.LogLevel.verbose)
            XCTAssertEqual(logSender.didSendTag, "MY_TAG")
            XCTAssertEqual(logSender.didSendMessage, "TEST_MESSAGE")
            XCTAssertEqual(logSender.didSendToThread, "")
            XCTAssertEqual(logSender.didSendFile, "File")
            XCTAssertEqual(logSender.didSendFunction, "Function()")
            XCTAssertEqual(logSender.didSendLine, 123)
            XCTAssertEqual(logSender.didSendContext as? String, "Context")
        }
        
        log.verbose("MY_TAG", "TEST_MESSAGE", "File", "Function()", line: 123, context: "Context")
    }
    
    func testMessageType() {
        let log = MAGLogger.self
        let logSender = MockLogSender()
        log.logSender = logSender
        
        // String message
        let stringMessage = "Hi!"
        var expectation = XCTestExpectation(description: "message type check")
        logSender.didSend = {
            XCTAssertEqual(logSender.didSendMessage, "\(stringMessage)")
            expectation.fulfill()
        }
        log.verbose("MY_TAG", "Hi!")
        wait(for: [expectation], timeout: 2)

        // Int message
        let intMessage = 777
        expectation = XCTestExpectation(description: "message type check")
        logSender.didSend = {
            XCTAssertEqual(logSender.didSendMessage, "\(intMessage)")
            expectation.fulfill()
        }
        log.verbose("MY_TAG", intMessage)
        wait(for: [expectation], timeout: 2)

        // Float message
        let floatMessage = 3.1415926
        expectation = XCTestExpectation(description: "message type check")
        logSender.didSend = {
            XCTAssertEqual(logSender.didSendMessage, "\(floatMessage)")
            expectation.fulfill()
        }
        log.verbose("MY_TAG", floatMessage)
        wait(for: [expectation], timeout: 2)

        // Date message
        let dateMessage = Date()
        expectation = XCTestExpectation(description: "message type check")
        logSender.didSend = {
            XCTAssertEqual(logSender.didSendMessage, "\(dateMessage)")
            expectation.fulfill()
        }
        log.verbose("MY_TAG", dateMessage)
        wait(for: [expectation], timeout: 2)

        // Array message
        let arrayMessage = [1, 2, 3]
        expectation = XCTestExpectation(description: "message type check")
        logSender.didSend = {
            XCTAssertEqual(logSender.didSendMessage, "\(arrayMessage)")
            expectation.fulfill()
        }
        log.verbose("MY_TAG", arrayMessage)
        wait(for: [expectation], timeout: 2)
        
        // Dictionary message
        let dictionaryMessage: [String: Any] = ["id" : 123, "name" : "Unknown"]
        expectation = XCTestExpectation(description: "message type check")
        logSender.didSend = {
            XCTAssertEqual(logSender.didSendMessage, "\(dictionaryMessage)")
            expectation.fulfill()
        }
        log.verbose("MY_TAG", dictionaryMessage)
        wait(for: [expectation], timeout: 2)
    }
    
    func testGetCorrectThread() {
        let log = MAGLogger.self
        let logSender = MockLogSender()
        log.logSender = logSender
        
        //main thread
        var expectation = XCTestExpectation(description: "main thread check")
        logSender.didSend = { expectation.fulfill() }
        log.verbose("MY_TAG", "Hi")
        wait(for: [expectation], timeout: 2)
        XCTAssertEqual(logSender.didSendToThread, "")

        expectation = XCTestExpectation(description: "main thread check")
        logSender.didSend = { expectation.fulfill() }
        log.debug("MY_TAG", "Hi")
        wait(for: [expectation], timeout: 2)
        XCTAssertEqual(logSender.didSendToThread, "")

        expectation = XCTestExpectation(description: "main thread check")
        logSender.didSend = { expectation.fulfill() }
        log.info("MY_TAG", "Hi")
        wait(for: [expectation], timeout: 2)
        XCTAssertEqual(logSender.didSendToThread, "")

        expectation = XCTestExpectation(description: "main thread check")
        logSender.didSend = { expectation.fulfill() }
        log.warning("MY_TAG", "Hi")
        wait(for: [expectation], timeout: 2)
        XCTAssertEqual(logSender.didSendToThread, "")

        expectation = XCTestExpectation(description: "main thread check")
        logSender.didSend = { expectation.fulfill() }
        log.error("MY_TAG", "Hi")
        wait(for: [expectation], timeout: 2)
        XCTAssertEqual(logSender.didSendToThread, "")

        
        expectation = XCTestExpectation(description: "background thread check")
        DispatchQueue.global(qos: .background).async { [weak self] in
            let threadName = self?.currentThreadName()
            // Verbose
            var expectationSender = XCTestExpectation(description: "sender background thread check")
            logSender.didSend = { expectationSender.fulfill() }
            log.verbose("MY_TAG", "Hi")
            self?.wait(for: [expectationSender], timeout: 2)
            XCTAssertEqual(logSender.didSendToThread, threadName)
            
            // Info
            expectationSender = XCTestExpectation(description: "sender background thread check")
            logSender.didSend = { expectationSender.fulfill() }
            log.info("MY_TAG", "Hi")
            self?.wait(for: [expectationSender], timeout: 2)
            XCTAssertEqual(logSender.didSendToThread, threadName)
            
            // Debug
            expectationSender = XCTestExpectation(description: "sender background thread check")
            logSender.didSend = { expectationSender.fulfill() }
            log.debug("MY_TAG", "Hi")
            self?.wait(for: [expectationSender], timeout: 2)
            XCTAssertEqual(logSender.didSendToThread, threadName)
            
            // Warning
            expectationSender = XCTestExpectation(description: "sender background thread check")
            logSender.didSend = { expectationSender.fulfill() }
            log.warning("MY_TAG", "Hi")
            self?.wait(for: [expectationSender], timeout: 2)
            XCTAssertEqual(logSender.didSendToThread, threadName)
            
            // Error
            expectationSender = XCTestExpectation(description: "sender background thread check")
            logSender.didSend = { expectationSender.fulfill() }
            log.error("MY_TAG", "Hi")
            self?.wait(for: [expectationSender], timeout: 2)
            XCTAssertEqual(logSender.didSendToThread, threadName)
            
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5)
    }
    
    func testAutoClosure() {
        let log = MAGLogger.self
        let logSender = MockLogSender()
        log.logSender = logSender
        // should not create a compile error relating autoclosure
        log.info("MY_TAG", instanceVar)
    }
    
    static var allTests = [
        ("testLoggingWithoutDestination", testLoggingWithoutDestination),
        ("testRemoveSender", testRemoveSender),
        ("testLogPassParameters", testLogPassParameters),
        ("testMessageType", testMessageType),
        ("testGetCorrectThread", testGetCorrectThread),
        ("testAutoClosure", testAutoClosure),
    ]
    
    private func currentThreadName() -> String {
        if Thread.isMainThread {
            return ""
        } else {
            let threadName = Thread.current.name
            if let threadName = threadName, !threadName.isEmpty {
                return threadName
            } else {
                return String(format: "%p", Thread.current)
            }
        }
    }
}


private class MockLogSender: MAGLogSender {
    
    var queue: DispatchQueue
    
    var didSendToLevel: MAGLogger.LogLevel?
    var didSendTag: String?
    var didSendMessage: String?
    var didSendToThread: String?
    var didSendFile: String?
    var didSendFunction: String?
    var didSendLine: Int?
    var didSendContext: (Any?)?
    var didSend: (()->Void)?
    
    public init() {
        queue = DispatchQueue.main
    }
    
    func send(_ level: MAGLogger.LogLevel, tag: String, msg: String, thread: String, file: String, function: String, line: Int, context: Any?) {
        didSendToLevel = level
        didSendTag = tag
        didSendMessage = msg
        didSendToThread = thread
        didSendFile = file
        didSendFunction = function
        didSendLine = line
        didSendContext = context
        
        didSend?()
    }

}
