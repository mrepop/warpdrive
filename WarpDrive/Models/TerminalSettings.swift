import SwiftUI
import Combine

/// Settings for terminal display configuration
class TerminalSettings: ObservableObject {
    /// Shared singleton instance
    static let shared = TerminalSettings()
    
    /// Font size for terminal text (default 10 for better phone display)
    @AppStorage("terminalFontSize") var fontSize: Double = 10.0
    
    /// Minimum allowed font size
    static let minFontSize: Double = 8.0
    
    /// Maximum allowed font size
    static let maxFontSize: Double = 24.0
    
    private init() {}
}
