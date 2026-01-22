import SwiftUI
#if os(iOS)
import SwiftTerm
import UIKit

/// Standalone test view for terminal rendering - NO SSH/TMUX CONNECTION
struct TestTerminalView: View {
    @State private var terminalController: TerminalViewController?
    
    var body: some View {
        ZStack {
            TerminalViewWrapper(terminalController: $terminalController)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Text("TEST MODE")
                        .font(.caption)
                        .foregroundColor(.yellow)
                        .padding(4)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(4)
                    Spacer()
                }
                .padding()
                Spacer()
            }
        }
        .onAppear {
            // Wait for terminal to initialize
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                feedTestPattern()
            }
        }
    }
    
    private func feedTestPattern() {
        guard let controller = terminalController else { return }
        
        // Get terminal dimensions
        #if os(iOS)
        if let termView = controller.terminalView as? SwiftTerm.TerminalView {
            let terminal = termView.getTerminal()
            let cols = terminal.cols
            
            var pattern = ""
            pattern += "TEST PATTERN - \(cols) columns\n"
            pattern += "="
            for _ in 1..<cols { pattern += "=" }
            pattern += "\n"
            
            // Ruler showing column numbers
            var ruler = ""
            for i in 1...cols {
                if i % 10 == 0 {
                    ruler += "\(i/10)"
                } else {
                    ruler += " "
                }
            }
            pattern += ruler + "\n"
            
            // Tick marks
            var ticks = ""
            for i in 1...cols {
                if i % 10 == 0 {
                    ticks += "|"
                } else if i % 5 == 0 {
                    ticks += ":"
                } else {
                    ticks += "."
                }
            }
            pattern += ticks + "\n"
            pattern += "\n"
            
            // Lines of repeating text to fill width
            for lineNum in 1...10 {
                var line = String(format: "%02d ", lineNum)
                let remaining = cols - line.count
                let chars = "ABCDEFGHIJ"
                for i in 0..<remaining {
                    line += String(chars[chars.index(chars.startIndex, offsetBy: i % chars.count)])
                }
                pattern += line + "\n"
            }
            
            pattern += "\nEND OF TEST PATTERN\n"
            
            controller.feed(text: pattern)
        }
        #endif
    }
}

/// Wrapper that creates terminal with fixed size
private struct TerminalViewWrapper: UIViewRepresentable {
    @Binding var terminalController: TerminalViewController?
    
    func makeUIView(context: Context) -> SwiftTerm.TerminalView {
        // Fixed 10pt font
        let font = UIFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        let termView = SwiftTerm.TerminalView(frame: .zero, font: font)
        termView.nativeForegroundColor = .white
        termView.nativeBackgroundColor = .black
        
        // NO horizontal scroll
        termView.showsHorizontalScrollIndicator = false
        termView.alwaysBounceHorizontal = false
        
        // Minimal accessory
        termView.inputAccessoryView = MinimalAccessory(height: 36)
        termView.inputView = nil
        
        // FORCE 40 columns × 24 rows
        let terminal = termView.getTerminal()
        terminal.resize(cols: 40, rows: 24)
        
        NSLog("🧪 TEST TERMINAL: Created with 40x24, font 10pt")
        
        // Create controller
        let controller = TerminalViewController(terminalView: termView)
        DispatchQueue.main.async {
            terminalController = controller
        }
        
        return termView
    }
    
    func updateUIView(_ uiView: SwiftTerm.TerminalView, context: Context) {
        // Keep size fixed
        let terminal = uiView.getTerminal()
        if terminal.cols != 40 || terminal.rows != 24 {
            terminal.resize(cols: 40, rows: 24)
        }
        uiView.contentOffset.x = 0
    }
}
#endif
