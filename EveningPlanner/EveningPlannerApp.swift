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

        // Encore: set the notification delegate + categories before launch finishes
        // so taps (even cold-launch) route correctly.
        EncoreNotifications.shared.bootstrap()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authModel)
        }
    }
}
