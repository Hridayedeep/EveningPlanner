import SwiftUI
import FirebaseCore

@main
struct EveningPlannerApp: App {
    @State private var authModel: AuthenticationModel
    
    init() {
        FirebaseApp.configure()
        
        let authManager = AuthManager()
        let firestoreManager = FirestoreManager()
        let model = AuthenticationModel(authManager: authManager, firestoreManager: firestoreManager)
        
        _authModel = State(initialValue: model)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authModel)
        }
    }
}
