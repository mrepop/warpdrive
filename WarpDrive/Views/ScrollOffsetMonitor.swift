import SwiftUI
#if os(iOS)
import SwiftTerm
#endif

struct ScrollOffsetMonitor: View {
    @Binding var terminalController: TerminalViewController?
    @State private var offsetX: CGFloat = 0
    @State private var contentWidth: CGFloat = 0
    @State private var viewWidth: CGFloat = 0
    @State private var fontSize: CGFloat = 0
    
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("X:\(Int(offsetX))")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(offsetX > 1 ? .red : .green)
                .padding(6)
                .background(offsetX > 1 ? Color.red.opacity(0.9) : Color.green.opacity(0.9))
                .cornerRadius(6)
            
            Text("cW:\(Int(contentWidth)) vW:\(Int(viewWidth))")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .padding(4)
                .background(Color.black.opacity(0.8))
                .cornerRadius(4)
            
            Text("pt:\(String(format: "%.1f", fontSize))")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .padding(4)
                .background(Color.black.opacity(0.8))
                .cornerRadius(4)
        }
        .onReceive(timer) { _ in
            updateMetrics()
        }
    }
    
    private func updateMetrics() {
        #if os(iOS)
        guard let termView = terminalController?.terminalView as? SwiftTerm.TerminalView else { return }
        offsetX = termView.contentOffset.x
        contentWidth = termView.contentSize.width
        viewWidth = termView.bounds.width
        fontSize = termView.font.pointSize
        #endif
    }
}
