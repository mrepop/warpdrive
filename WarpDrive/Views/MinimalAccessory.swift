#if os(iOS)
import UIKit

/// A minimal input accessory that intentionally contains no buttons.
/// Purpose: prevent SwiftTerm's TerminalAccessory (which includes a custom keyboard toggle)
/// from being installed so the system QWERTY keyboard is used.
final class MinimalAccessory: UIInputView {
    init(height: CGFloat = 36) {
        // Use keyboard style so it docks like the normal accessory bar
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: height), inputViewStyle: .keyboard)
        allowsSelfSizing = true
        backgroundColor = .clear
        // Add a thin separator for visual clarity (optional)
        let separator = UIView(frame: CGRect(x: 0, y: 0, width: bounds.width, height: 0.5))
        separator.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        separator.backgroundColor = UIColor.separator.withAlphaComponent(0.3)
        addSubview(separator)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
#endif
