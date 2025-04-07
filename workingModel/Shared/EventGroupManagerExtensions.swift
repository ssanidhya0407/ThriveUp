import Foundation
import FirebaseFirestore

// Extension to bridge between old and new APIs
extension EventGroupManager {
    
    // MARK: - Compatibility methods for old member-related APIs
    
    /// Compatibility method for old group members API
    func getGroupMembersCompat(groupId: String, completion: @escaping ([EventGroupMember]) -> Void) {
        // Call the new namespaced version
        getEventMembers(eventId: groupId) { members in
            // Convert from namespaced version to old version
            let oldStyleMembers = members.map { member -> EventGroupMember in
                return EventGroupMember(
                    userId: member.userId,
                    name: member.name,
                    role: member.role,
                    joinedAt: member.joinedAt,
                    canChat: member.canChat,
                    profileImageURL: member.profileImageURL
                )
            }
            completion(oldStyleMembers)
        }
    }
    
    // Another compatibility method for a different signature
    func getGroupMembersWithFilter(groupId: String, filterRole: String? = nil, completion: @escaping ([EventGroupMember]) -> Void) {
        // Call the new namespaced version
        getEventMembers(eventId: groupId) { members in
            // Convert and filter
            let filteredMembers = members
                .filter { filterRole == nil || $0.role == filterRole }
                .map { member -> EventGroupMember in
                    return EventGroupMember(
                        userId: member.userId,
                        name: member.name,
                        role: member.role,
                        joinedAt: member.joinedAt,
                        canChat: member.canChat,
                        profileImageURL: member.profileImageURL
                    )
                }
            completion(filteredMembers)
        }
    }
    
    // User management compatibility method
    func addUserToEventGroupCompat(groupId: String, userId: String, role: String = "member", completion: @escaping (Bool) -> Void) {
        // Implement or call the actual method
        addUserToEvent(eventId: groupId, userId: userId, role: role, completion: completion)
    }
    
    // Add the actual implementation
    func addUserToEvent(eventId: String, userId: String, role: String, completion: @escaping (Bool) -> Void) {
        fetchUserDetails(userId: userId) { userData in
            guard let userData = userData else {
                print("Failed to fetch user data for user: \(userId)")
                completion(false)
                return
            }
            
            let memberData: [String: Any] = [
                "role": role,
                "joinedAt": Timestamp(date: Date()),
                "canChat": true,
                "name": userData["name"] as? String ?? "User",
                "profileImageURL": userData["profileImageURL"] as? String ?? ""
            ]
            
            Firestore.firestore().collection("eventGroups").document(eventId)
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
    
    // Message sending compatibility method
    func sendMessageCompat(eventId: String, userId: String, text: String? = nil, imageURL: String? = nil, completion: @escaping (Bool, String?) -> Void) {
        // Use the existing messageManager to send
        let messageManager = EventGroupMessageManager()
        messageManager.sendMessage(eventId: eventId, userId: userId, text: text, imageURL: imageURL, completion: completion)
    }
    
    // Helper method
    private func fetchUserDetails(userId: String, completion: @escaping ([String: Any]?) -> Void) {
        Firestore.firestore().collection("users").document(userId).getDocument { (snapshot, error) in
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
