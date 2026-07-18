import SwiftUI

struct ContentView: View {
    @Environment(AuthenticationModel.self) var authModel
    
    var body: some View {
        Group {
            switch authModel.authState {
            case .authenticating:
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.ignoresSafeArea())
                    .preferredColorScheme(.dark)
            case .unauthenticated:
                AuthenticationView()
                    .preferredColorScheme(.dark)
            case .authenticated:
                WelcomeScreen()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthenticationModel.forPreview())
}
