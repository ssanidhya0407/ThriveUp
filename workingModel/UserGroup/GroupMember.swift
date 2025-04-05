import Foundation
import FirebaseFirestore

// Use the UserGroup namespace declared in UserGroup.swift
// This file now contains just the manager
import Foundation
import FirebaseFirestore

// Use the UserGroup namespace declared in UserGroup.swift
// This file now contains just the manager

class UserGroupManager {
    private let db = Firestore.firestore()
    
    // MARK: - Group Creation
    func createUserGroup(groupId: String, adminId: String, groupName: String, completion: @escaping (Bool) -> Void) {
        // Check if group already exists
        let groupRef = db.collection("userGroups").document(groupId)
        
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
                "groupId": groupId,
                "name": groupName,
                "admin": adminId,
                "createdAt": Timestamp(date: Date()),
                "settings": [
                    "chatEnabled": true,
                    "membersCanInvite": false
                ]
            ]
            
            // Add the admin as the first member
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
                        print("Error creating user group: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("Successfully created user group: \(groupId)")
                        completion(true)
                    }
                }
            }
        }
    }
    
    // MARK: - Member Management
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
            
            self.db.collection("userGroups").document(groupId)
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
    
    // MARK: - Member Removal
    func removeUserFromGroup(groupId: String, userId: String, completion: @escaping (Bool) -> Void) {
        db.collection("userGroups").document(groupId)
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
    
    // MARK: - Member Permissions
    func updateMemberChatPermission(groupId: String, userId: String, canChat: Bool, completion: @escaping (Bool) -> Void) {
        db.collection("userGroups").document(groupId)
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
    
    // MARK: - Group Settings
    func updateGroupChatSettings(groupId: String, chatEnabled: Bool, completion: @escaping (Bool) -> Void) {
        db.collection("userGroups").document(groupId)
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
    
    // MARK: - Member Retrieval
    func getGroupMembers(groupId: String, completion: @escaping ([UserGroup.Member]) -> Void) {
        db.collection("userGroups").document(groupId)
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
                
                let members = documents.compactMap { document -> UserGroup.Member? in
                    let userId = document.documentID
                    
                    guard let role = document.data()["role"] as? String,
                          let joinedAt = document.data()["joinedAt"] as? Timestamp,
                          let canChat = document.data()["canChat"] as? Bool,
                          let name = document.data()["name"] as? String else {
                        return nil
                    }
                    
                    return UserGroup.Member(
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
    
    // MARK: - Helper Methods
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
