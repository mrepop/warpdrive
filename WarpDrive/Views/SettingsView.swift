import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var settings = TerminalSettings.shared
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Terminal Display")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Font Size")
                            Spacer()
                            Text(String(format: "%.0f", settings.fontSize))
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(
                            value: $settings.fontSize,
                            in: TerminalSettings.minFontSize...TerminalSettings.maxFontSize,
                            step: 1
                        )
                        
                        HStack {
                            Text("Small")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Large")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    Toggle(isOn: $settings.fitToWidthEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Fit Columns to Width")
                            Text("Auto-size font so exactly N columns fit the screen width.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if settings.fitToWidthEnabled {
                        HStack {
                            Text("Columns")
                            Spacer()
                            Picker("Columns", selection: $settings.fitColumns) {
                                Text("80").tag(80)
                                Text("100").tag(100)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 160)
                        }
                    }

                    Text("Adjust the font size for better readability on your device.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Keyboard")) {
                    Toggle(isOn: $settings.keyboardAutoHide) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Auto-hide Terminal Keys")
                            Text("Hide the terminal key accessory bar when not in use to maximize screen space.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
