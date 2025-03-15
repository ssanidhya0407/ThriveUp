//
//  MessageCell.swift
//  ThriveUp
//
//  Created by Sanidhya's MacBook Pro on 16/03/25.
//


import UIKit

class MessageCell: UITableViewCell {
    
    private let userNameLabel = UILabel()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()
    private let profileImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Configure profile image view
        profileImageView.contentMode = .scaleAspectFit
        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileImageView)
        
        // Configure user name label
        userNameLabel.font = UIFont.boldSystemFont(ofSize: 14)
        userNameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(userNameLabel)
        
        // Configure message label
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(messageLabel)
        
        // Configure time label
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textColor = .gray
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(timeLabel)
        
        NSLayoutConstraint.activate([
            // Profile image constraints
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            profileImageView.widthAnchor.constraint(equalToConstant: 40),
            profileImageView.heightAnchor.constraint(equalToConstant: 40),
            
            // User name constraints
            userNameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            userNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            userNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Message label constraints
            messageLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            messageLabel.topAnchor.constraint(equalTo: userNameLabel.bottomAnchor, constant: 4),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Time label constraints
            timeLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            timeLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 4),
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with message: EventGroupMessage) {
        userNameLabel.text = message.userName
        messageLabel.text = message.text
        
        // Format the timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        timeLabel.text = dateFormatter.string(from: message.timestamp)
        
        // Load profile image if available
        if let profileImageURL = message.profileImageURL, let url = URL(string: profileImageURL) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.profileImageView.image = image
                    }
                }
            }.resume()
        } else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
        }
    }
}
