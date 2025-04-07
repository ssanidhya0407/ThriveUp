import Foundation
import UIKit
import FirebaseAuth

// MARK: - Extensions for MessageCell to handle GroupMessage type

extension MessageCell {
    // Configure with UserGroup.Message and admins array
    func configure(with message: UserGroup.Message, admins: [String]) {
        // Convert UserGroup.Message to EventGroupMessage
        let eventGroupMessage = EventGroupMessage(
            id: message.id,
            userId: message.userId,
            userName: message.userName,
            text: message.text,
            timestamp: message.timestamp,
            profileImageURL: message.profileImageURL,
            imageURL: message.imageURL
        )
        
        let currentUserId = getCurrentUserId()
        
        // Call the original configure method
        configure(with: eventGroupMessage, currentUserId: currentUserId)
        
        // Additional styling for admin messages if needed
        if admins.contains(message.userId) && message.userId != currentUserId {
            // Apply admin styling
            nameLabel.textColor = .systemIndigo
        }
    }
    
    // Helper to get the current user ID
    private func getCurrentUserId() -> String {
        return FirebaseAuth.Auth.auth().currentUser?.uid ?? ""
    }
}

// MARK: - Extension to locate nameLabel in MessageCell (REMOVED - now nameLabel is exposed directly)
/* REMOVED TO PREVENT DUPLICATE PROPERTY DECLARATION
extension MessageCell {
    // Helper to expose the nameLabel - add this if the nameLabel is private in MessageCell
    var nameLabel: UILabel {
        // Find the nameLabel in the cell's content view
        return self.contentView.subviews.compactMap { view in
            if let label = view as? UILabel, label.font.pointSize == 14 {
                return label
            }
            return nil
        }.first!
    }
}
*/
