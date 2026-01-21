import XCTest
@testable import WarpDriveCore

/// Tests for iOS SSH client implementation using Citadel
/// Note: These tests require an SSH server running on localhost with password authentication enabled
final class IOSSSHClientTests: XCTestCase {
    
    var sshClient: SSHClient!
    
    override func setUp() async throws {
        try await super.setUp()
        sshClient = await SSHClient()
    }
    
    override func tearDown() async throws {
        if sshClient != nil {
            await sshClient.disconnect()
        }
        try await super.tearDown()
    }
    
    // Test basic SSH connection with password auth
    func testSSHConnectionWithPassword() async throws {
        #if os(iOS)
        // Get username from environment
        let username = ProcessInfo.processInfo.environment["USER"] ?? "test"
        
        // Note: This test requires SSH server to accept password auth
        // For testing, you need to provide a valid password
        let password = ProcessInfo.processInfo.environment["TEST_SSH_PASSWORD"] ?? ""
        
        guard !password.isEmpty else {
            throw XCTestSkip("Skipping test: TEST_SSH_PASSWORD environment variable not set")
        }
        
        let credentials = SSHCredentials(
            username: username,
            authMethod: .password(password)
        )
        
        let config = SSHConnectionConfig(
            host: "localhost",
            port: 22,
            credentials: credentials
        )
        
        // Test connection
        try await sshClient.connect(config: config)
        
        // Verify connection state
        let state = await sshClient.connectionState
        XCTAssertTrue(state.isConnected, "SSH client should be connected")
        #else
        throw XCTestSkip("This test is only for iOS")
        #endif
    }
    
    // Test command execution via iOS SSH
    func testCommandExecution() async throws {
        #if os(iOS)
        let username = ProcessInfo.processInfo.environment["USER"] ?? "test"
        let password = ProcessInfo.processInfo.environment["TEST_SSH_PASSWORD"] ?? ""
        
        guard !password.isEmpty else {
            throw XCTestSkip("Skipping test: TEST_SSH_PASSWORD environment variable not set")
        }
        
        let credentials = SSHCredentials(
            username: username,
            authMethod: .password(password)
        )
        
        let config = SSHConnectionConfig(
            host: "localhost",
            port: 22,
            credentials: credentials
        )
        
        try await sshClient.connect(config: config)
        
        // Execute a simple command
        let result = try await sshClient.execute(command: "echo 'test'")
        
        XCTAssertTrue(result.contains("test"), "Command output should contain 'test'")
        #else
        throw XCTestSkip("This test is only for iOS")
        #endif
    }
    
    // Test that agent auth throws appropriate error on iOS
    func testAgentAuthNotSupported() async throws {
        #if os(iOS)
        let username = ProcessInfo.processInfo.environment["USER"] ?? "test"
        
        let credentials = SSHCredentials(
            username: username,
            authMethod: .agent
        )
        
        let config = SSHConnectionConfig(
            host: "localhost",
            port: 22,
            credentials: credentials
        )
        
        // Should throw error about agent auth not implemented
        do {
            try await sshClient.connect(config: config)
            XCTFail("Should have thrown error for agent auth on iOS")
        } catch let error as SSHError {
            switch error {
            case .authenticationFailed(let message):
                XCTAssertTrue(message.contains("not yet implemented"), 
                             "Error should mention auth not implemented")
            default:
                XCTFail("Wrong error type: \(error)")
            }
        }
        #else
        throw XCTestSkip("This test is only for iOS")
        #endif
    }
    
    // Test tmux command execution
    func testTmuxCommandExecution() async throws {
        #if os(iOS)
        let username = ProcessInfo.processInfo.environment["USER"] ?? "test"
        let password = ProcessInfo.processInfo.environment["TEST_SSH_PASSWORD"] ?? ""
        
        guard !password.isEmpty else {
            throw XCTestSkip("Skipping test: TEST_SSH_PASSWORD environment variable not set")
        }
        
        let credentials = SSHCredentials(
            username: username,
            authMethod: .password(password)
        )
        
        let config = SSHConnectionConfig(
            host: "localhost",
            port: 22,
            credentials: credentials
        )
        
        try await sshClient.connect(config: config)
        
        // Try to list tmux sessions (using full path since it might not be in PATH)
        let result = try await sshClient.execute(command: "/opt/homebrew/bin/tmux ls 2>&1 || echo 'no sessions'")
        
        // Should either list sessions or say "no sessions"
        XCTAssertFalse(result.isEmpty, "Command should return output")
        #else
        throw XCTestSkip("This test is only for iOS")
        #endif
    }
}
