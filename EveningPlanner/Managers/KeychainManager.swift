import UIKit

public final class KeychainManager {
    public static let shared = KeychainManager()
    private init() {}
    
    public func isDeviceIdPresent() -> Bool {
        return true
    }
    
    public func getDeviceId() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? "mock-device-id"
    }
}
