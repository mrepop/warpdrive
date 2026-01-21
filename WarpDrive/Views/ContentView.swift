import SwiftUI

struct ContentView: View {
    @StateObject private var sessionManager = SessionManager()
    
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "terminal.fill")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                    .font(.system(size: 72))
                    .padding()
                
                Text("WarpDrive")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Control your Warp sessions from anywhere")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
                
                Button(action: {
                    // TODO: Connect to Warp session
                }) {
                    Label("Connect to Session", systemImage: "link")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("WarpDrive")
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
