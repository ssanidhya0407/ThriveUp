//
//  GroupMember.swift
//  ThriveUp
//
//  Created by Sanidhya's MacBook Pro on 05/04/25.
//


//
//  GroupMember.swift
//  ThriveUp
//
//  Created on 2025-04-04 22:47:47
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

struct GroupMember {
    var userId: String
    var name: String
    var role: String // "admin" or "member"
    var joinedAt: Date
    var canChat: Bool
    var profileImageURL: String?
}

struct GroupMessage {
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

struct GroupSettings {
    var chatEnabled: Bool
    var membersCanInvite: Bool
}

class GroupManager {
    private let db = Firestore.firestore()
    
    // MARK: - Group Creation
    
    /// Creates a new user group
    func createGroup(groupId: String, adminId: String, groupName: String, imageURL: String? = nil, completion: @escaping (Bool) -> Void) {
        // Check if group already exists
        let groupRef = db.collection("groups").document(groupId)
        
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
                "id": groupId,
                "name": groupName,
                "createdBy": adminId,
                "createdAt": Timestamp(date: Date()),
                "imageURL": imageURL ?? NSNull(),
                "settings": [
                    "chatEnabled": true,
                    "membersCanInvite": false
                ]
            ]
            
            // Add the creator as the first member (admin)
            self.fetchUserDetails(userId: adminId) { userData in
                var memberData: [String: Any] = [
                    "role": "admin",
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
                batch.setData(memberData, forDocument: groupRef.collection("members").document(adminId))
                
                batch.commit { error in
                    if let error = error {
                        print("Error creating group: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("Successfully created group: \(groupId)")
                        completion(true)
                    }
                }
            }
        }
    }
    
    // MARK: - Member Management
    
    /// Add a user to a group
    func addUserToGroup(groupId: String, userId: String, completion: @escaping (Bool) -> Void) {
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
                "profileImageURL": userData["profileImageURL"] as? String ?? ""
            ]
            
            self.db.collection("groups").document(groupId)
                .collection("members").document(userId)
                .setData(memberData) { error in
                    if let error = error {
                        print("Error adding user to group: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("Successfully added user \(userId) to group \(groupId)")
                        completion(true)
                    }
                }
        }
    }
    
    /// Remove a user from a group
    func removeUserFromGroup(groupId: String, userId: String, completion: @escaping (Bool) -> Void) {
        db.collection("groups").document(groupId)
            .collection("members").document(userId)
            .delete() { error in
                if let error = error {
                    print("Error removing user from group: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Successfully removed user \(userId) from group \(groupId)")
                    completion(true)
                }
            }
    }
    
    /// Update a member's chat permission in the group
    func updateMemberChatPermission(groupId: String, userId: String, canChat: Bool, completion: @escaping (Bool) -> Void) {
        db.collection("groups").document(groupId)
            .collection("members").document(userId)
            .updateData(["canChat": canChat]) { error in
                if let error = error {
                    print("Error updating member chat permission: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Successfully updated chat permission for user \(userId) in group \(groupId)")
                    completion(true)
                }
            }
    }
    
    /// Update group chat settings
    func updateGroupChatSettings(groupId: String, chatEnabled: Bool, completion: @escaping (Bool) -> Void) {
        db.collection("groups").document(groupId)
            .updateData(["settings.chatEnabled": chatEnabled]) { error in
                if let error = error {
                    print("Error updating group chat settings: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Successfully updated chat settings for group \(groupId)")
                    completion(true)
                }
            }
    }
    
    // MARK: - Chat Functions
    
    /// Send a message in the group chat
    func sendMessage(groupId: String, text: String? = nil, imageURL: String? = nil, completion: @escaping (Bool) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("No authenticated user found")
            completion(false)
            return
        }
        
        // Ensure either text or imageURL is provided
        guard text != nil || imageURL != nil else {
            print("Either text or image URL must be provided")
            completion(false)
            return
        }
        
        // First check if the user has permission to chat
        db.collection("groups").document(groupId)
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
                self.db.collection("groups").document(groupId)
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
                            var messageData: [String: Any] = [
                                "id": messageId,
                                "userId": currentUserId,
                                "userName": userData?["name"] as? String ?? "User",
                                "timestamp": Timestamp(date: Date()),
                                "profileImageURL": userData?["profileImageURL"] as? String ?? ""
                            ]
                            
                            // Add text if provided
                            if let text = text {
                                messageData["text"] = text
                            }
                            
                            // Add imageURL if provided
                            if let imageURL = imageURL {
                                messageData["imageURL"] = imageURL
                            }
                            
                            // Finally, send the message
                            self.db.collection("groups").document(groupId)
                                .collection("messages").document(messageId)
                                .setData(messageData) { error in
                                    if let error = error {
                                        print("Error sending message: \(error.localizedDescription)")
                                        completion(false)
                                    } else {
                                        print("Successfully sent message in group \(groupId)")
                                        completion(true)
                                    }
                                }
                        }
                    }
            }
    }
    
    /// Get messages from the group chat
    func getMessages(groupId: String, limit: Int = 50, completion: @escaping ([GroupMessage]) -> Void) {
        db.collection("groups").document(groupId)
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
                
                let messages = documents.compactMap { document -> GroupMessage? in
                    guard let id = document.data()["id"] as? String,
                          let userId = document.data()["userId"] as? String,
                          let userName = document.data()["userName"] as? String,
                          let timestamp = document.data()["timestamp"] as? Timestamp else {
                        return nil
                    }
                    
                    return GroupMessage(
                        id: id,
                        userId: userId,
                        userName: userName,
                        text: document.data()["text"] as? String,
                        timestamp: timestamp.dateValue(),
                        profileImageURL: document.data()["profileImageURL"] as? String,
                        imageURL: document.data()["imageURL"] as? String
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
    
    /// Get all members of a group
    func getGroupMembers(groupId: String, completion: @escaping ([GroupMember]) -> Void) {
        db.collection("groups").document(groupId)
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
                
                let members = documents.compactMap { document -> GroupMember? in
                    let userId = document.documentID
                    
                    guard let role = document.data()["role"] as? String,
                          let joinedAt = document.data()["joinedAt"] as? Timestamp,
                          let canChat = document.data()["canChat"] as? Bool,
                          let name = document.data()["name"] as? String else {
                        return nil
                    }
                    
                    return GroupMember(
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