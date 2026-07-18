import Foundation
import FirebaseAuth

public protocol UserRepresentable: Identifiable, Codable {
    var uid: String { get }
    var name: String? { get set }
    var email: String? { get set }
    
    init(user: User)
    mutating func updateName(newName: String)
}

public struct AppUser: UserRepresentable {
    public var id: String { uid }
    public let uid: String
    public var name: String?
    public var email: String?
    
    public init(user: User) {
        self.uid = user.uid
        self.name = user.displayName
        self.email = user.email
    }
    
    public init(uid: String, name: String?, email: String?) {
        self.uid = uid
        self.name = name
        self.email = email
    }
    
    public mutating func updateName(newName: String) {
        self.name = newName
    }
}
