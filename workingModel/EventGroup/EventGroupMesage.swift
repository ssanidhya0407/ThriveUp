//
//  EventGroupMesage.swift
//  ThriveUp
//
//  Created by Sanidhya's MacBook Pro on 05/04/25.
//

import Foundation
import FirebaseFirestore

// Legacy non-namespaced class that MessageCell expects
class EventGroupMessage {
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
    
    // Factory method to create from EventGroup.Message
    static func fromEventGroupMessage(_ message: EventGroup.Message) -> EventGroupMessage {
        return EventGroupMessage(
            id: message.id,
            userId: message.userId,
            userName: message.userName,
            text: message.text,
            timestamp: message.timestamp,
            profileImageURL: message.profileImageURL,
            imageURL: message.imageURL
        )
    }
    
    // Factory method to create from UserGroup.Message
    static func fromUserGroupMessage(_ message: UserGroup.Message) -> EventGroupMessage {
        return EventGroupMessage(
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
