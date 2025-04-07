import UIKit
import FirebaseAuth

// This adapter provides a direct bridge for MessageCell to work with UserGroup.Message
class MessageCellAdapter {
    // Static method to configure a MessageCell with UserGroup.Message
    static func configure(cell: MessageCell, message: UserGroup.Message, admins: [String]) {
        // Create an EventGroupMessage directly instead of trying to convert EventGroup.Message
        let eventMessage = EventGroupMessage(
            id: message.id,
            userId: message.userId,
            userName: message.userName,
            text: message.text,
            timestamp: message.timestamp,
            profileImageURL: message.profileImageURL,
            imageURL: message.imageURL
        )
        
        let currentUserId = Auth.auth().currentUser?.uid ?? ""
        
        // Configure the cell using its original method
        cell.configure(with: eventMessage, currentUserId: currentUserId)
        
        // Additional styling for admin messages
        if admins.contains(message.userId) && message.userId != currentUserId {
            // We need to access the nameLabel - this may need adjustment
            if let nameLabel = findNameLabel(in: cell) {
                nameLabel.textColor = .systemIndigo
            }
        }
    }
    
    // Static method to configure a MessageCell with EventGroup.Message
    static func configureForEvent(cell: MessageCell, message: EventGroup.Message, organizers: [String]) {
        // Create an EventGroupMessage from EventGroup.Message
        let eventMessage = EventGroupMessage(
            id: message.id,
            userId: message.userId,
            userName: message.userName,
            text: message.text,
            timestamp: message.timestamp,
            profileImageURL: message.profileImageURL,
            imageURL: message.imageURL
        )
        
        let currentUserId = Auth.auth().currentUser?.uid ?? ""
        
        // Use the cell's original configure method
        cell.configure(with: eventMessage, currentUserId: currentUserId)
        
        // Additional styling for organizer messages
        if organizers.contains(message.userId) && message.userId != currentUserId {
            if let nameLabel = findNameLabel(in: cell) {
                nameLabel.textColor = .systemIndigo
            }
        }
    }
    
    // Helper method to find the nameLabel in the cell
    private static func findNameLabel(in cell: MessageCell) -> UILabel? {
        return cell.contentView.subviews.compactMap { view in
            if let label = view as? UILabel, label.font.pointSize == 14 {
                return label
            }
            return nil
        }.first
    }
}
