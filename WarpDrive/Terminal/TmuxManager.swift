import Foundation
import Combine

/// Manages tmux sessions via SSH connection
@MainActor
public class TmuxManager: ObservableObject {
    @Published public private(set) var sessions: [TmuxSession] = []
    @Published public private(set) var currentSession: TmuxSession?
    @Published public private(set) var isConnected: Bool = false
    
    private var sshClient: SSHClient?
    private var cancellables = Set<AnyCancellable>()
    private var tmuxPath: String = "tmux"
    
    public init() {
        logInfo("TmuxManager initialized", category: .tmux)
    }
    
    // MARK: - Connection
    
    public func connect(sshClient: SSHClient) {
        self.sshClient = sshClient
        isConnected = sshClient.connectionState.isConnected
        
        logInfo("TmuxManager connected to SSH client", category: .tmux)
    }
    
    public func disconnect() {
        sshClient = nil
        isConnected = false
        sessions = []
        currentSession = nil
        
        logInfo("TmuxManager disconnected", category: .tmux)
    }
    
    // MARK: - Session Management
    
    /// List all available tmux sessions
    public func listSessions() async throws -> [TmuxSession] {
        logInfo("Listing tmux sessions", category: .tmux)
        
        guard let client = sshClient else {
            throw TmuxError.commandFailed("Not connected to SSH")
        }
        
        // Check if tmux is installed - try common paths
        let tmuxPaths = ["/opt/homebrew/bin/tmux", "/usr/local/bin/tmux", "/usr/bin/tmux", "tmux"]
        var foundPath: String?
        
        for path in tmuxPaths {
            do {
                _ = try await client.execute(command: "\(path) -V 2>/dev/null")
                foundPath = path
                logInfo("Found tmux at: \(path)", category: .tmux)
                break
            } catch {
                continue
            }
        }
        
        guard let tmuxPath = foundPath else {
            logError("tmux not found on remote host", category: .tmux)
            throw TmuxError.notInstalled
        }
        
        self.tmuxPath = tmuxPath
        
        // List sessions with format
        let output = try await client.execute(command: "\(tmuxPath) list-sessions -F '#{session_name}|#{session_created}|#{session_attached}|#{session_windows}' 2>/dev/null || echo ''")
        
        logDebug("tmux list-sessions output: \(output)", category: .tmux)
        
        let sessions = try parseSessions(from: output)
        self.sessions = sessions
        
        logInfo("Found \(sessions.count) tmux sessions", category: .tmux)
        return sessions
    }
    
    /// Create a new tmux session
    public func createSession(name: String) async throws -> TmuxSession {
        logInfo("Creating tmux session: \(name)", category: .tmux)
        
        guard let client = sshClient else {
            throw TmuxError.commandFailed("Not connected to SSH")
        }
        
        // Create detached session
        _ = try await client.execute(command: "\(tmuxPath) new-session -d -s '\(name)'")
        
        let session = TmuxSession(id: name, name: name, created: Date(), attached: false, windows: 1)
        
        // Refresh session list
        _ = try await listSessions()
        
        logInfo("Created tmux session: \(name)", category: .tmux)
        return session
    }
    
    /// Attach to a tmux session in control mode
    public func attachSession(_ session: TmuxSession) async throws {
        logInfo("Attaching to tmux session: \(session.name)", category: .tmux)
        
        guard let client = sshClient else {
            throw TmuxError.commandFailed("Not connected to SSH")
        }
        
        // Attach to session in control mode
        // This will give us a persistent connection to the session
        let command = "tmux attach-session -t '\(session.name)'"
        
        logDebug("Executing: \(command)", category: .tmux)
        
        currentSession = session
        
        // Note: For now, we'll just verify the session exists
        // Full control mode implementation will come in the interactive terminal
        _ = try await client.execute(command: "\(tmuxPath) has-session -t '\(session.name)'")
        
        logInfo("Successfully attached to session: \(session.name)", category: .tmux)
    }
    
    /// Detach from current session
    public func detachSession() async throws {
        guard let session = currentSession else {
            return
        }
        
        logInfo("Detaching from session: \(session.name)", category: .tmux)
        
        guard let client = sshClient else {
            throw TmuxError.commandFailed("Not connected to SSH")
        }
        
        _ = try await client.execute(command: "\(tmuxPath) detach-client")
        currentSession = nil
        
        logInfo("Detached from session", category: .tmux)
    }
    
    /// Kill a tmux session
    public func killSession(_ session: TmuxSession) async throws {
        logInfo("Killing tmux session: \(session.name)", category: .tmux)
        
        guard let client = sshClient else {
            throw TmuxError.commandFailed("Not connected to SSH")
        }
        
        _ = try await client.execute(command: "\(tmuxPath) kill-session -t '\(session.name)'")
        
        // Refresh session list
        _ = try await listSessions()
        
        if currentSession?.id == session.id {
            currentSession = nil
        }
        
        logInfo("Killed session: \(session.name)", category: .tmux)
    }
    
    /// Send a command to the current session
    public func sendKeys(_ keys: String, session: TmuxSession? = nil) async throws {
        let targetSession = session ?? currentSession
        
        guard let session = targetSession else {
            throw TmuxError.commandFailed("No active session")
        }
        
        guard let client = sshClient else {
            throw TmuxError.commandFailed("Not connected to SSH")
        }
        
        logDebug("Sending keys to session \(session.name): \(keys)", category: .tmux)
        
        // Escape single quotes in the keys
        let escapedKeys = keys.replacingOccurrences(of: "'", with: "'\\''")
        
        _ = try await client.execute(command: "\(tmuxPath) send-keys -t '\(session.name)' '\(escapedKeys)'")
    }
    
    /// Capture pane output from a session
    public func capturePaneOutput(session: TmuxSession, lines: Int = 100, cols: Int? = nil, rows: Int? = nil) async throws -> String {
        guard let client = sshClient else {
            throw TmuxError.commandFailed("Not connected to SSH")
        }
        
        logDebug("Capturing pane output from session: \(session.name)", category: .tmux)
        
        // Resize tmux pane to match terminal dimensions if provided
        if let cols = cols, let rows = rows {
            _ = try? await client.execute(command: "\(tmuxPath) resize-pane -t '\(session.name)' -x \(cols) -y \(rows)")
        }
        
        // Capture only visible pane without history to avoid column count rewrap issues
        let output = try await client.execute(command: "\(tmuxPath) capture-pane -t '\(session.name)' -p")
        
        return output
    }
    
    // MARK: - Private Helpers
    
    private func parseSessions(from output: String) throws -> [TmuxSession] {
        let lines = output.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var sessions: [TmuxSession] = []
        
        for line in lines {
            let parts = line.split(separator: "|")
            guard parts.count >= 4 else {
                logWarning("Skipping malformed session line: \(line)", category: .tmux)
                continue
            }
            
            let name = String(parts[0])
            let createdTimestamp = Int(parts[1]) ?? 0
            let attached = parts[2] == "1"
            let windowCount = Int(parts[3]) ?? 1
            
            let created = Date(timeIntervalSince1970: TimeInterval(createdTimestamp))
            
            let session = TmuxSession(
                id: name,
                name: name,
                created: created,
                attached: attached,
                windows: windowCount
            )
            
            sessions.append(session)
        }
        
        return sessions
    }
}
