import SwiftUI

/// Terminal key types
enum TerminalKey {
    case escape
    case tab
    case control
    case alt
    case arrowUp
    case arrowDown
    case arrowLeft
    case arrowRight
    case home
    case end
    case pageUp
    case pageDown
    case function(Int)
    
    /// Convert to ANSI escape sequence
    var escapeSequence: String {
        switch self {
        case .escape:
            return "\u{1B}"
        case .tab:
            return "\t"
        case .control:
            // Ctrl key is a modifier, not a standalone key
            // Return empty for now, handle with modifier logic
            return ""
        case .alt:
            // Alt key is a modifier
            return ""
        case .arrowUp:
            return "\u{1B}[A"
        case .arrowDown:
            return "\u{1B}[B"
        case .arrowRight:
            return "\u{1B}[C"
        case .arrowLeft:
            return "\u{1B}[D"
        case .home:
            return "\u{1B}[H"
        case .end:
            return "\u{1B}[F"
        case .pageUp:
            return "\u{1B}[5~"
        case .pageDown:
            return "\u{1B}[6~"
        case .function(let num):
            // F1-F12 escape sequences
            switch num {
            case 1: return "\u{1B}OP"
            case 2: return "\u{1B}OQ"
            case 3: return "\u{1B}OR"
            case 4: return "\u{1B}OS"
            case 5: return "\u{1B}[15~"
            case 6: return "\u{1B}[17~"
            case 7: return "\u{1B}[18~"
            case 8: return "\u{1B}[19~"
            case 9: return "\u{1B}[20~"
            case 10: return "\u{1B}[21~"
            case 11: return "\u{1B}[23~"
            case 12: return "\u{1B}[24~"
            default: return ""
            }
        }
    }
}

#if os(iOS)
/// Custom keyboard accessory view with terminal-specific keys
struct TerminalKeyboardAccessory: View {
    let onKeyPress: (TerminalKey) -> Void
    @State private var showExtendedKeys = false
    
    var body: some View {
        VStack(spacing: 0) {
            if showExtendedKeys {
                // Extended keys row (F-keys)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(1...12, id: \.self) { num in
                            KeyButton(title: "F\(num)", width: 50) {
                                onKeyPress(.function(num))
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .frame(height: 40)
                .background(Color(.systemGray5))
                
                Divider()
            }
            
            // Main control keys row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    KeyButton(title: "ESC", width: 50) {
                        onKeyPress(.escape)
                    }
                    
                    KeyButton(title: "TAB", width: 50) {
                        onKeyPress(.tab)
                    }
                    
                    KeyButton(title: "CTRL", width: 50) {
                        onKeyPress(.control)
                    }
                    
                    KeyButton(title: "ALT", width: 50) {
                        onKeyPress(.alt)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    KeyButton(title: "↑", width: 40) {
                        onKeyPress(.arrowUp)
                    }
                    
                    KeyButton(title: "↓", width: 40) {
                        onKeyPress(.arrowDown)
                    }
                    
                    KeyButton(title: "←", width: 40) {
                        onKeyPress(.arrowLeft)
                    }
                    
                    KeyButton(title: "→", width: 40) {
                        onKeyPress(.arrowRight)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    KeyButton(title: "HOME", width: 50) {
                        onKeyPress(.home)
                    }
                    
                    KeyButton(title: "END", width: 50) {
                        onKeyPress(.end)
                    }
                    
                    KeyButton(title: "PGUP", width: 50) {
                        onKeyPress(.pageUp)
                    }
                    
                    KeyButton(title: "PGDN", width: 50) {
                        onKeyPress(.pageDown)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    KeyButton(title: showExtendedKeys ? "<<<" : ">>>", width: 50) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showExtendedKeys.toggle()
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
            .frame(height: 44)
            .background(Color(.systemGray6))
        }
    }
}

/// Individual key button
private struct KeyButton: View {
    let title: String
    let width: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: width, height: 32)
                .background(Color(.systemGray4))
                .cornerRadius(6)
        }
    }
}

#Preview {
    TerminalKeyboardAccessory { key in
        print("Key pressed: \(key)")
    }
    .frame(height: 88)
}
#endif
