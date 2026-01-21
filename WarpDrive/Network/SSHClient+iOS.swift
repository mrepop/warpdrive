import Foundation
import Combine
import Citadel

#if os(iOS)
// iOS-specific SSH implementation using Citadel (high-level wrapper over NIO-SSH)

extension SSHClient {
    // Private property to store the Citadel SSH client
    private static var citadelClient: Citadel.SSHClient?
    
    /// iOS implementation using Citadel
    func executeSSHCommand_iOS(config: SSHConnectionConfig, command: String) async throws -> String {
        logDebug("iOS SSH: Executing command: \(command)", category: .ssh)
        
        // Create or reuse SSH client
        let client = try await getOrCreateClient(config: config)
        
        // Execute command using Citadel - returns ByteBuffer
        let resultBuffer = try await client.executeCommand(command)
        
        // Convert ByteBuffer to String
        let result = resultBuffer.getString(at: resultBuffer.readerIndex, length: resultBuffer.readableBytes) ?? ""
        
        logDebug("iOS SSH: Command completed, output length: \(result.count)", category: .ssh)
        return result
    }
    
    private func getOrCreateClient(config: SSHConnectionConfig) async throws -> Citadel.SSHClient {
        // If we have an existing client, try to reuse it
        if let existingClient = Self.citadelClient {
            // TODO: Check if connection is still valid
            return existingClient
        }
        
        // Create authentication method
        let authMethod: SSHAuthenticationMethod
        
        switch config.credentials.authMethod {
        case .password(let password):
            authMethod = .passwordBased(username: config.credentials.username, password: password)
            
        case .publicKey(let keyPath, let passphrase):
            // For now, fall back to password - full key parsing would be implemented here
            logWarning("iOS SSH: Public key auth not fully implemented", category: .ssh)
            throw SSHError.authenticationFailed("Public key auth not yet implemented for iOS")
            
        case .agent:
            // Fall back to password for now
            logWarning("iOS SSH: Agent auth not fully implemented", category: .ssh)
            throw SSHError.authenticationFailed("Agent auth not yet implemented for iOS")
        }
        
        // Create client settings - authenticationMethod needs to be a closure
        let settings = SSHClientSettings(
            host: config.host,
            port: Int(config.port),
            authenticationMethod: { authMethod },
            hostKeyValidator: .acceptAnything() // For Phase 2 - should be made configurable
        )
        
        logInfo("iOS SSH: Connecting to \(config.host):\(config.port)", category: .ssh)
        let client = try await Citadel.SSHClient.connect(to: settings)
        
        Self.citadelClient = client
        return client
    }
    
    /// iOS-specific connection cleanup
    func cleanup_iOS() async {
        if let client = Self.citadelClient {
            logDebug("iOS SSH: Closing connection", category: .ssh)
            try? await client.close()
            Self.citadelClient = nil
        }
    }
}

#endif
