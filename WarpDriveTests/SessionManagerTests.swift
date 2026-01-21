import XCTest
@testable import WarpDriveCore

final class SessionManagerTests: XCTestCase {
    var sessionManager: SessionManager!
    
    @MainActor
    override func setUp() {
        super.setUp()
        sessionManager = SessionManager()
    }
    
    override func tearDown() {
        sessionManager = nil
        super.tearDown()
    }
    
    @MainActor
    func testAddSession() {
        let session = Session(name: "Test Session", host: "localhost", port: 8080)
        sessionManager.addSession(session)
        
        XCTAssertEqual(sessionManager.sessions.count, 1)
        XCTAssertEqual(sessionManager.sessions.first?.name, "Test Session")
    }
    
    @MainActor
    func testRemoveSession() {
        let session = Session(name: "Test Session", host: "localhost", port: 8080)
        sessionManager.addSession(session)
        sessionManager.removeSession(session)
        
        XCTAssertEqual(sessionManager.sessions.count, 0)
    }
    
    @MainActor
    func testDisconnect() {
        sessionManager.disconnect()
        
        XCTAssertFalse(sessionManager.isConnected)
        XCTAssertNil(sessionManager.activeSession)
    }
}
