import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices
import CryptoKit

public enum AuthenticationMethod: Equatable {
    case google
    case apple
    
    public var title: String {
        switch self {
        case .google:
            return "Google"
        case .apple:
            return "Apple"
        }
    }
    
    public var providerID: String {
        switch self {
        case .google:
            return GoogleAuthProviderID
        case .apple:
            return "apple.com"
        }
    }
}

public final class AuthManager {
    public let auth: Auth
    
    public init(auth: Auth = .auth()) {
        self.auth = auth
    }
    
    public func verifySignInWithAppleAuthenticationState() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let providerData = auth.currentUser?.providerData
        if let appleProviderData = providerData?.first(where: { $0.providerID == "apple.com" }) {
            Task {
                guard let credentialState = try? await appleIDProvider.credentialState(forUserID: appleProviderData.uid) else {
                    return
                }
                switch credentialState {
                case .authorized:
                    break
                case .revoked, .notFound:
                    try? logout()
                default:
                    break
                }
            }
        }
    }
    
    public func authStateStream<T: UserRepresentable>() -> AsyncStream<T?> {
        AsyncStream { continuation in
            let handle = auth.addStateDidChangeListener { _, user in
                if let user = user {
                    let myUser = T(user: user)
                    continuation.yield(myUser)
                } else {
                    continuation.yield(nil)
                }
            }
            
            continuation.onTermination = { @Sendable [auth] _ in
                auth.removeStateDidChangeListener(handle)
            }
        }
    }
    
    public func updateDisplayName(to newName: String) async throws {
        guard let user = auth.currentUser else {
            throw AuthErrorCode.userNotFound
        }
        
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = newName
        
        try await changeRequest.commitChanges()
    }
    
    public func authenticate<T: UserRepresentable>(with method: AuthenticationMethod) async throws -> T {
        switch method {
        case .google:
            return try await signInWithGoogle()
        case .apple:
            return try await signInWithApple()
        }
    }
    
    public func linkAccount<T: UserRepresentable>(with method: AuthenticationMethod) async throws -> T {
        switch method {
        case .google:
            return try await linkGoogleAccount()
        case .apple:
            return try await linkAppleAccount()
        }
    }
    
    public func unlink<T: UserRepresentable>(from method: AuthenticationMethod) async throws -> T {
        guard let user = auth.currentUser else { throw AuthErrorCode.userNotFound }
        guard user.providerData.count > 1 else {
            throw AuthErrorCode.appNotAuthorized
        }
        let updatedUser = try await user.unlink(fromProvider: method.providerID)
        
        return T(user: updatedUser)
    }
    
    public func reauthenticate(with method: AuthenticationMethod) async throws {
        guard let currentUser = auth.currentUser else {
            throw AuthErrorCode.userNotFound
        }
        
        let credential = try await fetchCredential(for: method)
        try await currentUser.reauthenticate(with: credential)
    }
    
    private func fetchCredential(for method: AuthenticationMethod) async throws -> AuthCredential {
        switch method {
        case .google:
            return try await googleAuthCredential()
        case .apple:
            let credentialTuple = try await appleAuthCredential()
            return credentialTuple.auth
        }
    }
    
    public func logout() throws {
        try auth.signOut()
    }
}

// MARK: - Google Auth
extension AuthManager {
    private func googleAuthCredential() async throws -> AuthCredential {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthErrorCode.invalidClientID
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        let gidResult = try await googleSignInHelper()
        
        guard let idToken = gidResult.user.idToken?.tokenString else {
            throw AuthErrorCode.invalidUserToken
        }
        let accessToken = gidResult.user.accessToken.tokenString
        return GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
    }
    
    public func signInWithGoogle<T: UserRepresentable>() async throws -> T {
        let credential = try await googleAuthCredential()
        let authResult = try await auth.signIn(with: credential)
        return T(user: authResult.user)
    }
    
    public func linkGoogleAccount<T: UserRepresentable>() async throws -> T {
        guard let currentUser = auth.currentUser else {
            throw AuthErrorCode.userNotFound
        }
        let credential = try await googleAuthCredential()
        let authResult = try await currentUser.link(with: credential)
        return T(user: authResult.user)
    }
    
