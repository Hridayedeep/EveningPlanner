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
                MainTabView()
                    .preferredColorScheme(.dark)
            }
        }
    }
}

/// Authenticated home. Two entry points, one occasion engine (see claude.md §0.2):
/// Flow A — Encore (taste-driven discovery), Flow B — Plan My Evening (questionnaire).
private struct MainTabView: View {
    var body: some View {
        TabView {
            EncoreRootView()
                .tabItem { Label("Encore", systemImage: "waveform") }

            WelcomeScreen()
                .tabItem { Label("Plan Evening", systemImage: "sparkles") }
        }
        .tint(.white)
    }
}
