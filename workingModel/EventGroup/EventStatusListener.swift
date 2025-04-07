//
//  EventStatusListener.swift
//  ThriveUp
//
//  Created by Sanidhya's MacBook Pro on 16/03/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class EventStatusListener {
    
    private let db = Firestore.firestore()
    private var listeners: [String: ListenerRegistration] = [:]
    private let eventGroupManager = EventGroupManager()
    
    // MARK: - Public Methods
    
    /// Start listening for event status changes
    func startListening() {
        // Listen for all events
        setupListenerForAllEvents()
    }
    
    /// Stop all listeners
    func stopListening() {
        for (_, listener) in listeners {
            listener.remove()
        }
        listeners.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func setupListenerForAllEvents() {
        // Listen for status changes on all events
        let listener = db.collection("events")
            .whereField("status", isEqualTo: "accepted")
            .addSnapshotListener { [weak self] (snapshot, error) in
                guard let self = self, let snapshot = snapshot else {
                    print("Error listening for event status changes: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                for change in snapshot.documentChanges {
                    // Only process modified documents that have just been accepted
                    if change.type == .modified || change.type == .added {
                        let eventData = change.document.data()
                        
                        if let eventId = eventData["eventId"] as? String,
                           let status = eventData["status"] as? String,
                           let organizerId = eventData["userId"] as? String,
                           status == "accepted" {
                            
                            // Create event group for the newly accepted event
                            self.handleAcceptedEvent(eventId: eventId, organizerId: organizerId)
                        }
                    }
                }
            }
        
        // Store the listener to be able to remove it later
        listeners["all_events"] = listener
    }

    
    private func handleAcceptedEvent(eventId: String, organizerId: String) {
        // Check if group already exists
        db.collection("eventGroups").document(eventId).getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error checking for existing group: \(error.localizedDescription)")
                return
            }
            
            // If group already exists, don't create a new one
            if document?.exists == true {
                print("Group already exists for event: \(eventId)")
                return
            }
            
            // Create a new group - directly implement the creation logic here
            self.createEventGroupInternal(for: eventId, organizerId: organizerId) { success in
                if success {
                    print("Created group for accepted event: \(eventId)")
                    
                    // Add all existing registrants to the group
                    self.addRegistrantsToGroup(eventId: eventId)
                } else {
                    print("Failed to create group for event: \(eventId)")
                }
            }
        }
    }
    
    // Implement the group creation internally since EventGroupManager doesn't have createEventGroup
    private func createEventGroupInternal(for eventId: String, organizerId: String, completion: @escaping (Bool) -> Void) {
        // Fetch event details
        db.collection("events").document(eventId).getDocument { [weak self] (snapshot, error) in
            guard let self = self else {
                completion(false)
                return
            }
            
            if let error = error {
                print("Error fetching event details: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let data = snapshot?.data(),
                  let eventName = data["title"] as? String else {
                print("Invalid event data")
                completion(false)
                return
            }
            
            // Create the group document
            let groupData: [String: Any] = [
                "eventId": eventId,
                "name": eventName,
                "createdAt": Timestamp(date: Date()),
                "organizerId": organizerId,
                "settings": [
                    "chatEnabled": true,
                    "memberCanInvite": false
                ],
                "imageURL": data["thumbnailURL"] as? String ?? ""
            ]
            
            self.db.collection("eventGroups").document(eventId).setData(groupData) { error in
                if let error = error {
                    print("Error creating event group: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                // Add organizer as a member with organizer role
                self.fetchUserDetails(userId: organizerId) { userData in
                    guard let userData = userData else {
                        print("Failed to fetch organizer details")
                        completion(false)
                        return
                    }
                    
                    let memberData: [String: Any] = [
                        "role": "organizer",
                        "joinedAt": Timestamp(date: Date()),
                        "canChat": true,
                        "name": userData["name"] as? String ?? "Organizer",
                        "profileImageURL": userData["profileImageURL"] as? String ?? ""
                    ]
                    
                    self.db.collection("eventGroups").document(eventId)
                        .collection("members").document(organizerId)
                        .setData(memberData) { error in
                            if let error = error {
                                print("Error adding organizer to group: \(error.localizedDescription)")
                                completion(false)
                            } else {
                                print("Successfully created event group and added organizer")
                                completion(true)
                            }
                        }
                }
            }
        }
    }
    
    private func addRegistrantsToGroup(eventId: String) {
        db.collection("registrations")
            .whereField("eventId", isEqualTo: eventId)
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching registrations: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                print("Found \(documents.count) registrations for event: \(eventId)")
                
                // Add each user to the event group
                for document in documents {
                    if let userId = document.data()["uid"] as? String {
                        // Skip if this is the organizer (already added)
                        if userId != self.getOrganizerId(for: eventId) {
                            self.addUserToGroup(eventId: eventId, userId: userId)
                        }
                    }
                }
            }
    }
    
    // Helper to get organizer ID
    private func getOrganizerId(for eventId: String) -> String? {
        // This would normally make a database call, but for simplicity
        // we'll return nil which means no user will be skipped
        return nil
    }
    
    // Add user to event group
    private func addUserToGroup(eventId: String, userId: String) {
        fetchUserDetails(userId: userId) { [weak self] userData in
            guard let self = self else { return }
            
            guard let userData = userData else {
                print("Failed to fetch user data for user: \(userId)")
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
                        print("Error adding user to event group: \(error.localizedDescription)")
                    } else {
                        print("Successfully added user \(userId) to event group \(eventId)")
                    }
                }
        }
    }
    
    // Helper method to fetch user details
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
