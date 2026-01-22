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
    @ObservedObject var settings = TerminalSettings.shared

    func makeCoordinator() -> Coordinator { Coordinator(self) }

final class Coordinator: NSObject {
        var parent: TerminalView
        private var lastBounds: CGRect = .zero
        init(_ parent: TerminalView) { self.parent = parent }

        func resizeTerminalIfNeeded(_ uiView: NativeTerminalView) {
            let terminal = uiView.getTerminal()
            
            // HARDCODE small column count to test if mechanism works
            let targetCols = 40  // Small enough to definitely fit
            let targetRows = 20
            
            let currentCols = terminal.cols
            let currentRows = terminal.rows
            
            NSLog("📐 resizeTerminalIfNeeded called: current=\(currentCols)x\(currentRows) target=\(targetCols)x\(targetRows)")
            
            if targetCols != currentCols || targetRows != currentRows {
                NSLog("📐 RESIZING terminal now")
                terminal.resize(cols: targetCols, rows: targetRows)
                NSLog("📐 After resize: \(terminal.cols)x\(terminal.rows)")
                
                // Flash background blue briefly to show resize happened
                uiView.nativeBackgroundColor = UIColor.blue
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    uiView.nativeBackgroundColor = .black
                }
            }
            
            // Always clamp horizontal scroll
            uiView.contentOffset.x = 0
        }

        @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
            guard parent.settings.pinchZoomEnabled else { return }
            if recognizer.state == .changed || recognizer.state == .ended {
                let current = parent.settings.fontSize
                // scale delta, clamp
                let scaled = max(TerminalSettings.minFontSize, min(TerminalSettings.maxFontSize, current * Double(recognizer.scale)))
                parent.settings.fontSize = scaled
                // turn off fit-to-width once user pinches
                parent.settings.fitToWidthEnabled = false
                recognizer.scale = 1.0
            }
        }
    }
    
    func makeUIView(context: Context) -> NativeTerminalView {
        NSLog("🖥️ 🖥️ 🖥️ makeUIView CALLED 🖥️ 🖥️ 🖥️")
        print("🖥️ Creating TerminalView with frame: .zero, fontSize: \(settings.fontSize)")
        
        // Create terminal with custom font size
        let font = UIFont.monospacedSystemFont(ofSize: settings.fontSize, weight: .regular)
        let termView = NativeTerminalView(frame: .zero, font: font)
        termView.nativeForegroundColor = .white
        termView.nativeBackgroundColor = .black

        // Clamp horizontal scrolling artifacts
        termView.showsHorizontalScrollIndicator = false
        termView.alwaysBounceHorizontal = false
        termView.isDirectionalLockEnabled = true

        // Pinch-to-zoom recognizer
        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        termView.addGestureRecognizer(pinch)
        
        // Replace SwiftTerm's TerminalAccessory with a minimal accessory (no keyboard toggle)
        termView.inputAccessoryView = MinimalAccessory(height: 36)
        
        // Ensure system keyboard (no custom inputView)
        termView.inputView = nil
        
        // Make terminal view first responder
        DispatchQueue.main.async { termView.becomeFirstResponder() }
        
print("🖥️ TerminalView created, bounds: \(termView.bounds)")
        
if DebugConfig.fitDebug {
            let label = UILabel(frame: CGRect(x: 10, y: 60, width: 380, height: 52))
            label.tag = 4242
            label.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .bold)
            label.textColor = .black
            label.backgroundColor = UIColor.yellow.withAlphaComponent(0.95)
            label.numberOfLines = 3
            label.isUserInteractionEnabled = false
            label.layer.zPosition = 10000
            label.layer.cornerRadius = 6
            label.clipsToBounds = true
            label.autoresizingMask = [.flexibleRightMargin, .flexibleBottomMargin]
            label.text = "FIT DEBUG\nInitializing..."
            termView.addSubview(label)
            
            // Continuous update timer for HUD + background color indicator
            Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
                guard let label = termView.viewWithTag(4242) as? UILabel else { return }
                termView.bringSubviewToFront(label)
                let info = String(format: "FIT vW:%.0f cW:%.0f\npt:%.1f x:%.1f", 
                                  termView.bounds.width, termView.contentSize.width,
                                  termView.font.pointSize, termView.contentOffset.x)
                label.text = info
                
                // Visual indicator: background flashes red if horizontal scroll detected
                if termView.contentOffset.x > 1 {
                    termView.nativeBackgroundColor = UIColor(red: 0.2, green: 0, blue: 0, alpha: 1.0)
                } else {
                    termView.nativeBackgroundColor = .black
                }
            }
        }
        
        // FORCE IMMEDIATE RESIZE to 40 columns
        NSLog("🖥️ About to force resize in makeUIView")
        let terminal = termView.getTerminal()
        NSLog("🖥️ Terminal before resize: \(terminal.cols)x\(terminal.rows)")
        terminal.resize(cols: 40, rows: 20)
        NSLog("🖥️ Terminal after resize: \(terminal.cols)x\(terminal.rows)")
        
        // INJECT MASSIVE TEST PATTERN - repeat many times so it can't be missed
        var testPattern = ""
        for rep in 1...20 {
            testPattern += "========== TEST PATTERN #\(rep) - 40 cols ==========\n"
            testPattern += "    1    1    2    2    3    3    4    4\n"
            testPattern += "....:....|....:....|....:....|....:....|\n"
            for i in 1...3 {
                testPattern += String(format: "%02d ", i)
                let pattern = "ABCDEFGHIJ"
                for j in 0..<37 {
                    testPattern += String(pattern[pattern.index(pattern.startIndex, offsetBy: j % pattern.count)])
                }
                testPattern += "\n"
            }
        }
        testPattern += "========== END OF TEST ===========\n"
        NSLog("🖥️ Injecting MASSIVE test pattern (\(testPattern.count) chars)...")
        terminal.feed(text: testPattern)
        NSLog("🖥️ Test pattern injected - should be visible now!")
        
        // Create controller
        let controller = TerminalViewController(terminalView: termView)
        print("🖥️ TerminalViewController created")
        print("🖥️ inputView after init: \(termView.inputView == nil ? "nil" : "NOT NIL")")
        print("🖥️ inputAccessoryView: \(termView.inputAccessoryView == nil ? "nil" : "NOT NIL")")
        
        // Update binding
        DispatchQueue.main.async {
            terminalController = controller
            print("🖥️ Terminal controller bound")
            print("🖥️ inputView in async: \(termView.inputView == nil ? "nil" : "NOT NIL")")
            
            // Force reset inputView one more time after everything is set up
            if termView.inputView != nil {
                print("🖥️ FORCING inputView to nil after setup")
                termView.inputView = nil
                termView.reloadInputViews()
            }
        }
        
        return termView
    }
    
    private func charWidth(for font: UIFont) -> CGFloat {
        let test = "W"
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let size = (test as NSString).size(withAttributes: attributes)
        return size.width
    }

    func updateUIView(_ uiView: NativeTerminalView, context: Context) {
print("🖥️ updateUIView called, bounds: \(uiView.bounds)")
        
        // Resize terminal to fit current bounds
        context.coordinator.resizeTerminalIfNeeded(uiView)
        
        // CRITICAL: Force standard iOS keyboard (not SwiftTerm's custom KeyboardView)
        if uiView.inputView != nil {
print("🖥️ FORCING inputView back to nil (was: \(type(of: uiView.inputView!)))")
            uiView.inputView = nil
            if uiView.isFirstResponder {
                uiView.resignFirstResponder()
                DispatchQueue.main.async {
                    uiView.becomeFirstResponder()
                }
            }
        }
        
        // Update font if settings changed and not in fit-to-width mode
        let currentFontSize = uiView.font.pointSize
        if !settings.fitToWidthEnabled && abs(currentFontSize - settings.fontSize) > 0.1 {
print("🖥️ Updating font size from \(currentFontSize) to \(settings.fontSize)")
            let newFont = UIFont.monospacedSystemFont(ofSize: settings.fontSize, weight: .regular)
            uiView.font = newFont
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
