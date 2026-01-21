import Foundation

// MARK: - SSH Connection Configuration

public struct SSHCredentials {
    public enum AuthMethod {
        case password(String)
        case publicKey(privateKeyPath: String, passphrase: String?)
        case agent
    }
    
    public let username: String
    public let authMethod: AuthMethod
    
    public init(username: String, authMethod: AuthMethod) {
        self.username = username
        self.authMethod = authMethod
    }
}

public struct SSHConnectionConfig {
    public let host: String
    public let port: Int
    public let credentials: SSHCredentials
    public let timeout: TimeInterval
    
    public init(host: String,
                port: Int = 22,
                credentials: SSHCredentials,
                timeout: TimeInterval = 30) {
        self.host = host
        self.port = port
        self.credentials = credentials
        self.timeout = timeout
    }
}

// MARK: - SSH Errors

public enum SSHError: Error, LocalizedError {
    case connectionFailed(String)
    case authenticationFailed(String)
    case channelCreationFailed(String)
    case commandExecutionFailed(String)
    case disconnected(String)
    case timeout
    case invalidConfiguration(String)
    case dataEncodingError
    case unknownError(String)
    
    public var errorDescription: String? {
        switch self {
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .channelCreationFailed(let message):
            return "Channel creation failed: \(message)"
        case .commandExecutionFailed(let message):
            return "Command execution failed: \(message)"
        case .disconnected(let message):
            return "Disconnected: \(message)"
        case .timeout:
            return "Connection timed out"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        case .dataEncodingError:
            return "Data encoding error"
        case .unknownError(let message):
            return "Unknown error: \(message)"
        }
    }
}

// MARK: - SSH Connection State

public enum SSHConnectionState {
    case disconnected
    case connecting
    case authenticating
    case connected
    case error(Error)
    
    public var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }
    
    public var description: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .authenticating:
            return "Authenticating..."
        case .connected:
            return "Connected"
        case .error(let error):
            return "Error: \(error.localizedDescription)"
        }
    }
}
