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
    static let maxFontSize: Double = 28.0
    
    /// Auto-hide keyboard accessory when not in use (default true for more screen space)
    @AppStorage("keyboardAutoHide") var keyboardAutoHide: Bool = true

    /// Fit-to-width mode: compute font so exactly `fitColumns` columns fit the width
    @AppStorage("fitToWidthEnabled") var fitToWidthEnabled: Bool = true

    /// Target columns for fit-to-width (80 or 100 typically)
    @AppStorage("fitColumns") var fitColumns: Int = 80

    /// Enable pinch-to-zoom on terminal
    @AppStorage("pinchZoomEnabled") var pinchZoomEnabled: Bool = true
    
    private init() {}
}
