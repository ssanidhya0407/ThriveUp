import Foundation
import FirebaseFirestore

// Create a namespace for UserGroup types
enum UserGroup {
    struct Member {
        var userId: String
        var name: String
        var role: String // "admin" or "member"
        var joinedAt: Date
        var canChat: Bool
        var profileImageURL: String?
        
        // Remove the toEventGroup method entirely
    }
    
    struct Message {
        let id: String
        let userId: String
        let userName: String
        let text: String?
        let timestamp: Date
        let profileImageURL: String?
        let imageURL: String?
        
        init(id: String, userId: String, userName: String, text: String? = nil, timestamp: Date, profileImageURL: String? = nil, imageURL: String? = nil) {
            self.id = id
            self.userId = userId
            self.userName = userName
            self.text = text
            self.timestamp = timestamp
            self.profileImageURL = profileImageURL
            self.imageURL = imageURL
        }
        
        init?(document: DocumentSnapshot) {
            guard let data = document.data(),
                  let id = data["id"] as? String,
                  let userId = data["userId"] as? String,
                  let userName = data["userName"] as? String,
                  let timestamp = data["timestamp"] as? Timestamp else {
                return nil
            }
            
            self.id = id
            self.userId = userId
            self.userName = userName
            self.text = data["text"] as? String
            self.timestamp = timestamp.dateValue()
            self.profileImageURL = data["profileImageURL"] as? String
            self.imageURL = data["imageURL"] as? String
        }
        
        func toDictionary() -> [String: Any] {
            var dict: [String: Any] = [
                "id": id,
                "userId": userId,
                "userName": userName,
                "timestamp": Timestamp(date: timestamp)
            ]
            
            if let text = text {
                dict["text"] = text
            }
            
            if let profileImageURL = profileImageURL {
                dict["profileImageURL"] = profileImageURL
            }
            
            if let imageURL = imageURL {
                dict["imageURL"] = imageURL
            }
            
            return dict
        }
        
        // Remove the toEventGroup method entirely
    }
}

// Add extension with type conversion methods outside the enum
extension EventGroup.Member {
    static func fromUserGroupMember(_ member: UserGroup.Member) -> EventGroup.Member {
        return EventGroup.Member(
            userId: member.userId,
            name: member.name,
            role: member.role,
            joinedAt: member.joinedAt,
            canChat: member.canChat,
            profileImageURL: member.profileImageURL
        )
    }
}

extension EventGroup.Message {
    static func fromUserGroupMessage(_ message: UserGroup.Message) -> EventGroup.Message {
        return EventGroup.Message(
            id: message.id,
            userId: message.userId,
            userName: message.userName,
            text: message.text,
            timestamp: message.timestamp,
            profileImageURL: message.profileImageURL,
            imageURL: message.imageURL
        )
    }
}
