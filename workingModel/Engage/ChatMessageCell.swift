//
//  ChatMessageCell.swift
//  ThriveUp
//
//  Created by palak seth on 15/11/24.
//

 
import UIKit
import SDWebImage

class ChatMessageCell: UITableViewCell {
    
    private let bubbleBackgroundView = UIView()
    private let messageLabel = UILabel()
    private let messageImageView = UIImageView()
    
    var isIncoming: Bool = true {
        didSet {
            updateBubbleUI()
        }
    }
    
    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clear
        selectionStyle = .none
        
        // Bubble Background
        bubbleBackgroundView.layer.cornerRadius = 15
        bubbleBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubbleBackgroundView)
        
        // Message Label
        messageLabel.numberOfLines = 0
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleBackgroundView.addSubview(messageLabel)
        
        // Image Message View
        messageImageView.contentMode = .scaleAspectFill
        messageImageView.layer.cornerRadius = 12
        messageImageView.clipsToBounds = true
        messageImageView.translatesAutoresizingMaskIntoConstraints = false
        bubbleBackgroundView.addSubview(messageImageView)
        messageImageView.isHidden = true
        
        // Constraints
        leadingConstraint = bubbleBackgroundView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        trailingConstraint = bubbleBackgroundView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        
        NSLayoutConstraint.activate([
            bubbleBackgroundView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            bubbleBackgroundView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            
            messageLabel.topAnchor.constraint(equalTo: bubbleBackgroundView.topAnchor, constant: 10),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleBackgroundView.bottomAnchor, constant: -10),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleBackgroundView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleBackgroundView.trailingAnchor, constant: -12),
            
            messageImageView.topAnchor.constraint(equalTo: bubbleBackgroundView.topAnchor),
            messageImageView.bottomAnchor.constraint(equalTo: bubbleBackgroundView.bottomAnchor),
            messageImageView.leadingAnchor.constraint(equalTo: bubbleBackgroundView.leadingAnchor),
            messageImageView.trailingAnchor.constraint(equalTo: bubbleBackgroundView.trailingAnchor),
            messageImageView.widthAnchor.constraint(lessThanOrEqualToConstant: 250),
            messageImageView.heightAnchor.constraint(lessThanOrEqualToConstant: 250)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Dynamic Bubble UI for text & images
    private func updateBubbleUI() {
        bubbleBackgroundView.backgroundColor = isIncoming ? UIColor(white: 0.9, alpha: 1) : UIColor.systemOrange
        messageLabel.textColor = isIncoming ? .black : .white
        leadingConstraint.isActive = isIncoming
        trailingConstraint.isActive = !isIncoming
    }
    
    // Update Cell Content Based on Message Type
    func configure(with message: ChatMessage) {
        if let mediaURL = message.mediaURL, !mediaURL.isEmpty {
            messageImageView.isHidden = false
            messageLabel.isHidden = true
            messageImageView.sd_setImage(with: URL(string: mediaURL), placeholderImage: UIImage(systemName: "photo"))
            bubbleBackgroundView.layer.cornerRadius = 12 // More rounded corners for images
        } else {
            messageImageView.isHidden = true
            messageLabel.isHidden = false
            messageLabel.text = message.messageContent
            bubbleBackgroundView.layer.cornerRadius = 15
        }
        isIncoming = !message.isSender
    }
}




