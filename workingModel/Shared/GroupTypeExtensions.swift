import Foundation
import FirebaseFirestore

// MARK: - Type Converters for UserGroup and EventGroup compatibility

// Use module-namespaced types to avoid ambiguity
extension EventGroup.Member {
    func toUserGroup() -> UserGroup.Member {
        return UserGroup.Member(
            userId: self.userId,
            name: self.name,
            role: self.role,
            joinedAt: self.joinedAt,
            canChat: self.canChat,
            profileImageURL: self.profileImageURL
        )
    }
    
    static func fromUserGroup(_ groupMember: UserGroup.Member) -> EventGroup.Member {
        return EventGroup.Member(
            userId: groupMember.userId,
            name: groupMember.name,
            role: groupMember.role,
            joinedAt: groupMember.joinedAt,
            canChat: groupMember.canChat,
            profileImageURL: groupMember.profileImageURL
        )
    }
}

extension UserGroup.Member {
    func toEventGroup() -> EventGroup.Member {
        return EventGroup.Member(
            userId: self.userId,
            name: self.name,
            role: self.role,
            joinedAt: self.joinedAt,
            canChat: self.canChat,
            profileImageURL: self.profileImageURL
        )
    }
}

// Convert between EventGroup.Message and UserGroup.Message
extension EventGroup.Message {
    func toUserGroup() -> UserGroup.Message {
        return UserGroup.Message(
            id: self.id,
            userId: self.userId,
            userName: self.userName,
            text: self.text,
            timestamp: self.timestamp,
            profileImageURL: self.profileImageURL,
            imageURL: self.imageURL
        )
    }
    
    static func fromUserGroup(_ groupMessage: UserGroup.Message) -> EventGroup.Message {
        return EventGroup.Message(
            id: groupMessage.id,
            userId: groupMessage.userId,
            userName: groupMessage.userName,
            text: groupMessage.text,
            timestamp: groupMessage.timestamp,
            profileImageURL: groupMessage.profileImageURL,
            imageURL: groupMessage.imageURL
        )
    }
}

extension UserGroup.Message {
    func toEventGroup() -> EventGroup.Message {
        return EventGroup.Message(
            id: self.id,
            userId: self.userId,
            userName: self.userName,
            text: self.text,
            timestamp: self.timestamp,
            profileImageURL: self.profileImageURL,
            imageURL: self.imageURL
        )
    }
}
