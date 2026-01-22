#if os(iOS)
import SwiftUI
import UIKit

/// A tiny, invisible UITextField that forces the iOS software keyboard to appear
/// and emits every keystroke via `onText`.
struct KeyboardBridgeView: UIViewRepresentable {
    typealias UIViewType = UITextField
    var onText: (String) -> Void
    var onBackspace: () -> Void

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: KeyboardBridgeView
        init(_ parent: KeyboardBridgeView) { self.parent = parent }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            if string.isEmpty {
                parent.onBackspace()
            } else {
                parent.onText(string)
            }
            // Keep field empty to avoid uncontrolled growth
            textField.text = ""
            return false
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField(frame: .zero)
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.spellCheckingType = .no
        tf.keyboardType = .asciiCapable
        tf.textContentType = .none
        tf.delegate = context.coordinator
        tf.tintColor = .clear
        tf.textColor = .clear
        tf.backgroundColor = .clear
        tf.isSecureTextEntry = false
        // Ensure no custom accessory or inputView interferes
        tf.inputView = nil
        tf.inputAssistantItem.leadingBarButtonGroups = []
        tf.inputAssistantItem.trailingBarButtonGroups = []
        // Become first responder asynchronously to guarantee focus
        DispatchQueue.main.async { _ = tf.becomeFirstResponder() }
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if !uiView.isFirstResponder { DispatchQueue.main.async { _ = uiView.becomeFirstResponder() } }
    }
}
#endif
