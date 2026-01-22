import SwiftUI
#if os(iOS)
import SwiftTerm
import UIKit
#endif

struct SessionDetailView: View {
    let session: TmuxSession
    @ObservedObject var tmuxManager: TmuxManager
    
    @State private var terminalController: TerminalViewController?
    @State private var isLoading = false
    @State private var autoRefreshTimer: Timer?
    @State private var showKeyboardAccessory = false
    @State private var debugInfo: String = "Init"
    // Bridge TextField state to force system QWERTY keyboard
    @State private var bridgeText: String = ""
    @FocusState private var bridgeFocused: Bool
    @ObservedObject var settings = TerminalSettings.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Full-screen terminal
            TerminalView(terminalController: $terminalController)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .edgesIgnoringSafeArea(.all)
            
            #if os(iOS)
            // Hidden bridge TextField to force the system QWERTY keyboard (debug-only)
            if DebugConfig.forceSoftwareKeyboard {
                VStack {
                    Spacer()
                    KeyboardBridgeView(
                        onText: { ch in
                            terminalController?.feed(text: ch)
                            Task { try? await tmuxManager.sendKeys(ch, session: session) }
                        },
                        onBackspace: {
                            terminalController?.feed(text: "\u{08} \u{08}")
                            Task { try? await tmuxManager.sendKeys("BSpace", session: session) }
                        }
                    )
                    .frame(width: 1, height: 1)
                    .opacity(0.01)
                }
            }
            
            // Keyboard accessory overlay (conditionally shown)
            if showKeyboardAccessory {
                VStack {
                    Spacer()
                    TerminalKeyboardAccessory { key in
                        handleTerminalKey(key)
                    }
                    .background(Color.black.opacity(0.9))
                }
                .transition(.move(edge: .bottom))
            }
            #endif
            
