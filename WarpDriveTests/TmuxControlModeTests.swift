import XCTest
@testable import WarpDriveCore

final class TmuxControlModeTests: XCTestCase {
    
    func testParseBeginMessage() {
        let message = TmuxControlMessage.parse("%begin")
        
        if case .begin = message {
            // Success
        } else {
            XCTFail("Expected .begin, got \(message)")
        }
    }
    
    func testParseEndMessage() {
        let message = TmuxControlMessage.parse("%end")
        
        if case .end = message {
            // Success
        } else {
            XCTFail("Expected .end, got \(message)")
        }
    }
    
    func testParseSessionChangedMessage() {
        let message = TmuxControlMessage.parse("%session-changed $0 test-session")
        
        if case .sessionChanged(let sessionId, let sessionName) = message {
            XCTAssertEqual(sessionId, "$0")
            XCTAssertEqual(sessionName, "test-session")
        } else {
            XCTFail("Expected .sessionChanged, got \(message)")
        }
    }
    
    func testParseOutputMessage() {
        let message = TmuxControlMessage.parse("%output %0 test output data")
        
        if case .output(let windowId, let data) = message {
            XCTAssertEqual(windowId, "%0")
            XCTAssertEqual(data, "test output data")
        } else {
            XCTFail("Expected .output, got \(message)")
        }
    }
    
    func testParseWindowAddMessage() {
        let message = TmuxControlMessage.parse("%window-add @1")
        
        if case .windowAdd(let window) = message {
            XCTAssertEqual(window.id, "1")
        } else {
            XCTFail("Expected .windowAdd, got \(message)")
        }
    }
    
    func testParseWindowCloseMessage() {
        let message = TmuxControlMessage.parse("%window-close @1")
        
        if case .windowClose(let windowId) = message {
            XCTAssertEqual(windowId, "1")
        } else {
            XCTFail("Expected .windowClose, got \(message)")
        }
    }
    
    func testParseLayoutChangeMessage() {
        let message = TmuxControlMessage.parse("%layout-change @1 layout-info")
        
        if case .layoutChange(let windowId) = message {
            XCTAssertEqual(windowId, "1")
        } else {
            XCTFail("Expected .layoutChange, got \(message)")
        }
    }
    
    func testParseErrorMessage() {
        let message = TmuxControlMessage.parse("%error something went wrong")
        
        if case .error(let errorMsg) = message {
            XCTAssertEqual(errorMsg, "something went wrong")
        } else {
            XCTFail("Expected .error, got \(message)")
        }
    }
    
    func testParseUnknownMessage() {
        let message = TmuxControlMessage.parse("some random text")
        
        if case .unknown = message {
            // Success
        } else {
            XCTFail("Expected .unknown, got \(message)")
        }
    }
    
    func testParseUnknownControlMessage() {
        let message = TmuxControlMessage.parse("%unknown-command some data")
        
        if case .unknown = message {
            // Success
        } else {
            XCTFail("Expected .unknown, got \(message)")
        }
    }
}
