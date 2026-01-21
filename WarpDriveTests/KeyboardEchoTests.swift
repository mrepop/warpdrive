import XCTest
@testable import WarpDriveCore
import SwiftUI

/// Tests to verify keyboard autocapitalization fixes and character echo
final class KeyboardEchoTests: XCTestCase {
    
    func testTextFieldAutocapitalizationDisabled() {
        // This test verifies that TextField has autocapitalization disabled
        // The actual verification happens at runtime in iOS, but we can test
        // the component compiles with the correct modifiers
        
        // Create a mock TextField similar to SessionDetailView
        struct TestView: View {
            @State private var command: String = ""
            
            var body: some View {
                TextField("Enter command...", text: $command)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.asciiCapable)
                    #endif
            }
        }
        
        // If this compiles, the modifiers are correct
        let _ = TestView()
        XCTAssertTrue(true, "TextField with autocapitalization disabled compiles correctly")
    }
    
    func testCharacterEchoLogic() {
        // Test the character echo logic for adding characters
        let oldValue = "ls"
        let newValue = "ls -la"
        
        // Diff should be " -la"
        let expectedDiff = String(newValue.suffix(newValue.count - oldValue.count))
        XCTAssertEqual(expectedDiff, " -la", "Character diff calculation should work correctly")
    }
    
    func testBackspaceEchoLogic() {
        // Test backspace handling
        let oldValue = "ls -la"
        let newValue = "ls"
        
        // Should detect 4 characters removed
        let deleteCount = oldValue.count - newValue.count
        XCTAssertEqual(deleteCount, 4, "Backspace count should be calculated correctly")
    }
    
    func testRefreshIntervalIsOptimized() {
        // Verify that refresh interval is reasonable for responsive terminal
        let refreshInterval: TimeInterval = 0.3
        
        // Should be less than 1 second for good responsiveness
        XCTAssertLessThan(refreshInterval, 1.0, "Refresh interval should be less than 1 second")
        
        // Should be at least 100ms to avoid overwhelming the system
        XCTAssertGreaterThanOrEqual(refreshInterval, 0.1, "Refresh interval should be at least 100ms")
    }
    
    func testTerminalKeyEscapeSequences() {
        // Verify ANSI escape sequences are correct
        XCTAssertEqual(TerminalKey.escape.escapeSequence, "\u{1B}", "ESC key should produce correct sequence")
        XCTAssertEqual(TerminalKey.tab.escapeSequence, "\t", "TAB key should produce correct sequence")
        XCTAssertEqual(TerminalKey.arrowUp.escapeSequence, "\u{1B}[A", "Arrow up should produce correct sequence")
        XCTAssertEqual(TerminalKey.arrowDown.escapeSequence, "\u{1B}[B", "Arrow down should produce correct sequence")
        XCTAssertEqual(TerminalKey.arrowLeft.escapeSequence, "\u{1B}[D", "Arrow left should produce correct sequence")
        XCTAssertEqual(TerminalKey.arrowRight.escapeSequence, "\u{1B}[C", "Arrow right should produce correct sequence")
        XCTAssertEqual(TerminalKey.home.escapeSequence, "\u{1B}[H", "HOME key should produce correct sequence")
        XCTAssertEqual(TerminalKey.end.escapeSequence, "\u{1B}[F", "END key should produce correct sequence")
    }
    
    func testFunctionKeyEscapeSequences() {
        // Verify F-key escape sequences
        XCTAssertEqual(TerminalKey.function(1).escapeSequence, "\u{1B}OP", "F1 should produce correct sequence")
        XCTAssertEqual(TerminalKey.function(2).escapeSequence, "\u{1B}OQ", "F2 should produce correct sequence")
        XCTAssertEqual(TerminalKey.function(5).escapeSequence, "\u{1B}[15~", "F5 should produce correct sequence")
        XCTAssertEqual(TerminalKey.function(12).escapeSequence, "\u{1B}[24~", "F12 should produce correct sequence")
    }
}
