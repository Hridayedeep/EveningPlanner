import Foundation
// import FirebaseMessaging
import FirebaseAuth
import CoreLocation

enum AuthenticationState : Equatable {
    case authenticated
    case unauthenticated
    case authenticating
}

enum AuthError : Error, LocalizedError {
    case deviceBanned
    
    var errorDescription: String? {
        switch self {
        case .deviceBanned:
            return "Access is denied for this device and any other sharing its digital footprint."
        }
    }
}

@MainActor @Observable
class AuthenticationModel {
    
    @ObservationIgnored private var authManager: AuthManager
    @ObservationIgnored private var firestoreManager: FirestoreManager
    @ObservationIgnored private var storageManager: StorageManager
    @ObservationIgnored private var listenerHandle : Task<Void, Never>?
    @ObservationIgnored private var userListener : Task<Void, Never>?

    var authState = AuthenticationState.authenticating
    var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined

    var myUser : MyUser?
    
    init(authManager: AuthManager, firestoreManager : FirestoreManager, storageManager: StorageManager? = nil) {
        self.authManager = authManager
        self.firestoreManager = firestoreManager
        self.storageManager = storageManager ?? StorageManager()

        listenToAuthState()
        listenToAppleAuthState()
    }

    static func forPreview() -> AuthenticationModel {
        AuthenticationModel(authManager: AuthManager(), firestoreManager: FirestoreManager())
    }

    func authenticate(with method : AuthenticationMethod) async throws -> MyUser {
        let isDevideIdPresent = KeychainManager.shared.isDeviceIdPresent()
        
        if isDevideIdPresent {
            try await firestoreManager.isUserBanned(deviceID: KeychainManager.shared.getDeviceId())
        }
        
        return try await authenticationHelper(method: method)
    }
    
    func logout() async {
        try? await authManager.logout()
    }
    
    func logUser(user : inout MyUser) async {
        user.fcmToken = "mock-fcm-token"
        user.deviceId = KeychainManager.shared.getDeviceId()
        try? await firestoreManager.logUserData(user: user)
    }
    }


//MARK: - Auth State Listeners and Initial Login
extension AuthenticationModel {
    private func listenToAuthState() {
        guard listenerHandle == nil else { return }
        listenerHandle = Task {
            let stream : AsyncStream<MyUser?> = await authManager.authStateStream()
            for await user in stream {
                if let user {
                    authState = .authenticated
                    fetchUser(uid: user.uid)
                } else {
                    authState = .unauthenticated
                }
            }
        }
    }

    private func listenToAppleAuthState() {
        Task {
            await authManager.verifySignInWithAppleAuthenticationState()
        }
    }
    
    func fetchUser(uid : String)  {
        guard userListener == nil else {return}
        userListener = Task {
            let stream = await firestoreManager.getDocumentWithListener(MyUser.self, at: "Users/\(uid)")
            for await result in stream {
                myUser = result
            }
        }
    }
    
    private func clearUserSession() {
        userListener?.cancel()
        userListener = nil
        myUser = nil
    }
}

//MARK: - Auth Helper
extension AuthenticationModel {
    @discardableResult
    private func authenticationHelper(method : AuthenticationMethod) async throws -> MyUser {
        var authenticatedUser : MyUser?
        switch method {
        case .google:
            authenticatedUser = try await authManager.signInWithGoogle()
        case .apple:
            authenticatedUser = try await authManager.signInWithApple()
        }
        
        guard let authenticatedUser = authenticatedUser else {
            throw URLError(.timedOut)
        }
        
        return authenticatedUser
    }
}

// MARK: - Phone Auth & Linking
extension AuthenticationModel {
    func startPhoneVerification(phoneNumber: String) async throws -> String {
        let verificationID = try await PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil)
        return verificationID
    }
    
    func verifyAndLinkPhone(verificationID: String?, smsCode: String) async throws {
        guard let verificationID = verificationID else {
            throw URLError(.badServerResponse)
        }
        
        guard let currentUser = await authManager.auth.currentUser else {
            throw NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user is currently signed in."])
        }
        
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: smsCode
        )
        
        try await currentUser.updatePhoneNumber(credential)
        try await currentUser.reload()
    }
}
