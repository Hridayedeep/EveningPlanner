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
                VStack(spacing: 20) {
                    Text("Welcome to Evening Planner!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if let email = authModel.myUser?.email {
                        Text("Signed in as: \(email)")
                            .foregroundColor(.gray)
                    } else if let uid = authModel.myUser?.uid {
                        Text("Signed in (UID: \(uid))")
                            .foregroundColor(.gray)
                    }
                    
                    Button("Sign Out") {
                        Task {
                            await authModel.logout()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.ignoresSafeArea())
                .preferredColorScheme(.dark)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthenticationModel.forPreview())
}
