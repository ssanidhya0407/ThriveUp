////
////  EventStatusObserver.swift
////  ThriveUp
////
////  Created by Sanidhya's MacBook Pro on 16/03/25.
////
//
//
//import Foundation
//import FirebaseFirestore
//import FirebaseAuth
//
//class EventStatusObserver {
//    private let db = Firestore.firestore()
//    private var eventStatusListeners: [String: ListenerRegistration] = [:]
//    private let eventGroupManager = EventGroupManager()
//    
//    /// Start observing status changes for a specific event
//    func observeEventStatus(eventId: String) {
//        // Make sure we don't add multiple listeners for the same event
//        if eventStatusListeners[eventId] != nil {
//            return
//        }
//        
//        let listener = db.collection("events").document(eventId)
//            .addSnapshotListener { [weak self] (documentSnapshot, error) in
//                guard let self = self,
//                      let document = documentSnapshot,
//                      let data = document.data(),
//                      let status = data["status"] as? String,
//                      let userId = data["userId"] as? String else {
//                    return
//                }
//                
//                // If the event is approved, create a group and add the registrants
//                if status == "accepted" && document.exists {
//                    // Create a group for this event with the organizer as the first member
//                    self.createEventGroupIfNeeded(eventId: eventId, organizerId: userId)
//                    
//                    // Add all registrants to the group
//                    self.addRegistrantsToGroup(eventId: eventId)
//                    
//                    // Stop listening for this event as the group is now created
//                    self.stopObservingEventStatus(eventId: eventId)
//                }
//            }
//        
//        // Store the listener for later removal
//        eventStatusListeners[eventId] = listener
//    }
//    
//    /// Stop observing status changes for a specific event
//    func stopObservingEventStatus(eventId: String) {
//        if let listener = eventStatusListeners[eventId] {
//            listener.remove()
//            eventStatusListeners.removeValue(forKey: eventId)
//        }
//    }
//    
//    /// Create an event group if it doesn't already exist
//    private func createEventGroupIfNeeded(eventId: String, organizerId: String) {
//        eventGroupManager.createEventGroup(for: eventId, organizerId: organizerId) { success in
//            if success {
//                print("Event group created or already exists for event: \(eventId)")
//            } else {
//                print("Failed to create event group for event: \(eventId)")
//            }
//        }
//    }
//    
//    /// Add all users who have registered for the event to the event group
//    private func addRegistrantsToGroup(eventId: String) {
//        db.collection("registrations")
//            .whereField("eventId", isEqualTo: eventId)
//            .getDocuments { [weak self] (snapshot, error) in
//                guard let self = self else { return }
//                
//                if let error = error {
//                    print("Error fetching registrations: \(error.localizedDescription)")
//                    return
//                }
//                
//                guard let documents = snapshot?.documents, !documents.isEmpty else {
//                    print("No registrations found for event: \(eventId)")
//                    return
//                }
//                
//                // Add each registrant to the event group
//                for document in documents {
//                    if let userId = document["uid"] as? String {
//                        self.eventGroupManager.addUserToEventGroup(eventId: eventId, userId: userId) { success in
//                            if success {
//                                print("Added registrant \(userId) to event group \(eventId)")
//                            } else {
//                                print("Failed to add registrant \(userId) to event group")
//                            }
//                        }
//                    }
//                }
//            }
//    }
//    
//    /// Setup observers for all pending events
//    func setupObserversForPendingEvents() {
//        db.collection("events")
//            .whereField("status", isEqualTo: "pending")
//            .getDocuments { [weak self] (snapshot, error) in
//                guard let self = self else { return }
//                
//                if let error = error {
//                    print("Error fetching pending events: \(error.localizedDescription)")
//                    return
//                }
//                
//                guard let documents = snapshot?.documents else { return }
//                
//                for document in documents {
//                    if let eventId = document["eventId"] as? String {
//                        self.observeEventStatus(eventId: eventId)
//                    }
//                }
//            }
//    }
//}
