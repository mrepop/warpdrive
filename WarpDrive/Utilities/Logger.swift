import Foundation
import OSLog

/// Diagnostic logging utility for WarpDrive
/// Provides structured logging with categories for debugging
public enum LogCategory: String {
    case ssh = "SSH"
    case tmux = "TMUX"
    case terminal = "Terminal"
    case ui = "UI"
    case network = "Network"
    case general = "General"
}

public enum LogLevel {
    case debug
    case info
    case warning
    case error
}

public class WarpLogger {
    public static let shared = WarpLogger()
    
    private let subsystem = "com.warpdrive.app"
    private var loggers: [LogCategory: Logger] = [:]
    
    // In-memory log buffer for debugging
    private var logBuffer: [LogEntry] = []
    private let bufferLimit = 1000
    private let bufferQueue = DispatchQueue(label: "com.warpdrive.logger")
    
    public struct LogEntry {
        let timestamp: Date
        let category: LogCategory
        let level: LogLevel
        let message: String
        let file: String
        let function: String
        let line: Int
    }
    
    private init() {
        for category in [LogCategory.ssh, .tmux, .terminal, .ui, .network, .general] {
            loggers[category] = Logger(subsystem: subsystem, category: category.rawValue)
        }
    }
    
    public func log(_ message: String, 
                   category: LogCategory = .general,
                   level: LogLevel = .info,
                   file: String = #file,
                   function: String = #function,
                   line: Int = #line) {
        let entry = LogEntry(
            timestamp: Date(),
            category: category,
            level: level,
            message: message,
            file: (file as NSString).lastPathComponent,
            function: function,
            line: line
        )
        
        bufferQueue.async {
            self.logBuffer.append(entry)
            if self.logBuffer.count > self.bufferLimit {
                self.logBuffer.removeFirst()
            }
        }
        
        guard let logger = loggers[category] else { return }
        
        let logMessage = "[\(function):\(line)] \(message)"
        
        switch level {
        case .debug:
            logger.debug("\(logMessage)")
        case .info:
            logger.info("\(logMessage)")
        case .warning:
            logger.warning("\(logMessage)")
        case .error:
            logger.error("\(logMessage)")
        }
    }
    
    public func debug(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: category, level: .debug, file: file, function: function, line: line)
    }
    
    public func info(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: category, level: .info, file: file, function: function, line: line)
    }
    
    public func warning(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: category, level: .warning, file: file, function: function, line: line)
    }
    
    public func error(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: category, level: .error, file: file, function: function, line: line)
    }
    
    // Get recent logs for debugging UI
    public func getRecentLogs(limit: Int = 100) -> [LogEntry] {
        bufferQueue.sync {
            Array(logBuffer.suffix(limit))
        }
    }
    
    public func getLogsByCategory(_ category: LogCategory, limit: Int = 100) -> [LogEntry] {
        bufferQueue.sync {
            logBuffer.filter { $0.category == category }.suffix(limit)
        }
    }
    
    public func clearLogs() {
        bufferQueue.async {
            self.logBuffer.removeAll()
        }
    }
    
    // Export logs as string for sharing/debugging
    public func exportLogs() -> String {
        bufferQueue.sync {
            logBuffer.map { entry in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
                let timestamp = formatter.string(from: entry.timestamp)
                return "[\(timestamp)] [\(entry.category.rawValue)] [\(entry.level)] \(entry.file):\(entry.line) \(entry.function) - \(entry.message)"
            }.joined(separator: "\n")
        }
    }
}

// Convenience global functions
public func logDebug(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
    WarpLogger.shared.debug(message, category: category, file: file, function: function, line: line)
}

public func logInfo(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
    WarpLogger.shared.info(message, category: category, file: file, function: function, line: line)
}

public func logWarning(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
    WarpLogger.shared.warning(message, category: category, file: file, function: function, line: line)
}

public func logError(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
    WarpLogger.shared.error(message, category: category, file: file, function: function, line: line)
}
