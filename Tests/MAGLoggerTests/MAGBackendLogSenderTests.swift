import XCTest
@testable import MAGLogger

final class MAGBackendLogSenderTests: XCTestCase {
    
    func testSendToInvalidServerAsync() {
        // invalid address
        let serverURL = URL(string: "https://foo.bar.com")!
        let logSender = MAGBackendLogSender(serverURL: serverURL)
        
        let exp = expectation(description: "returns false due to invalid URL")

        logSender.sendToServerAsync([:]) { ok in
            XCTAssertFalse(ok)
            exp.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    static var allTests = [
        ("testSendToInvalidServerAsync", testSendToInvalidServerAsync),
    ]
}
