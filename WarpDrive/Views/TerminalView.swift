import SwiftUI
import SwiftTerm

/// Typealias to avoid naming conflicts with SwiftUI wrapper
#if os(iOS)
import UIKit
typealias NativeTerminalView = SwiftTerm.TerminalView
#elseif os(macOS)
import AppKit
typealias NativeTerminalView = LocalProcessTerminalView
#endif

/// Controller for managing terminal state and I/O (shared across platforms)
class TerminalViewController: ObservableObject {
    let terminalView: NativeTerminalView
    private var terminal: Terminal
    
    init(terminalView: NativeTerminalView) {
        self.terminalView = terminalView
        self.terminal = terminalView.getTerminal()
    }
    
    /// Feed output data to the terminal
    func feed(text: String) {
        terminal.feed(text: text)
    }
    
    /// Feed output data to the terminal
    func feed(data: Data) {
        terminal.feed(byteArray: [UInt8](data))
    }
    
    /// Clear the terminal display
    func clear() {
        terminal.resetNormalBuffer()
    }
    
    /// Reset the terminal to initial state
    func reset() {
        terminal.setup(isReset: true)
    }
    
    /// Get selected text from terminal
    func getSelectedText() -> String? {
        return terminalView.getSelection()
    }
    
    /// Resize terminal to given dimensions
    func resize(cols: Int, rows: Int) {
        terminal.resize(cols: cols, rows: rows)
    }
}

#if os(iOS)
/// SwiftUI wrapper for SwiftTerm's TerminalView on iOS
struct TerminalView: UIViewRepresentable {
    @Binding var terminalController: TerminalViewController?
    
    func makeUIView(context: Context) -> NativeTerminalView {
        print("🖥️ Creating TerminalView with frame: .zero")
        let termView = NativeTerminalView(frame: .zero)
        termView.nativeForegroundColor = .white
        termView.nativeBackgroundColor = .black
        print("🖥️ TerminalView created, bounds: \(termView.bounds)")
        
        // Create controller
        let controller = TerminalViewController(terminalView: termView)
        print("🖥️ TerminalViewController created")
        
        // Update binding
        DispatchQueue.main.async {
            terminalController = controller
            print("🖥️ Terminal controller bound")
        }
        
        return termView
    }
    
    func updateUIView(_ uiView: NativeTerminalView, context: Context) {
        // Update display when size changes
        print("🖥️ updateUIView called, bounds: \(uiView.bounds)")
        if uiView.bounds.size != .zero {
            print("🖥️ Triggering display update")
            uiView.setNeedsDisplay()
        }
    }
}

#elseif os(macOS)
/// SwiftUI wrapper for SwiftTerm's TerminalView on macOS
struct TerminalView: NSViewRepresentable {
    @Binding var terminalController: TerminalViewController?
    
    func makeNSView(context: Context) -> NativeTerminalView {
        let termView = NativeTerminalView(frame: .zero)
        
        // Create controller
        let controller = TerminalViewController(terminalView: termView)
        
        // Update binding
        DispatchQueue.main.async {
            terminalController = controller
        }
        
        return termView
    }
    
    func updateNSView(_ nsView: NativeTerminalView, context: Context) {
        // No updates needed
    }
}
#endif
