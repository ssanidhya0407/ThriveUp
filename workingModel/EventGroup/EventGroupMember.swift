import Foundation

// Legacy non-namespaced class that parts of the app may still be using
class EventGroupMember {
    var userId: String
    var name: String
    var role: String // "organizer" or "member"
    var joinedAt: Date
    var canChat: Bool
    var profileImageURL: String?
    
    init(userId: String, name: String, role: String, joinedAt: Date, canChat: Bool, profileImageURL: String? = nil) {
        self.userId = userId
        self.name = name
        self.role = role
        self.joinedAt = joinedAt
        self.canChat = canChat
        self.profileImageURL = profileImageURL
    }
    
    // Factory method to create from EventGroup.Member
    static func fromEventGroupMember(_ member: EventGroup.Member) -> EventGroupMember {
        return EventGroupMember(
            userId: member.userId,
            name: member.name,
            role: member.role,
            joinedAt: member.joinedAt,
            canChat: member.canChat,
            profileImageURL: member.profileImageURL
        )
    }
}
