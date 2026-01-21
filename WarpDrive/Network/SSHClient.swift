import Foundation
import Combine

/// SSH Client for establishing connections and executing commands
/// Note: This is a simplified implementation for Phase 1
/// For iOS, we'll use a proper SSH library or framework
@MainActor
public class SSHClient: ObservableObject {
    @Published public private(set) var connectionState: SSHConnectionState = .disconnected
    @Published public private(set) var lastError: Error?
    
    private var config: SSHConnectionConfig?
    private var dataSubject = PassthroughSubject<Data, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    // For now, we'll use a simple process-based approach for macOS testing
    // In production iOS, we'd use a proper SSH library like NMSSH or libssh2
    private var sshProcess: Process?
    private var inputPipe: Pipe?
    private var outputPipe: Pipe?
    
    public init() {
        logInfo("SSHClient initialized", category: .ssh)
    }
    
    // MARK: - Connection Management
    
    public func connect(config: SSHConnectionConfig) async throws {
        logInfo("Attempting to connect to \(config.host):\(config.port)", category: .ssh)
        self.config = config
        
        connectionState = .connecting
        
        do {
            try await establishConnection(config: config)
            connectionState = .connected
            logInfo("Successfully connected to \(config.host)", category: .ssh)
        } catch {
            connectionState = .error(error)
            lastError = error
            logError("Connection failed: \(error.localizedDescription)", category: .ssh)
            throw error
        }
    }
    
    public func disconnect() {
        logInfo("Disconnecting from SSH", category: .ssh)
        
        sshProcess?.terminate()
        sshProcess = nil
        inputPipe = nil
        outputPipe = nil
        
        connectionState = .disconnected
    }
    
    // MARK: - Command Execution
    
    public func execute(command: String) async throws -> String {
        guard connectionState.isConnected else {
            throw SSHError.connectionFailed("Not connected")
        }
        
        logDebug("Executing command: \(command)", category: .ssh)
        
        // For phase 1, we'll use a simple approach
        // In production, this would be handled by the SSH session
        guard let config = config else {
            throw SSHError.invalidConfiguration("No configuration available")
        }
        
        let result = try await executeSSHCommand(config: config, command: command)
        logDebug("Command result: \(result.prefix(100))...", category: .ssh)
        return result
    }
    
    public func sendData(_ data: Data) throws {
        guard let pipe = inputPipe else {
            throw SSHError.connectionFailed("No input pipe available")
        }
        
        try pipe.fileHandleForWriting.write(contentsOf: data)
    }
    
    public func sendString(_ string: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw SSHError.dataEncodingError
        }
        try sendData(data)
    }
    
    // MARK: - Data Stream
    
    public var dataPublisher: AnyPublisher<Data, Never> {
        dataSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Helpers
    
    private func establishConnection(config: SSHConnectionConfig) async throws {
        // For phase 1 macOS testing, we'll validate connection with a simple command
        // In production iOS, this would establish a proper SSH session
        
        _ = try await executeSSHCommand(config: config, command: "echo 'connection_test'")
    }
    
    private func executeSSHCommand(config: SSHConnectionConfig, command: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
            
            var args = [
                "-o", "StrictHostKeyChecking=no",
                "-o", "UserKnownHostsFile=/dev/null",
                "-o", "ConnectTimeout=\(Int(config.timeout))",
                "-p", "\(config.port)",
            ]
            
            // Add authentication
            switch config.credentials.authMethod {
            case .password(_):
                // Note: ssh doesn't accept password via command line
                // For testing, we'll assume key-based auth is set up
                logWarning("Password auth not supported in current implementation", category: .ssh)
                continuation.resume(throwing: SSHError.authenticationFailed("Password auth requires sshpass or key-based auth"))
                return
                
            case .publicKey(let keyPath, _):
                args += ["-i", keyPath]
                
            case .agent:
                // Use SSH agent
                break
            }
            
            args.append("\(config.credentials.username)@\(config.host)")
            args.append(command)
            
            process.arguments = args
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                
                let output = String(data: outputData, encoding: .utf8) ?? ""
                let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
                
                if process.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    // Ignore known_hosts warnings
                    if errorOutput.contains("Permanently added") || errorOutput.contains("Warning:") {
                        logDebug("SSH warning (ignored): \(errorOutput)", category: .ssh)
                        continuation.resume(returning: output)
                    } else {
                        logError("SSH command failed: \(errorOutput)", category: .ssh)
                        continuation.resume(throwing: SSHError.commandExecutionFailed(errorOutput))
                    }
                }
            } catch {
                logError("Failed to execute SSH command: \(error)", category: .ssh)
                continuation.resume(throwing: SSHError.commandExecutionFailed(error.localizedDescription))
            }
        }
    }
}
