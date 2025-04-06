import Foundation
import FirebaseFirestore

// Use the UserGroup namespace declared in UserGroup.swift
// This file now contains just the message manager
import Foundation
import FirebaseFirestore

class GroupMessageManager {
    private let db = Firestore.firestore()
    
    // Send a message to a group
    func sendMessage(groupId: String, userId: String, text: String? = nil, imageURL: String? = nil, completion: @escaping (Bool, String?) -> Void) {
        // Ensure either text or imageURL is provided
        guard text != nil || imageURL != nil else {
            completion(false, "No message content provided")
            return
        }
        
        // Check if user can send messages
        checkUserPermissionsAndSendMessage(
            groupId: groupId,
            userId: userId,
            text: text,
            imageURL: imageURL,
            completion: completion
        )
    }
    
    private func checkUserPermissionsAndSendMessage(
        groupId: String,
        userId: String,
        text: String?,
        imageURL: String?,
        completion: @escaping (Bool, String?) -> Void
    ) {
        db.collection("groups").document(groupId)
            .collection("members").document(userId)
            .getDocument { [weak self] (snapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    completion(false, "Error checking member permissions: \(error.localizedDescription)")
                    return
                }
                
                guard let data = snapshot?.data(),
                      let canChat = data["canChat"] as? Bool,
                      canChat == true else {
                    completion(false, "You don't have permission to chat in this group")
                    return
                }
                
                // Check if group chat is enabled
                self.db.collection("groups").document(groupId)
                    .getDocument { [weak self] (snapshot, error) in
                        guard let self = self else { return }
                        
                        if let error = error {
                            completion(false, "Error checking group settings: \(error.localizedDescription)")
                            return
                        }
                        
                        guard let groupData = snapshot?.data(),
                              let settings = groupData["settings"] as? [String: Any],
                              let chatEnabled = settings["chatEnabled"] as? Bool,
                              chatEnabled == true else {
                            completion(false, "Chat is disabled for this group")
                            return
                        }
                        
                        // Now send the message
                        self.fetchUserDetailsAndSendMessage(
                            groupId: groupId,
                            userId: userId,
                            text: text,
                            imageURL: imageURL,
                            completion: completion
                        )
                    }
            }
    }
    
    private func fetchUserDetailsAndSendMessage(
        groupId: String,
        userId: String,
        text: String?,
        imageURL: String?,
        completion: @escaping (Bool, String?) -> Void
    ) {
        fetchUserDetails(userId: userId) { [weak self] userData in
            guard let self = self else { return }
            
            let messageId = UUID().uuidString
            var messageData: [String: Any] = [
                "id": messageId,
                "userId": userId,
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
            
            // Send the message
            self.db.collection("groups").document(groupId)
                .collection("messages").document(messageId)
                .setData(messageData) { error in
                    if let error = error {
                        completion(false, "Error sending message: \(error.localizedDescription)")
                    } else {
                        completion(true, messageId)
                    }
                }
        }
    }
    
    // Get messages from a group
    func getMessages(groupId: String, limit: Int = 50, completion: @escaping ([UserGroup.Message]) -> Void) {
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
                
                let messages = documents.compactMap { document -> UserGroup.Message? in
                    return UserGroup.Message(document: document)
                }
                
                completion(messages)
            }
    }
    
    // Set up a real-time listener for messages
    func addMessageListener(groupId: String, limit: Int = 50, completion: @escaping ([UserGroup.Message]) -> Void) -> ListenerRegistration {
        return db.collection("groups").document(groupId)
            .collection("messages")
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .addSnapshotListener { (snapshot, error) in
                if let error = error {
                    print("Error listening for messages: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let messages = documents.compactMap { document -> UserGroup.Message? in
                    return UserGroup.Message(document: document)
                }
                
                completion(messages)
            }
    }
    
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
}
