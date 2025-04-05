import Foundation

// MARK: - Common Protocol for Group Members
protocol MemberProtocol {
    var userId: String { get }
    var name: String { get }
    var role: String { get }
    var joinedAt: Date { get }
    var canChat: Bool { get }
    var profileImageURL: String? { get }
}

// Make both member types conform to the protocol
extension UserGroup.Member: MemberProtocol {}
extension EventGroup.Member: MemberProtocol {}

// MARK: - Common Protocol for Messages
protocol MessageProtocol {
    var id: String { get }
    var userId: String { get }
    var userName: String { get }
    var text: String? { get }
    var timestamp: Date { get }
    var profileImageURL: String? { get }
    var imageURL: String? { get }
}

// Make both message types conform to the protocol
extension UserGroup.Message: MessageProtocol {}
extension EventGroup.Message: MessageProtocol {}
