import Foundation
import Combine
import Citadel
import Crypto

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
            // Parse SSH private key file
            do {
                let keyData = try Data(contentsOf: URL(fileURLWithPath: keyPath))
                let keyString = String(data: keyData, encoding: .utf8) ?? ""
                
                // Try to parse the key based on format
                if keyString.contains("BEGIN OPENSSH PRIVATE KEY") || keyString.contains("BEGIN RSA PRIVATE KEY") {
                    // OpenSSH format RSA key
                    let privateKey = try Insecure.RSA.PrivateKey(sshRsa: keyString)
                    authMethod = .rsa(username: config.credentials.username, privateKey: privateKey)
                    logDebug("iOS SSH: Using RSA key authentication", category: .ssh)
                } else {
                    // TODO: Add support for Ed25519 and ECDSA keys
                    throw SSHError.authenticationFailed("Only RSA keys are currently supported. Ed25519/ECDSA support coming soon.")
                }
            } catch {
                logError("iOS SSH: Failed to load/parse private key: \(error)", category: .ssh)
                throw SSHError.authenticationFailed("Failed to load private key: \(error.localizedDescription)")
            }
            
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
        
        logInfo("iOS SSH: Connecting to \(config.host):\(config.port) as \(config.credentials.username)", category: .ssh)
        
        do {
            let client = try await Citadel.SSHClient.connect(to: settings)
            logInfo("iOS SSH: Connection established successfully", category: .ssh)
            Self.citadelClient = client
            return client
        } catch let error as SSHClientError {
            logError("iOS SSH: Citadel SSHClientError: \(error)", category: .ssh)
            switch error {
            case .unsupportedPasswordAuthentication:
                throw SSHError.authenticationFailed("Password authentication not supported by server")
            case .unsupportedPrivateKeyAuthentication:
                throw SSHError.authenticationFailed("Private key authentication not supported by server")
            case .unsupportedHostBasedAuthentication:
                throw SSHError.authenticationFailed("Host-based authentication not supported")
            case .allAuthenticationOptionsFailed:
                throw SSHError.authenticationFailed("All authentication methods failed - check username/password")
            case .channelCreationFailed:
                throw SSHError.channelCreationFailed("Failed to create SSH channel")
            }
        } catch {
            logError("iOS SSH: Connection failed with error: \(error)", category: .ssh)
            throw SSHError.connectionFailed(error.localizedDescription)
        }
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
