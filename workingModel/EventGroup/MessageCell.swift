import UIKit

class MessageCell: UITableViewCell {
    static let identifier = "MessageCell"
    
    private let userNameLabel = UILabel()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()
    private let profileImageView = UIImageView()
    private let messageImageView = UIImageView()
    
    private let organizerBadge: UIView = {
        let badge = UIView()
        badge.backgroundColor = UIColor.systemOrange
        badge.layer.cornerRadius = 8
        badge.isHidden = true
        return badge
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Configure profile image view
        profileImageView.contentMode = .scaleAspectFill
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
        
        // Configure message image view
        messageImageView.contentMode = .scaleAspectFit
        messageImageView.clipsToBounds = true
        messageImageView.layer.cornerRadius = 8
        messageImageView.isHidden = true
        messageImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(messageImageView)
        
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
            
            // Message image view constraints
            messageImageView.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            messageImageView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 8),
            messageImageView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.7),
            messageImageView.heightAnchor.constraint(lessThanOrEqualToConstant: 200),
            
            // Time label constraints
            timeLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            timeLabel.topAnchor.constraint(equalTo: messageImageView.bottomAnchor, constant: 8),
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with message: EventGroupMessage, organizers: [String] = []) {
        userNameLabel.text = message.userName
        messageLabel.text = message.text
        
        // Format time
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        timeLabel.text = formatter.string(from: message.timestamp)
        
        // Check if the message sender is an organizer
        let isOrganizer = organizers.contains(message.userId)
        
        // Show the badge if the sender is an organizer
        organizerBadge.isHidden = !isOrganizer
        
        // Change bubble color for organizer messages
        if isOrganizer {
            userNameLabel.textColor = UIColor.systemOrange
        } else {
            userNameLabel.textColor = .darkGray
        }
        
        // Load profile image if available
        if let profileImageURL = message.profileImageURL, let url = URL(string: profileImageURL) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data = data, let image = UIImage(data: data) else { return }
                
                DispatchQueue.main.async {
                    self?.profileImageView.image = image
                }
            }.resume()
        } else {
            // Set default image
            profileImageView.image = UIImage(systemName: "person.circle.fill")
        }
        
        // Ensure the badge is added to the view and positioned properly
        if isOrganizer {
            contentView.addSubview(organizerBadge)
            organizerBadge.isHidden = false
            
            NSLayoutConstraint.activate([
                organizerBadge.leadingAnchor.constraint(equalTo: userNameLabel.leadingAnchor, constant: 4),
                organizerBadge.centerYAnchor.constraint(equalTo: userNameLabel.centerYAnchor),
                organizerBadge.widthAnchor.constraint(equalToConstant: 8),
                organizerBadge.heightAnchor.constraint(equalToConstant: 8)
            ])
        } else {
            organizerBadge.isHidden = true
        }
    }

}

