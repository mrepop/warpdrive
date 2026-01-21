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
            // Keyboard accessory overlay (conditionally shown)
            if showKeyboardAccessory && (!settings.keyboardAutoHide || showKeyboardAccessory) {
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
                    await loadOutput()
                    startAutoRefresh()
                }
            }
    }
    
    private func loadOutput() async {
        isLoading = true
        print("📱 SessionDetailView: loadOutput started for session \(session.name)")
        print("📱 Terminal controller: \(terminalController != nil ? "exists" : "nil")")
        
        do {
            let captured = try await tmuxManager.capturePaneOutput(session: session, lines: 100)
            print("📱 Captured output length: \(captured.count) characters")
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
    }
    
    private func refreshOutput() {
        Task {
            await loadOutput()
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