    @MainActor
    private func googleSignInHelper() async throws -> GIDSignInResult {
        guard let topVC = Utilities.shared.topViewController() else {
            throw AuthErrorCode.invalidAppCredential
        }
        
        return try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)
    }
}

// MARK: - Apple Auth
extension AuthManager {
    private func appleAuthCredential() async throws -> (auth: OAuthCredential, appleId: ASAuthorizationAppleIDCredential) {
        let rawNonce = CryptoUtils.randomNonceString()
        let hashedNonce = CryptoUtils.sha256(rawNonce)
        
        let appleResult = try await AppleSignInHelper().startSignInWithAppleFlow(nonce: hashedNonce)
        
        guard let appleIDCredential = appleResult.credential as? ASAuthorizationAppleIDCredential,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw AuthErrorCode.invalidCustomToken
        }
        
        let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                       rawNonce: rawNonce,
                                                       fullName: appleIDCredential.fullName)
        return (credential, appleIDCredential)
    }
    
    private func persistName<T: UserRepresentable>(authResult: AuthDataResult, authToken: OAuthCredential, appleId: ASAuthorizationAppleIDCredential) async throws -> T {
        if let appleUser = appleId.fullName {
            let firstName = appleUser.givenName ?? ""
            let lastName = appleUser.familyName ?? ""
            let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
            
            if !fullName.isEmpty {
                let changeRequest = authResult.user.createProfileChangeRequest()
                changeRequest.displayName = fullName
                try await changeRequest.commitChanges()
                var updatedUser = T(user: authResult.user)
                updatedUser.updateName(newName: fullName)
                return updatedUser
            }
        }
        return T(user: authResult.user)
    }
    
    public func signInWithApple<T: UserRepresentable>() async throws -> T {
        let credential = try await appleAuthCredential()
        let authResult = try await auth.signIn(with: credential.auth)
        return try await persistName(authResult: authResult, authToken: credential.auth, appleId: credential.appleId)
    }
    
    public func linkAppleAccount<T: UserRepresentable>() async throws -> T {
        guard let currentUser = auth.currentUser else {
            throw AuthErrorCode.userNotFound
        }
        let credential = try await appleAuthCredential()
        let authResult = try await currentUser.link(with: credential.auth)
        return try await persistName(authResult: authResult, authToken: credential.auth, appleId: credential.appleId)
    }
}

// MARK: - Apple Sign-In Helper (Delegate Handler)
@MainActor
public final class AppleSignInHelper: NSObject {
    private var continuation: CheckedContinuation<ASAuthorization, Error>?
    private var authorizationController: ASAuthorizationController?
    
    public func startSignInWithAppleFlow(nonce: String) async throws -> ASAuthorization {
        if continuation != nil {
            throw AuthErrorCode.tooManyRequests
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = nonce
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            
            self.authorizationController = controller
            controller.performRequests()
        }
    }
}

extension AppleSignInHelper: ASAuthorizationControllerDelegate {
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation?.resume(returning: authorization)
        cleanUp()
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        cleanUp()
    }
    
    private func cleanUp() {
        continuation = nil
        authorizationController = nil
    }
}

extension AppleSignInHelper: ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let window = Utilities.shared.topViewController()?.view.window {
            return window
        }
        
        let scenes = UIApplication.shared.connectedScenes
        if let window = scenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) {
            return window
        }
        
        if let activeScene = scenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            return UIWindow(windowScene: activeScene)
        }
        fatalError("Unable to find a valid UIWindowScene for Apple Sign In presentation.")
    }
}

// MARK: - Crypto Utilities
public struct CryptoUtils {
    public static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }
    
    public static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
    }
}

// MARK: - Utilities
@MainActor
public final class Utilities {
    public static let shared = Utilities()
    private init() {}
    
    public func topViewController(controller: UIViewController? = nil) -> UIViewController? {
        let controller = controller ?? UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
        
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}