            // Debug overlay (only when forcing software keyboard)
            if DebugConfig.forceSoftwareKeyboard {
                VStack {
                    Text(debugInfo)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.yellow)
                        .padding(4)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(4)
                        .padding(.top, 50)
                    Spacer()
                }
            }
            
            // Real-time scroll offset monitor (always visible when fitDebug is on)
            if DebugConfig.fitDebug {
                VStack {
                    HStack {
                        Spacer()
                        ScrollOffsetMonitor(terminalController: $terminalController)
                            .padding(.top, 50)
                            .padding(.trailing, 10)
                    }
                    Spacer()
                }
            }
            
            // Floating menu button overlay (top-left)
            VStack {
                HStack {
                    Menu {
                        Button(action: copySelectedText) {
                            Label("Copy", systemImage: "doc.on.clipboard")
                        }
                        
                        Button(action: pasteText) {
                            Label("Paste", systemImage: "doc.on.clipboard.fill")
                        }
                        
                        Divider()
                        
                        Button(action: { showKeyboardAccessory.toggle() }) {
                            Label(showKeyboardAccessory ? "Hide Keys" : "Show Keys", 
                                  systemImage: showKeyboardAccessory ? "keyboard.chevron.compact.down" : "keyboard")
                        }
                        
                        Button(action: refreshOutput) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        
                        Button(action: clearTerminal) {
                            Label("Clear", systemImage: "trash")
                        }
                        
                        Divider()
                        
                        Button(action: { dismiss() }) {
                            Label("Close", systemImage: "xmark")
                        }
                        
                        Button(role: .destructive, action: killSession) {
                            Label("Kill Session", systemImage: "xmark.circle")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(12)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding()
                    
                    Spacer()
                }
                Spacer()
            }
        }
        .navigationBarHidden(true)
            .onAppear {
                // Check keyboard configuration
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let termView = terminalController?.terminalView as? SwiftTerm.TerminalView {
                        debugInfo = "keyboardType:\(termView.keyboardType.rawValue) autocap:\(termView.autocapitalizationType.rawValue)"
                    }
                }
                
                // Start keyboard state monitoring
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    if let termView = terminalController?.terminalView as? SwiftTerm.TerminalView {
                        let inputViewStatus = termView.inputView == nil ? "NIL" : "SET"
                        let accessoryStatus = termView.inputAccessoryView == nil ? "NIL" : "SET"
                        let responder = termView.isFirstResponder ? "YES" : "NO"
                        let kbType = termView.keyboardType.rawValue
                        debugInfo = "iV:\(inputViewStatus) acc:\(accessoryStatus) resp:\(responder) kbType:\(kbType)"
                    }
                }
            }
            .task {
                // Wait for terminal controller to be initialized
                var attempts = 0
                while terminalController == nil && attempts < 50 {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                    attempts += 1
                }
                
                if terminalController == nil {
                    print("📱 ERROR: Terminal controller never initialized after 5 seconds")
                } else {
                    print("📱 Terminal controller ready after \(attempts * 100)ms")
                    
                    // Force terminal to resize to fit current view bounds BEFORE loading content
                    #if os(iOS)
                    if let termView = terminalController?.terminalView as? SwiftTerm.TerminalView {
                        await MainActor.run {
                            termView.setNeedsLayout()
                            termView.layoutIfNeeded()
                        }
                        // Give layout a moment to complete
                        try? await Task.sleep(nanoseconds: 100_000_000)
                    }
                    #endif
                    
                    // DISABLED for test pattern visibility
                    // await loadOutput()
                    // startAutoRefresh()
                }
            }
    }
    
    private func loadOutput() async {
        isLoading = true
        print("📱 SessionDetailView: loadOutput started for session \(session.name)")
        print("📱 Terminal controller: \(terminalController != nil ? "exists" : "nil")")
        
        // Get current terminal dimensions
        var cols = 80
        var rows = 24
        #if os(iOS)
        if let termView = terminalController?.terminalView as? SwiftTerm.TerminalView {
            let terminal = termView.getTerminal()
            cols = terminal.cols
            rows = terminal.rows
        }
        #endif
        
        NSLog("📱 Terminal dimensions: %dx%d", cols, rows)
        NSLog("📱 FORCING TEST PATTERN MODE")
        
        // TEST PATTERN MODE - ALWAYS SHOW for debugging
        do {
            NSLog("📱 Building test pattern...")
            var testPattern = ""
            // Header line with column markers every 10 chars
            testPattern += "TEST PATTERN - \(cols) columns:\n"
            
            // Row of numbers showing column positions
            var ruler = ""
            for i in 1...cols {
                if i % 10 == 0 {
                    ruler += "\(i/10)"
                } else {
                    ruler += " "
                }
            }
            testPattern += ruler + "\n"
            
            // Row of tick marks
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
            testPattern += ticks + "\n"
            
            // A few lines of full-width text
            for lineNum in 1...5 {
                var line = String(format: "%02d ", lineNum)
                let remainingCols = cols - line.count
                let pattern = "ABCDEFGHIJ"
                for i in 0..<remainingCols {
                    line += String(pattern[pattern.index(pattern.startIndex, offsetBy: i % pattern.count)])
                }
                testPattern += line + "\n"
            }
            
            testPattern += "\nEnd of test pattern\n"
            
            NSLog("📱 Feeding test pattern to terminal...")
            await MainActor.run {
                terminalController?.clear()
                terminalController?.feed(text: testPattern)
            }
            NSLog("📱 Test pattern fed successfully")
        }
        
        isLoading = false
        NSLog("📱 loadOutput completed (TEST PATTERN MODE)")
        
        /* DISABLED - NORMAL MODE
        do {
            let captured = try await tmuxManager.capturePaneOutput(session: session, lines: 100, cols: cols, rows: rows)
            print("📱 Captured output length: \(captured.count) characters (cols:\(cols) rows:\(rows))")
            print("📱 First 100 chars: \(String(captured.prefix(100)))")
            
            await MainActor.run {
                terminalController?.clear()
                terminalController?.feed(text: captured)
            }
        } catch {
            print("📱 Error capturing output: \(error)")
            await MainActor.run {
                terminalController?.feed(text: "Error: \(error.localizedDescription)\n")
            }
        }
        
        isLoading = false
        print("📱 loadOutput completed")
        */
    }
    
    private func refreshOutput() {
        Task {
            await loadOutput()
        }
    }
    
    private func handleBridgeInput(oldValue: String, newValue: String) {
        // Echo locally and send to remote
        if newValue.count > oldValue.count {
            let diff = String(newValue.suffix(newValue.count - oldValue.count))
            terminalController?.feed(text: diff)
            Task { try? await tmuxManager.sendKeys(diff, session: session) }
            // If newline entered, clear buffer and refresh
            if diff.contains("\n") {
                bridgeText = ""
                Task { try? await Task.sleep(nanoseconds: 150_000_000); await loadOutput() }
            }
        } else if newValue.count < oldValue.count {
            // Backspace
            let del = oldValue.count - newValue.count
            for _ in 0..<del {
                terminalController?.feed(text: "\u{08} \u{08}")
                Task { try? await tmuxManager.sendKeys("BSpace", session: session) }
            }
        }
    }
    
    private func killSession() {
        Task {
            do {
                try await tmuxManager.killSession(session)
                await MainActor.run {
                    stopAutoRefresh()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    terminalController?.feed(text: "\nError killing session: \(error.localizedDescription)\n")
                }
            }
        }
    }
    
    #if os(iOS)
    private func handleTerminalKey(_ key: TerminalKey) {
        let sequence = key.escapeSequence
        guard !sequence.isEmpty else { return }
        
        Task {
            do {
                try await tmuxManager.sendKeys(sequence, session: session)
                
                // Refresh after a short delay
                try await Task.sleep(nanoseconds: 100_000_000)
                await loadOutput()
            } catch {
                await MainActor.run {
                    terminalController?.feed(text: "\nError: \(error.localizedDescription)\n")
                }
            }
        }
    }
    
    private func copySelectedText() {
        guard let selectedText = terminalController?.getSelectedText(), !selectedText.isEmpty else {
            return
        }
        
        UIPasteboard.general.string = selectedText
    }
    
    private func pasteText() {
        guard let text = UIPasteboard.general.string, !text.isEmpty else {
            return
        }
        
        Task {
            do {
                try await tmuxManager.sendKeys(text, session: session)
                
                // Refresh after paste
                try await Task.sleep(nanoseconds: 100_000_000)
                await loadOutput()
            } catch {
                await MainActor.run {
                    terminalController?.feed(text: "\nError: \(error.localizedDescription)\n")
                }
            }
        }
    }
    #endif
    
    private func clearTerminal() {
        terminalController?.clear()
    }
    
    private func startAutoRefresh() {
        // Auto-refresh terminal output every 300ms for responsive feedback
        autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            Task {
                await loadOutput()
            }
        }
    }
    
    private func stopAutoRefresh() {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil
    }
}

#Preview {
    SessionDetailView(
        session: TmuxSession(id: "test", name: "test", created: Date(), attached: false, windows: 1),
        tmuxManager: TmuxManager()
    )
}
