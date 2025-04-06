//
//  EventGroupManager.swift
//  ThriveUp
//
//  Created by Sanidhya's MacBook Pro on 05/04/25.
//


import Foundation
import FirebaseFirestore

class EventGroupManager {
    private let db = Firestore.firestore()
    
    // Get members from an event
    // Replace the getEventMembers method in EventGroupManager with this:
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
    
    // Add other relevant event group management methods here...
}
