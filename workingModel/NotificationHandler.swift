import Foundation
import FirebaseFirestore
import FirebaseAuth

class NotificationHandler {
    
    static let shared = NotificationHandler()
    private let db = Firestore.firestore()
    
    // MARK: - Team Invitation Response
    func respondToTeamInvitation(notificationId: String, teamId: String, accept: Bool, completion: @escaping (Bool, String) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(false, "User not logged in")
            return
        }
        
        // First, get the notification to access team information
        db.collection("notifications").document(notificationId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let document = snapshot,
                  let data = document.data(),
                  let teamName = data["teamName"] as? String else {
                completion(false, "Could not fetch notification data")
                return
            }
            
            if accept {
                // Accept team invitation
                self.db.collection("hackathon_teams").document(teamId).updateData([
                    "members": FieldValue.arrayUnion([currentUser.uid]),
                    "pendingMembers": FieldValue.arrayRemove([currentUser.uid])
                ]) { error in
                    if let error = error {
                        completion(false, "Failed to join team: \(error.localizedDescription)")
                        return
                    }
                    
                    // Update notification as read
                    self.db.collection("notifications").document(notificationId).updateData([
                        "isRead": true,
                        "responseStatus": "accepted"
                    ])
                    
                    completion(true, "You have successfully joined team '\(teamName)'")
                }
            } else {
                // Reject team invitation
                self.db.collection("hackathon_teams").document(teamId).updateData([
                    "pendingMembers": FieldValue.arrayRemove([currentUser.uid])
                ]) { error in
                    if let error = error {
                        completion(false, "Failed to reject invitation: \(error.localizedDescription)")
                        return
                    }
                    
                    // Update notification as read
                    self.db.collection("notifications").document(notificationId).updateData([
                        "isRead": true,
                        "responseStatus": "declined"
                    ])
                    
                    completion(true, "You have declined the invitation to join team '\(teamName)'")
                }
            }
        }
    }
    
    // MARK: - Team Join Request Response
    func respondToTeamJoinRequest(notificationId: String, teamId: String, userId: String, accept: Bool, completion: @escaping (Bool, String) -> Void) {
        // First, get the notification to access relevant information
        db.collection("notifications").document(notificationId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let document = snapshot,
                  let data = document.data(),
                  let senderName = data["senderName"] as? String,
                  let teamName = data["teamName"] as? String else {
                completion(false, "Could not fetch notification data")
                return
            }
            
            if accept {
                // Accept join request
                self.db.collection("hackathon_teams").document(teamId).updateData([
                    "members": FieldValue.arrayUnion([userId]),
                    "pendingMembers": FieldValue.arrayRemove([userId])
                ]) { error in
                    if let error = error {
                        completion(false, "Failed to add member: \(error.localizedDescription)")
                        return
                    }
                    
                    // Update notification as read
                    self.db.collection("notifications").document(notificationId).updateData([
                        "isRead": true,
                        "responseStatus": "accepted"
                    ])
                    
                    // Send notification to the requester using existing model
                    let newNotificationData: [String: Any] = [
                        "title": "Team Request Accepted",
                        "message": "Your request to join team '\(teamName)' has been accepted",
                        "timestamp": FieldValue.serverTimestamp(),
                        "isRead": false,
                        "userId": userId,
                        "senderId": Auth.auth().currentUser?.uid ?? "",
                        "notificationType": "team_join_accepted",
                        "teamId": teamId,
                        "teamName": teamName
                    ]
                    
                    self.db.collection("notifications").addDocument(data: newNotificationData)
                    
                    completion(true, "You have accepted \(senderName)'s request to join your team")
                }
            } else {
                // Reject join request
                self.db.collection("hackathon_teams").document(teamId).updateData([
                    "pendingMembers": FieldValue.arrayRemove([userId])
                ]) { error in
                    if let error = error {
                        completion(false, "Failed to reject request: \(error.localizedDescription)")
                        return
                    }
                    
                    // Update notification as read
                    self.db.collection("notifications").document(notificationId).updateData([
                        "isRead": true,
                        "responseStatus": "declined"
                    ])
                    
                    // Send notification to the requester
                    let newNotificationData: [String: Any] = [
                        "title": "Team Request Declined",
                        "message": "Your request to join team '\(teamName)' has been declined",
                        "timestamp": FieldValue.serverTimestamp(),
                        "isRead": false,
                        "userId": userId,
                        "senderId": Auth.auth().currentUser?.uid ?? "",
                        "notificationType": "team_join_rejected",
                        "teamId": teamId,
                        "teamName": teamName
                    ]
                    
                    self.db.collection("notifications").addDocument(data: newNotificationData)
                    
                    completion(true, "You have declined \(senderName)'s request to join your team")
                }
            }
        }
    }
    
    // MARK: - Create Team Notification
    func sendTeamInvitations(teamId: String, teamName: String, eventId: String, eventName: String, members: [String], completion: @escaping (Bool) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(false)
            return
        }
        
        // Get user data for the team leader (current user)
        db.collection("users").document(currentUser.uid).getDocument { [weak self] documentSnapshot, error in
            guard let self = self,
                  let document = documentSnapshot,
                  let userData = document.data(),
                  let leaderName = userData["name"] as? String else {
                completion(false)
                return
            }
            
            let dispatchGroup = DispatchGroup()
            var successCount = 0
            
            for memberId in members {
                dispatchGroup.enter()
                
                let notificationData: [String: Any] = [
                    "title": "Team Invitation",
                    "message": "\(leaderName) has invited you to join team '\(teamName)' for \(eventName)",
                    "timestamp": FieldValue.serverTimestamp(),
                    "isRead": false,
                    "userId": memberId, // Important: Set the recipient userId
                    "senderId": currentUser.uid,
                    "senderName": leaderName,
                    "notificationType": "team_invitation",
                    "eventId": eventId,
                    "eventName": eventName,
                    "teamId": teamId,
                    "teamName": teamName
                ]
                
                self.db.collection("notifications").addDocument(data: notificationData) { error in
                    if error == nil {
                        successCount += 1
                    } else {
                        print("Error sending invitation to \(memberId): \(error!.localizedDescription)")
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion(successCount == members.count)
            }
        }
    }
    
    // MARK: - Send Join Request
    func sendTeamJoinRequest(teamId: String, teamName: String, teamLeaderId: String, eventId: String, eventName: String, completion: @escaping (Bool, String) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(false, "User not logged in")
            return
        }
        
        // Get current user's name
        db.collection("users").document(currentUser.uid).getDocument { [weak self] documentSnapshot, error in
            guard let self = self,
                  let document = documentSnapshot,
                  let userData = document.data(),
                  let userName = userData["name"] as? String else {
                completion(false, "Could not fetch user data")
                return
            }
            
            // Add user to pending members
            self.db.collection("hackathon_teams").document(teamId).updateData([
                "pendingMembers": FieldValue.arrayUnion([currentUser.uid])
            ]) { error in
                if let error = error {
                    completion(false, "Failed to send join request: \(error.localizedDescription)")
                    return
                }
                
                // Create notification for team leader
                let notificationData: [String: Any] = [
                    "title": "Team Join Request",
                    "message": "\(userName) has requested to join your team '\(teamName)' for \(eventName)",
                    "timestamp": FieldValue.serverTimestamp(),
                    "isRead": false,
                    "userId": teamLeaderId, // Set recipient as team leader
                    "senderId": currentUser.uid,
                    "senderName": userName,
                    "notificationType": "team_join_request",
                    "eventId": eventId,
                    "eventName": eventName,
                    "teamId": teamId,
                    "teamName": teamName
                ]
                
                self.db.collection("notifications").addDocument(data: notificationData) { error in
                    if let error = error {
                        completion(false, "Request sent but notification failed: \(error.localizedDescription)")
                    } else {
                        completion(true, "Your request to join team '\(teamName)' has been sent")
                    }
                }
            }
        }
    }
}
