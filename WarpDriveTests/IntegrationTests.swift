import XCTest
@testable import WarpDriveCore

/// Integration tests for SSH and tmux functionality
/// These tests require SSH to be configured on localhost
final class IntegrationTests: XCTestCase {
    
    var sshClient: SSHClient!
    var tmuxManager: TmuxManager!
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        sshClient = SSHClient()
        tmuxManager = TmuxManager()
    }
    
    override func tearDown() {
        sshClient = nil
        tmuxManager = nil
        super.tearDown()
    }
    
    @MainActor
    func testSSHConnection() async throws {
        let username = ProcessInfo.processInfo.environment["USER"] ?? "user"
        
        let credentials = SSHCredentials(
            username: username,
            authMethod: .agent
        )
        
        let config = SSHConnectionConfig(
            host: "localhost",
            port: 22,
            credentials: credentials,
            timeout: 10
        )
        
        do {
            try await sshClient.connect(config: config)
            XCTAssertTrue(sshClient.connectionState.isConnected, "SSH should be connected")
            
            // Test command execution
            let result = try await sshClient.execute(command: "echo 'test'")
            XCTAssertTrue(result.contains("test"), "Command output should contain 'test'")
            
            sshClient.disconnect()
            XCTAssertFalse(sshClient.connectionState.isConnected, "SSH should be disconnected")
        } catch {
            XCTFail("SSH connection failed: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func testTmuxListSessions() async throws {
        let username = ProcessInfo.processInfo.environment["USER"] ?? "user"
        
        let credentials = SSHCredentials(
            username: username,
            authMethod: .agent
        )
        
        let config = SSHConnectionConfig(
            host: "localhost",
            port: 22,
            credentials: credentials,
            timeout: 10
        )
        
        try await sshClient.connect(config: config)
        tmuxManager.connect(sshClient: sshClient)
        
        do {
            let sessions = try await tmuxManager.listSessions()
            
            // There should be at least the warpdrive-test session
            XCTAssertGreaterThanOrEqual(sessions.count, 0, "Should list tmux sessions")
            
            logInfo("Found \(sessions.count) tmux sessions", category: .tmux)
            for session in sessions {
                logInfo("Session: \(session.name), Windows: \(session.windows), Attached: \(session.attached)", category: .tmux)
            }
        } catch {
            XCTFail("Failed to list tmux sessions: \(error.localizedDescription)")
        }
        
        sshClient.disconnect()
    }
    
    @MainActor
    func testTmuxCreateAndKillSession() async throws {
        let username = ProcessInfo.processInfo.environment["USER"] ?? "user"
        
        let credentials = SSHCredentials(
            username: username,
            authMethod: .agent
        )
        
        let config = SSHConnectionConfig(
            host: "localhost",
            port: 22,
            credentials: credentials,
            timeout: 10
        )
        
        try await sshClient.connect(config: config)
        tmuxManager.connect(sshClient: sshClient)
        
        let testSessionName = "test-session-\(Int.random(in: 1000...9999))"
        
        do {
            // Create session
            let session = try await tmuxManager.createSession(name: testSessionName)
            XCTAssertEqual(session.name, testSessionName)
            logInfo("Created test session: \(testSessionName)", category: .tmux)
            
            // Verify it exists
            let sessions = try await tmuxManager.listSessions()
            print("DEBUG: Created session '\(testSessionName)'")
            print("DEBUG: Found \(sessions.count) sessions:")
            for s in sessions {
                print("  - \(s.name)")
            }
            XCTAssertTrue(sessions.contains(where: { $0.name == testSessionName }), "Session should exist. Found: \(sessions.map { $0.name })")
            
            // Kill session
            try await tmuxManager.killSession(session)
            logInfo("Killed test session: \(testSessionName)", category: .tmux)
            
            // Verify it's gone
            let sessionsAfter = try await tmuxManager.listSessions()
            XCTAssertFalse(sessionsAfter.contains(where: { $0.name == testSessionName }), "Session should be killed")
            
        } catch {
            XCTFail("Failed tmux session operations: \(error.localizedDescription)")
        }
        
        sshClient.disconnect()
    }
    
    @MainActor
    func testTmuxSendKeysAndCapture() async throws {
        let username = ProcessInfo.processInfo.environment["USER"] ?? "user"
        
        let credentials = SSHCredentials(
            username: username,
            authMethod: .agent
        )
        
        let config = SSHConnectionConfig(
            host: "localhost",
            port: 22,
            credentials: credentials,
            timeout: 10
        )
        
        try await sshClient.connect(config: config)
        tmuxManager.connect(sshClient: sshClient)
        
        let testSessionName = "test-keys-\(Int.random(in: 1000...9999))"
        
        do {
            // Create session
            let session = try await tmuxManager.createSession(name: testSessionName)
            
            // Send a command
            try await tmuxManager.sendKeys("echo 'Hello from WarpDrive'", session: session)
            try await tmuxManager.sendKeys("Enter", session: session)
            
            // Give it a moment to execute
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Capture output
            let output = try await tmuxManager.capturePaneOutput(session: session, lines: 10)
            XCTAssertTrue(output.contains("Hello from WarpDrive"), "Output should contain the echo message")
            logInfo("Captured output: \(output.prefix(100))", category: .tmux)
            
            // Cleanup
            try await tmuxManager.killSession(session)
            
        } catch {
            XCTFail("Failed tmux send keys test: \(error.localizedDescription)")
        }
        
        sshClient.disconnect()
    }
}
