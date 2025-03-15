//
//  EventGroupMember.swift
//  ThriveUp
//
//  Created by Sanidhya's MacBook Pro on 16/03/25.
//


import Foundation
import FirebaseFirestore
import FirebaseAuth

struct EventGroupMember {
    var userId: String
    var name: String
    var role: String // "organizer" or "member"
    var joinedAt: Date
    var canChat: Bool
    var profileImageURL: String?
}


struct EventGroupMessage {
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
}

struct EventGroupSettings {
    var chatEnabled: Bool
    var membersCanInvite: Bool
}

class EventGroupManager {
    private let db = Firestore.firestore()
    
    // MARK: - Group Creation
    
    /// Creates a new event group when an event is approved
    func createEventGroup(for eventId: String, organizerId: String, completion: @escaping (Bool) -> Void) {
        // Check if group already exists
        let groupRef = db.collection("eventGroups").document(eventId)
        
        groupRef.getDocument { (snapshot, error) in
            if let error = error {
                print("Error checking for existing group: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            // If group already exists, don't create a new one
            if snapshot?.exists ?? false {
                completion(true)
                return
            }
            
            // Create new group data
            let groupData: [String: Any] = [
                "eventId": eventId,
                "organizer": organizerId,
                "createdAt": Timestamp(date: Date()),
                "settings": [
                    "chatEnabled": true,
                    "membersCanInvite": false
                ]
            ]
            
            // Add the organizer as the first member
            self.fetchUserDetails(userId: organizerId) { userData in
                var memberData: [String: Any] = [
                    "role": "organizer",
                    "joinedAt": Timestamp(date: Date()),
                    "canChat": true
                ]
                
                if let name = userData?["name"] as? String {
                    memberData["name"] = name
                }
                
                if let profileImage = userData?["profileImage"] as? String {
                    memberData["profileImageURL"] = profileImage
                }
                
                // Create group with the first member
                let batch = self.db.batch()
                batch.setData(groupData, forDocument: groupRef)
                batch.setData(memberData, forDocument: groupRef.collection("members").document(organizerId))
                
                batch.commit { error in
                    if let error = error {
                        print("Error creating event group: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("Successfully created event group for event: \(eventId)")
                        completion(true)
                    }
                }
            }
        }
    }
    
    // MARK: - Member Management
    
    /// Add a user to an event group when they register for the event
    func addUserToEventGroup(eventId: String, userId: String, completion: @escaping (Bool) -> Void) {
        fetchUserDetails(userId: userId) { userData in
            guard let userData = userData else {
                print("Failed to fetch user data for user: \(userId)")
                completion(false)
                return
            }
            
            let memberData: [String: Any] = [
                "role": "member",
                "joinedAt": Timestamp(date: Date()),
                "canChat": true,
                "name": userData["name"] as? String ?? "User",
                "profileImageURL": userData["profileImage"] as? String ?? ""
            ]
            
            self.db.collection("eventGroups").document(eventId)
                .collection("members").document(userId)
                .setData(memberData) { error in
                    if let error = error {
                        print("Error adding user to event group: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("Successfully added user \(userId) to event group \(eventId)")
                        completion(true)
                    }
                }
        }
    }
    
    /// Remove a user from an event group
    func removeUserFromEventGroup(eventId: String, userId: String, completion: @escaping (Bool) -> Void) {
        db.collection("eventGroups").document(eventId)
            .collection("members").document(userId)
            .delete() { error in
                if let error = error {
                    print("Error removing user from event group: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Successfully removed user \(userId) from event group \(eventId)")
                    completion(true)
                }
            }
    }
    
    /// Update a member's chat permission in the group
    func updateMemberChatPermission(eventId: String, userId: String, canChat: Bool, completion: @escaping (Bool) -> Void) {
        db.collection("eventGroups").document(eventId)
            .collection("members").document(userId)
            .updateData(["canChat": canChat]) { error in
                if let error = error {
                    print("Error updating member chat permission: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Successfully updated chat permission for user \(userId) in event group \(eventId)")
                    completion(true)
                }
            }
    }
    
    /// Update group chat settings
    func updateGroupChatSettings(eventId: String, chatEnabled: Bool, completion: @escaping (Bool) -> Void) {
        db.collection("eventGroups").document(eventId)
            .updateData(["settings.chatEnabled": chatEnabled]) { error in
                if let error = error {
                    print("Error updating group chat settings: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Successfully updated chat settings for event group \(eventId)")
                    completion(true)
                }
            }
    }
    
    // MARK: - Chat Functions
    
    /// Send a message in the event group chat
    func sendMessage(eventId: String, text: String, completion: @escaping (Bool) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("No authenticated user found")
            completion(false)
            return
        }
        
        // First check if the user has permission to chat
        db.collection("eventGroups").document(eventId)
            .collection("members").document(currentUserId)
            .getDocument { (snapshot, error) in
                if let error = error {
                    print("Error checking member permissions: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                guard let data = snapshot?.data(),
                      let canChat = data["canChat"] as? Bool,
                      canChat == true else {
                    print("User does not have permission to chat in this group")
                    completion(false)
                    return
                }
                
                // Then check if group chat is enabled
                self.db.collection("eventGroups").document(eventId)
                    .getDocument { (snapshot, error) in
                        if let error = error {
                            print("Error checking group settings: \(error.localizedDescription)")
                            completion(false)
                            return
                        }
                        
                        guard let groupData = snapshot?.data(),
                              let settings = groupData["settings"] as? [String: Any],
                              let chatEnabled = settings["chatEnabled"] as? Bool,
                              chatEnabled == true else {
                            print("Chat is disabled for this group")
                            completion(false)
                            return
                        }
                        
                        // Now fetch user details to include in the message
                        self.fetchUserDetails(userId: currentUserId) { userData in
                            let messageId = UUID().uuidString
                            let messageData: [String: Any] = [
                                "id": messageId,
                                "userId": currentUserId,
                                "userName": userData?["name"] as? String ?? "User",
                                "text": text,
                                "timestamp": Timestamp(date: Date()),
                                "profileImageURL": userData?["profileImage"] as? String ?? ""
                            ]
                            
                            // Finally, send the message
                            self.db.collection("eventGroups").document(eventId)
                                .collection("messages").document(messageId)
                                .setData(messageData) { error in
                                    if let error = error {
                                        print("Error sending message: \(error.localizedDescription)")
                                        completion(false)
                                    } else {
                                        print("Successfully sent message in event group \(eventId)")
                                        completion(true)
                                    }
                                }
                        }
                    }
            }
    }
    
    /// Get messages from the event group chat
    func getMessages(eventId: String, limit: Int = 50, completion: @escaping ([EventGroupMessage]) -> Void) {
        db.collection("eventGroups").document(eventId)
            .collection("messages")
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error fetching messages: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let messages = documents.compactMap { document -> EventGroupMessage? in
                    guard let id = document.data()["id"] as? String,
                          let userId = document.data()["userId"] as? String,
                          let userName = document.data()["userName"] as? String,
                          let text = document.data()["text"] as? String,
                          let timestamp = document.data()["timestamp"] as? Timestamp else {
                        return nil
                    }
                    
                    return EventGroupMessage(
                        id: id,
                        userId: userId,
                        userName: userName,
                        text: text,
                        timestamp: timestamp.dateValue(),
                        profileImageURL: document.data()["profileImageURL"] as? String
                    )
                }
                
                completion(messages)
            }
    }
    
    // MARK: - Helper Methods
    
    /// Fetch user details from Firestore
    private func fetchUserDetails(userId: String, completion: @escaping ([String: Any]?) -> Void) {
        db.collection("users").document(userId).getDocument { (snapshot, error) in
            if let error = error {
                print("Error fetching user details: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = snapshot?.data() else {
                completion(nil)
                return
            }
            
            completion(data)
        }
    }
    
    // MARK: - Group Members Fetching
    
    /// Get all members of an event group
    func getGroupMembers(eventId: String, completion: @escaping ([EventGroupMember]) -> Void) {
        db.collection("eventGroups").document(eventId)
            .collection("members")
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error fetching group members: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let members = documents.compactMap { document -> EventGroupMember? in
                    let userId = document.documentID
                    
                    guard let role = document.data()["role"] as? String,
                          let joinedAt = document.data()["joinedAt"] as? Timestamp,
                          let canChat = document.data()["canChat"] as? Bool,
                          let name = document.data()["name"] as? String else {
                        return nil
                    }
                    
                    return EventGroupMember(
                        userId: userId,
                        name: name,
                        role: role,
                        joinedAt: joinedAt.dateValue(),
                        canChat: canChat,
                        profileImageURL: document.data()["profileImageURL"] as? String
                    )
                }
                
                completion(members)
            }
    }
}
