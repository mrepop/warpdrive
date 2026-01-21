import XCTest
@testable import WarpDrive

final class TerminalSettingsTests: XCTestCase {
    func testDefaultFontSize() {
        let settings = TerminalSettings.shared
        // Default should be 10.0 for better phone display
        XCTAssertEqual(settings.fontSize, 10.0, "Default font size should be 10.0")
    }
    
    func testFontSizeRange() {
        // Verify the min and max values
        XCTAssertEqual(TerminalSettings.minFontSize, 8.0, "Min font size should be 8.0")
        XCTAssertEqual(TerminalSettings.maxFontSize, 24.0, "Max font size should be 24.0")
    }
    
    func testFontSizeModification() {
        let settings = TerminalSettings.shared
        let originalSize = settings.fontSize
        
        // Change font size
        settings.fontSize = 14.0
        XCTAssertEqual(settings.fontSize, 14.0, "Font size should be updated")
        
        // Restore original
        settings.fontSize = originalSize
    }
}
