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
                    
                    Text("Adjust the font size for better readability on your device.")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
