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
            
            // Create a new group
            self.eventGroupManager.createEventGroup(for: eventId, organizerId: organizerId) { success in
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
                        self.eventGroupManager.addUserToEventGroup(eventId: eventId, userId: userId) { success in
                            if success {
                                print("Added user \(userId) to event group \(eventId)")
                            } else {
                                print("Failed to add user \(userId) to event group")
                            }
                        }
                    }
                }
            }
    }
}