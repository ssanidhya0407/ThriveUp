//
//  EventNotificationService.swift
//  ThriveUp
//
//  Created by Sanidhya's MacBook Pro on 07/04/25.
//


import Foundation
import FirebaseFirestore
import FirebaseAuth

class EventNotificationService {
    static let shared = EventNotificationService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // Send notifications to friends when a user registers for an event
    func notifyFriendsAboutEventRegistration(
        eventId: String, 
        eventName: String, 
        eventImageURL: String? = nil,
        completion: @escaping (Bool) -> Void
    ) {
        print("🔔 Starting notification process for event: \(eventName)")
        
        // Ensure user is authenticated
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ Error: No authenticated user found")
            completion(false)
            return
        }
        
        print("👤 Current user ID: \(currentUser.uid)")
        
        // Get current user's details
        getUserDetails(userId: currentUser.uid) { [weak self] currentUserDetails in
            guard let self = self else {
                print("❌ Error: Self is nil")
                completion(false)
                return
            }
            
            guard let userDetails = currentUserDetails else {
                print("❌ Error: Could not fetch current user details")
                completion(false)
                return
            }
            
            print("👤 Found user details for: \(userDetails.name)")
            
            // Get the user's friends
            self.getUserFriends(userId: currentUser.uid) { friends in
                print("👥 Found \(friends.count) friends for notification")
                
                if friends.isEmpty {
                    print("⚠️ Warning: No friends found to notify")
                    // If there are no friends to notify, we still consider this a success
                    completion(true)
                    return
                }
                
                // Create a notification for each friend
                let batch = self.db.batch()
                var notificationRefs: [DocumentReference] = []
                
                for (index, friend) in friends.enumerated() {
                    print("📩 Creating notification for friend[\(index)]: \(friend.name) (ID: \(friend.id))")
                    
                    // Create a new document reference
                    let notificationRef = self.db.collection("notifications").document()
                    notificationRefs.append(notificationRef)
                    
                    // Create notification data
                    let notificationData: [String: Any] = [
                        "userId": friend.id,
                        "senderId": currentUser.uid,
                        "senderName": userDetails.name,
                        "senderImageURL": userDetails.profileImageURL ?? "",
                        "title": "\(userDetails.name) is going to an event!",
                        "message": "\(userDetails.name) just registered for \(eventName). Join them!",
                        "type": "event",
                        "eventId": eventId,
                        "eventName": eventName,
                        "eventImageURL": eventImageURL ?? "",
                        "timestamp": FieldValue.serverTimestamp(),
                        "isRead": false
                    ]
                    
                    // Add to batch
                    batch.setData(notificationData, forDocument: notificationRef)
                }
                
                // Commit the batch
                batch.commit { error in
                    if let error = error {
                        print("❌ Batch write error: \(error.localizedDescription)")
                        completion(false)
                        return
                    }
                    
                    print("✅ Successfully sent \(notificationRefs.count) notifications")
                    
                    // Additional verification - check if notifications were actually created
                    self.verifyNotificationsCreated(references: notificationRefs) { verified in
                        if verified {
                            print("✅ Verification passed - notifications exist in the database")
                        } else {
                            print("⚠️ Verification failed - some notifications may not exist")
                        }
                        completion(verified)
                    }
                }
            }
        }
    }
    
    // Verify that the notifications were actually created
    private func verifyNotificationsCreated(references: [DocumentReference], completion: @escaping (Bool) -> Void) {
        guard !references.isEmpty else {
            completion(false)
            return
        }
        
        // Take up to 5 references to verify
        let samplesToCheck = min(references.count, 5)
        let referencesToCheck = Array(references.prefix(samplesToCheck))
        
        let group = DispatchGroup()
        var allExist = true
        
        for ref in referencesToCheck {
            group.enter()
            
            ref.getDocument { snapshot, error in
                defer { group.leave() }
                
                if let error = error {
                    print("❌ Verification error for \(ref.documentID): \(error.localizedDescription)")
                    allExist = false
                    return
                }
                
                if snapshot?.exists != true {
                    print("❌ Document \(ref.documentID) does not exist")
                    allExist = false
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(allExist)
        }
    }
    
    // Explicitly add a method to directly create a notification for testing
    func createTestNotification(completion: @escaping (Bool) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ Test failed: No authenticated user")
            completion(false)
            return
        }
        
        let testData: [String: Any] = [
            "userId": currentUser.uid,
            "senderId": currentUser.uid,
            "senderName": "Test User",
            "title": "Test Notification",
            "message": "This is a test notification",
            "type": "test",
            "timestamp": FieldValue.serverTimestamp(),
            "isRead": false
        ]
        
        db.collection("notifications").addDocument(data: testData) { error in
            if let error = error {
                print("❌ Test notification error: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            print("✅ Test notification created successfully")
            completion(true)
        }
    }
    
    private func getUserDetails(userId: String, completion: @escaping (UserProfile?) -> Void) {
        print("🔍 Fetching user details for ID: \(userId)")
        
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("❌ Error getting user details: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                print("❌ User document doesn't exist for ID: \(userId)")
                completion(nil)
                return
            }
            
            guard let data = snapshot.data() else {
                print("❌ No data in user document for ID: \(userId)")
                completion(nil)
                return
            }
            
            // Handle potential missing fields with detailed logging
            let displayName = data["displayName"] as? String
            if displayName == nil { print("⚠️ Missing displayName for user: \(userId)") }
            
            let email = data["email"] as? String
            if email == nil { print("⚠️ Missing email for user: \(userId)") }
            
            let profileImageURL = data["profileImageURL"] as? String
            if profileImageURL == nil { print("⚠️ Missing profileImageURL for user: \(userId)") }
            
            let userProfile = UserProfile(
                id: userId,
                name: displayName ?? "Unknown User",
                profileImageURL: profileImageURL
            )
            
            print("✅ Successfully fetched user details for: \(userProfile.name)")
            completion(userProfile)
        }
    }
    
    private func getUserFriends(userId: String, completion: @escaping ([UserProfile]) -> Void) {
        print("🔍 Fetching friends for user ID: \(userId)")
        
        // Query the friends collection where userId matches the current user's ID
        db.collection("friends")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching friends: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("❌ No friend documents found for user: \(userId)")
                    completion([])
                    return
                }
                
                print("📄 Found \(documents.count) friend documents")
                
                // Debug each document
                for (index, doc) in documents.enumerated() {
                    print("📄 Friend document[\(index)]: ID=\(doc.documentID), data=\(doc.data())")
                }
                
                let group = DispatchGroup()
                var friendProfiles: [UserProfile] = []
                
                for document in documents {
                    // Get the friendId field from each document
                    if let friendId = document.data()["friendId"] as? String {
                        print("👥 Processing friend ID: \(friendId) from document: \(document.documentID)")
                        group.enter()
                        
                        // Fetch details for each friend
                        self.getUserDetails(userId: friendId) { userProfile in
                            if let profile = userProfile {
                                print("✅ Added friend profile: \(profile.name)")
                                friendProfiles.append(profile)
                            } else {
                                print("⚠️ Failed to get profile for friend ID: \(friendId)")
                            }
                            group.leave()
                        }
                    } else {
                        print("⚠️ Missing friendId in document: \(document.documentID)")
                    }
                }
                
                group.notify(queue: .main) {
                    print("👥 Returning \(friendProfiles.count) friend profiles")
                    completion(friendProfiles)
                }
            }
    }
}

// Helper struct for user profiles
