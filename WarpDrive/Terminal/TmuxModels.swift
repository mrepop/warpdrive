import Foundation

// MARK: - Tmux Session

public struct TmuxSession: Identifiable, Codable {
    public let id: String  // Session name
    public let name: String
    public let created: Date?
    public let attached: Bool
    public let windows: Int
    
    public init(id: String, name: String, created: Date? = nil, attached: Bool = false, windows: Int = 1) {
        self.id = id
        self.name = name
        self.created = created
        self.attached = attached
        self.windows = windows
    }
}

// MARK: - Tmux Window

public struct TmuxWindow: Identifiable {
    public let id: String  // Window index
    public let name: String
    public let sessionId: String
    public let active: Bool
    
    public init(id: String, name: String, sessionId: String, active: Bool = false) {
        self.id = id
        self.name = name
        self.sessionId = sessionId
        self.active = active
    }
}

// MARK: - Tmux Control Mode Protocol

/// Represents messages from tmux control mode
public enum TmuxControlMessage {
    case sessionChanged(sessionId: String, sessionName: String)
    case windowAdd(window: TmuxWindow)
    case windowClose(windowId: String)
    case output(windowId: String, data: String)
    case layoutChange(windowId: String)
    case sessionCreated(session: TmuxSession)
    case sessionClosed(sessionId: String)
    case begin
    case end
    case error(String)
    case unknown(String)
    
    /// Parse a line from tmux control mode
    public static func parse(_ line: String) -> TmuxControlMessage {
        logDebug("Parsing tmux control line: \(line)", category: .tmux)
        
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Messages start with %
        guard trimmed.hasPrefix("%") else {
            return .unknown(line)
        }
        
        let parts = trimmed.dropFirst().split(separator: " ", maxSplits: 1)
        guard let command = parts.first else {
            return .unknown(line)
        }
        
        let args = parts.count > 1 ? String(parts[1]) : ""
        
        switch command {
        case "begin":
            return .begin
            
        case "end":
            return .end
            
        case "session-changed":
            // Format: %session-changed $session_id $session_name
            let sessionParts = args.split(separator: " ", maxSplits: 1)
            if sessionParts.count >= 2 {
                return .sessionChanged(sessionId: String(sessionParts[0]),
                                     sessionName: String(sessionParts[1]))
            }
            return .unknown(line)
            
        case "output":
            // Format: %output %window_id content
            let outputParts = args.split(separator: " ", maxSplits: 1)
            if outputParts.count >= 2 {
                let windowId = String(outputParts[0])
                let data = String(outputParts[1])
                return .output(windowId: windowId, data: data)
            }
            return .unknown(line)
            
        case "window-add":
            // Format: %window-add @window_id
            if args.hasPrefix("@") {
                let windowId = String(args.dropFirst())
                let window = TmuxWindow(id: windowId, name: "Window \(windowId)",
                                       sessionId: "", active: false)
                return .windowAdd(window: window)
            }
            return .unknown(line)
            
        case "window-close":
            // Format: %window-close @window_id
            if args.hasPrefix("@") {
                let windowId = String(args.dropFirst())
                return .windowClose(windowId: windowId)
            }
            return .unknown(line)
            
        case "layout-change":
            // Format: %layout-change @window_id ...
            if args.hasPrefix("@") {
                let windowId = String(args.split(separator: " ")[0].dropFirst())
                return .layoutChange(windowId: windowId)
            }
            return .unknown(line)
            
        case "session-created":
            let sessionId = args
            let session = TmuxSession(id: sessionId, name: sessionId)
            return .sessionCreated(session: session)
            
        case "session-closed":
            return .sessionClosed(sessionId: args)
            
        case "error":
            return .error(args)
            
        default:
            logDebug("Unknown tmux control command: \(command)", category: .tmux)
            return .unknown(line)
        }
    }
}

// MARK: - Tmux Errors

public enum TmuxError: Error, LocalizedError {
    case notInstalled
    case sessionNotFound(String)
    case commandFailed(String)
    case parsingError(String)
    case invalidResponse(String)
    
    public var errorDescription: String? {
        switch self {
        case .notInstalled:
            return "tmux is not installed"
        case .sessionNotFound(let name):
            return "Session '\(name)' not found"
        case .commandFailed(let message):
            return "tmux command failed: \(message)"
        case .parsingError(let message):
            return "Failed to parse tmux output: \(message)"
        case .invalidResponse(let message):
            return "Invalid tmux response: \(message)"
        }
    }
}
