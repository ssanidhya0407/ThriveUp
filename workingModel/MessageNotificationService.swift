import UIKit
import FirebaseFirestore
import FirebaseAuth

class MessageNotificationService {
    
    static let shared = MessageNotificationService()
    private let db = Firestore.firestore()
    private var chatListeners: [String: ListenerRegistration] = [:]
    private var mainListener: ListenerRegistration?
    private var processedMessageIds = Set<String>() // Track processed message IDs
    private let lastProcessedMessagesKey = "lastProcessedMessagesTimestamp" // UserDefaults key
    
    private init() {}
    
    // Start listening for new messages across all user's chats
    func startListeningForNewMessages() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("User not authenticated.")
            return
        }
        
        // Remove any existing listeners
        removeAllListeners()
        
        // Clear the processed messages set when restarting
        processedMessageIds.removeAll()
        
        // Get the last time we processed messages
        let lastProcessedTimestamp = getLastProcessedTimestamp(for: currentUserId)
        
        // Listen to chats collection where the current user is a participant
        mainListener = db.collection("chats").whereField("participants", arrayContains: currentUserId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let snapshot = snapshot else {
                    print("Error listening for chat updates: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                // Process document changes
                for change in snapshot.documentChanges {
                    // Only process new or modified documents
                    if change.type == .added || change.type == .modified {
                        let chatId = change.document.documentID
                        self.listenForNewMessagesInChat(chatId: chatId, currentUserId: currentUserId, lastProcessedTimestamp: lastProcessedTimestamp)
                    }
                }
            }
    }
    
    private func listenForNewMessagesInChat(chatId: String, currentUserId: String, lastProcessedTimestamp: Date) {
        // Remove existing listener for this chat if there is one
        if let existingListener = chatListeners[chatId] {
            existingListener.remove()
            chatListeners.removeValue(forKey: chatId)
        }
        
        // Get the chat document to retrieve participants
        db.collection("chats").document(chatId).getDocument { [weak self] document, error in
            guard let self = self,
                  let document = document,
                  let chatData = document.data(),
                  let participants = chatData["participants"] as? [String] else {
                print("Error fetching chat document: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // Set up listener for new messages in this chat
            // Only listen for messages newer than the last processed timestamp
            let messagesRef = db.collection("chats").document(chatId).collection("messages")
                .whereField("timestamp", isGreaterThan: lastProcessedTimestamp) // Only get new messages
                .order(by: "timestamp", descending: true)
            
            // Store the listener so we can remove it later if needed
            let listener = messagesRef
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self,
                          let snapshot = snapshot else {
                        return
                    }
                    
                    var latestTimestamp = lastProcessedTimestamp
                    
                    // Process only added documents (new messages)
                    for change in snapshot.documentChanges where change.type == .added {
                        let messageData = change.document.data()
                        let messageId = change.document.documentID
                        
                        // Skip if we've already processed this message
                        if self.processedMessageIds.contains(messageId) {
                            continue
                        }
                        
                        // Add to processed set
                        self.processedMessageIds.insert(messageId)
                        
                        // Update latest timestamp if newer
                        if let timestamp = (messageData["timestamp"] as? Timestamp)?.dateValue(),
                           timestamp > latestTimestamp {
                            latestTimestamp = timestamp
                        }
                        
                        // Check if this message was sent by someone else
                        if let senderId = messageData["senderId"] as? String,
                           senderId != currentUserId, // Skip if the current user is the sender
                           let messageContent = messageData["messageContent"] as? String {
                            
                            // For each participant except the sender, create a notification
                            for participantId in participants where participantId != senderId {
                                // Only send notification to the current user
                                if participantId == currentUserId {
                                    self.getUserName(userId: senderId) { senderName in
                                        let notificationTitle = "\(senderName) sent you a message"
                                        
                                        // Create notification in Firestore
                                        self.createNotification(
                                            for: participantId,
                                            title: notificationTitle,
                                            message: messageContent,
                                            chatId: chatId,
                                            messageId: messageId,
                                            senderId: senderId
                                        )
                                    }
                                }
                            }
                        }
                    }
                    
                    // Save the latest timestamp to UserDefaults
                    if latestTimestamp > lastProcessedTimestamp {
                        self.saveLastProcessedTimestamp(latestTimestamp, for: currentUserId)
                    }
                }
            
            // Store the listener reference
            self.chatListeners[chatId] = listener
        }
    }
    
    private func getLastProcessedTimestamp(for userId: String) -> Date {
        // Get the last processed timestamp from UserDefaults, default to a date in the past
        let userDefaults = UserDefaults.standard
        let timestampKey = "\(lastProcessedMessagesKey)_\(userId)"
        
        // Instead of using if let with double(forKey:), we need to check if the key exists
        if userDefaults.object(forKey: timestampKey) != nil {
            let timestamp = userDefaults.double(forKey: timestampKey)
            if timestamp > 0 {
                return Date(timeIntervalSince1970: timestamp)
            }
        }
        
        // Default to current time minus 24 hours (only process last day's messages)
        return Date().addingTimeInterval(-24 * 60 * 60)
    }
    
    private func saveLastProcessedTimestamp(_ timestamp: Date, for userId: String) {
        // Save the timestamp to UserDefaults
        let userDefaults = UserDefaults.standard
        let timestampKey = "\(lastProcessedMessagesKey)_\(userId)"
        userDefaults.set(timestamp.timeIntervalSince1970, forKey: timestampKey)
    }
    
    private func getUserName(userId: String, completion: @escaping (String) -> Void) {
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists,
               let name = document.data()?["name"] as? String {
                completion(name)
            } else {
                completion("Someone") // Default name if user not found
            }
        }
    }
    
    private func createNotification(for userId: String, title: String, message: String,
                                   chatId: String, messageId: String, senderId: String) {
        let notificationData: [String: Any] = [
            "userId": userId,
            "title": title,
            "message": message,
            "timestamp": FieldValue.serverTimestamp(),
            "isRead": false,
            "chatId": chatId,
            "messageId": messageId,
            "senderId": senderId
        ]
        
        db.collection("notifications").addDocument(data: notificationData) { error in
            if let error = error {
                print("Error creating notification: \(error.localizedDescription)")
            } else {
                print("Notification created successfully for user \(userId)")
                
                // Update unread message count for the chat
                self.incrementUnreadCount(chatId: chatId, userId: userId)
            }
        }
    }
    
    // Increment unread message count for this chat
    private func incrementUnreadCount(chatId: String, userId: String) {
        // Reference to the user-specific chat metadata
        let userChatRef = self.db.collection("users").document(userId)
            .collection("chats").document(chatId)
        
        // Use a transaction to safely increment the counter
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let userChatDocument: DocumentSnapshot
            do {
                try userChatDocument = transaction.getDocument(userChatRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            // If document exists, increment the count, otherwise create it with count 1
            let newCount = (userChatDocument.data()?["unreadCount"] as? Int ?? 0) + 1
            
            if userChatDocument.exists {
                transaction.updateData(["unreadCount": newCount], forDocument: userChatRef)
            } else {
                transaction.setData(["unreadCount": newCount], forDocument: userChatRef)
            }
            
            return nil
        }) { (object, error) in
            if let error = error {
                print("Error updating unread count: \(error.localizedDescription)")
            }
        }
    }
    
    // Method to mark all messages in a chat as read
    func markAllMessagesAsRead(chatId: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        // Update the unread count in the user's chat metadata
        let userChatRef = db.collection("users").document(userId)
            .collection("chats").document(chatId)
        
        userChatRef.updateData([
            "unreadCount": 0
        ]) { error in
            if let error = error {
                print("Error marking messages as read: \(error.localizedDescription)")
            }
        }
        
        // Mark all notifications for this chat as read
        db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .whereField("chatId", isEqualTo: chatId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else {
                    if let error = error {
                        print("Error getting notifications: \(error.localizedDescription)")
                    }
                    return
                }
                
                let batch = self.db.batch()
                for document in documents {
                    batch.updateData(["isRead": true], forDocument: document.reference)
                }
                
                batch.commit { error in
                    if let error = error {
                        print("Error updating notifications: \(error.localizedDescription)")
                    }
                }
            }
    }
    
    // Delete all notifications for the current user
    func deleteAllNotifications(completion: @escaping (Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "MessageNotificationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
            return
        }
        
        db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    completion(error)
                    return
                }
                
                guard let self = self, let documents = snapshot?.documents else {
                    completion(nil)
                    return
                }
                
                if documents.isEmpty {
                    completion(nil)
                    return
                }
                
                let batch = self.db.batch()
                documents.forEach { batch.deleteDocument($0.reference) }
                
                batch.commit { error in
                    completion(error)
                }
            }
    }
    
    // Method to stop all listeners when user logs out
    func removeAllListeners() {
        // Remove main listener
        mainListener?.remove()
        mainListener = nil
        
        // Remove all chat-specific listeners
        for (_, listener) in chatListeners {
            listener.remove()
        }
        chatListeners.removeAll()
        
        // Clear processed message IDs
        processedMessageIds.removeAll()
    }
}
