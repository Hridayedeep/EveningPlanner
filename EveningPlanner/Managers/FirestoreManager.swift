import Foundation

public final class FirestoreManager {
    public init() {}
    
    public func isUserBanned(deviceID: String) async throws {
        // Mock: user is not banned
    }
    
    public func logUserData(user: MyUser) async throws {
        // Mock logging
    }
    
    public func getDocumentWithListener<T: Decodable>(_ type: T.Type, at path: String) async -> AsyncStream<T?> {
        return AsyncStream { continuation in
            continuation.yield(nil)
            continuation.finish()
        }
    }
}
