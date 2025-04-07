import Foundation
import FirebaseFirestore

class EventGroupManager {
    private let db = Firestore.firestore()
    
    // MARK: - Group Creation
    func createEventGroup(eventId: String, organizerId: String, eventName: String, completion: @escaping (Bool) -> Void) {
        // Check if event group already exists
        let eventRef = db.collection("eventGroups").document(eventId)
        
        eventRef.getDocument { (snapshot, error) in
            if let error = error {
                print("Error checking for existing event group: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            // If event group already exists, don't create a new one
            if snapshot?.exists ?? false {
                completion(true)
                return
            }
            
            // Create new event group data
            let groupData: [String: Any] = [
                "eventId": eventId,
                "name": eventName,
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
                
                // Create event group with the first member
                let batch = self.db.batch()
                batch.setData(groupData, forDocument: eventRef)
                batch.setData(memberData, forDocument: eventRef.collection("members").document(organizerId))
                
                batch.commit { error in
                    if let error = error {
                        print("Error creating event group: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("Successfully created event group: \(eventId)")
                        completion(true)
                    }
                }
            }
        }
    }
    
    // MARK: - Member Management
    func addUserToEvent(eventId: String, userId: String, completion: @escaping (Bool) -> Void) {
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
            
            self.db.collection("eventGroups").document(eventId)
                .collection("members").document(userId)
                .setData(memberData) { error in
                    if let error = error {
                        print("Error adding user to event: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("Successfully added user \(userId) to event \(eventId)")
                        completion(true)
                    }
                }
        }
    }
    
    // MARK: - Member Removal
    func removeUserFromEvent(eventId: String, userId: String, completion: @escaping (Bool) -> Void) {
        db.collection("eventGroups").document(eventId)
            .collection("members").document(userId)
            .delete() { error in
                if let error = error {
                    print("Error removing user from event: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Successfully removed user \(userId) from event \(eventId)")
                    completion(true)
                }
            }
    }
    
    // MARK: - Member Permissions
    func updateMemberChatPermission(eventId: String, userId: String, canChat: Bool, completion: @escaping (Bool) -> Void) {
        db.collection("eventGroups").document(eventId)
            .collection("members").document(userId)
            .updateData(["canChat": canChat]) { error in
                if let error = error {
                    print("Error updating member chat permission: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Successfully updated chat permission for user \(userId) in event \(eventId)")
                    completion(true)
                }
            }
    }
    
    // MARK: - Event Settings
    func updateEventChatSettings(eventId: String, chatEnabled: Bool, completion: @escaping (Bool) -> Void) {
        db.collection("eventGroups").document(eventId)
            .updateData(["settings.chatEnabled": chatEnabled]) { error in
                if let error = error {
                    print("Error updating event chat settings: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Successfully updated chat settings for event \(eventId)")
                    completion(true)
                }
            }
    }
    
    // MARK: - Member Retrieval
    func getEventMembers(eventId: String, completion: @escaping ([EventGroup.Member]) -> Void) {
        db.collection("eventGroups").document(eventId)
            .collection("members")
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error fetching event members: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let members = documents.compactMap { document -> EventGroup.Member? in
                    let userId = document.documentID
                    
                    guard let role = document.data()["role"] as? String,
                          let joinedAt = document.data()["joinedAt"] as? Timestamp,
                          let canChat = document.data()["canChat"] as? Bool,
                          let name = document.data()["name"] as? String else {
                        return nil
                    }
                    
                    return EventGroup.Member(
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
