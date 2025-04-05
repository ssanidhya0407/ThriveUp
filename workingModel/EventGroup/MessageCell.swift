import UIKit
import Kingfisher
import FirebaseAuth

class MessageCell: UITableViewCell {
    
    // MARK: - UI Elements
    // Changed from private to public to allow access from extensions
    public let userImageView = UIImageView()
    public let nameLabel = UILabel() // Made public to be accessible from extensions
    public let timeLabel = UILabel()
    public let messageLabel = UILabel()
    public let messageImageView = UIImageView()
    public let messageContainer = UIView()
    
    // MARK: - Properties
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        userImageView.kf.cancelDownloadTask()
        messageImageView.kf.cancelDownloadTask()
        messageImageView.image = nil
        messageImageView.isHidden = true
        userImageView.image = UIImage(systemName: "person.circle.fill")
        userImageView.tintColor = .systemGray3
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // Setup user image view
        userImageView.contentMode = .scaleAspectFill
        userImageView.clipsToBounds = true
        userImageView.layer.cornerRadius = 18
        userImageView.backgroundColor = .systemGray6
        userImageView.image = UIImage(systemName: "person.circle.fill")
        userImageView.tintColor = .systemGray3
        userImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(userImageView)
        
        // Setup message container view
        messageContainer.layer.cornerRadius = 18
        messageContainer.backgroundColor = .systemGray6
        messageContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(messageContainer)
        
        // Setup name label
        nameLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        messageContainer.addSubview(nameLabel)
        
        // Setup time label
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textColor = .secondaryLabel
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        messageContainer.addSubview(timeLabel)
        
        // Setup message label
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageContainer.addSubview(messageLabel)
        
        // Setup message image view
        messageImageView.contentMode = .scaleAspectFill
        messageImageView.clipsToBounds = true
        messageImageView.layer.cornerRadius = 12
        messageImageView.translatesAutoresizingMaskIntoConstraints = false
        messageImageView.isUserInteractionEnabled = true
        messageImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imageTapped)))
        messageContainer.addSubview(messageImageView)
        
        // Set constraints
        NSLayoutConstraint.activate([
            // User image view
            userImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            userImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            userImageView.widthAnchor.constraint(equalToConstant: 36),
            userImageView.heightAnchor.constraint(equalToConstant: 36),
            
            // Message container
            messageContainer.leadingAnchor.constraint(equalTo: userImageView.trailingAnchor, constant: 8),
            messageContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            messageContainer.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -60),
            messageContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            // Name label
            nameLabel.leadingAnchor.constraint(equalTo: messageContainer.leadingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: messageContainer.topAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -8),
            
            // Time label
            timeLabel.trailingAnchor.constraint(equalTo: messageContainer.trailingAnchor, constant: -12),
            timeLabel.topAnchor.constraint(equalTo: messageContainer.topAnchor, constant: 8),
            timeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: nameLabel.trailingAnchor, constant: 8),
            
            // Message label
            messageLabel.leadingAnchor.constraint(equalTo: messageContainer.leadingAnchor, constant: 12),
            messageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            messageLabel.trailingAnchor.constraint(equalTo: messageContainer.trailingAnchor, constant: -12),
            
            // Message image view (shown only for image messages)
            messageImageView.leadingAnchor.constraint(equalTo: messageContainer.leadingAnchor, constant: 12),
            messageImageView.trailingAnchor.constraint(equalTo: messageContainer.trailingAnchor, constant: -12),
            messageImageView.bottomAnchor.constraint(equalTo: messageContainer.bottomAnchor, constant: -12),
            messageImageView.heightAnchor.constraint(equalToConstant: 180),
            messageImageView.widthAnchor.constraint(lessThanOrEqualToConstant: 250)
        ])
        
        // Add constraint from message label to bottom (will be active only when no image)
        messageLabel.bottomAnchor.constraint(equalTo: messageContainer.bottomAnchor, constant: -12).isActive = true
    }
    
    // MARK: - Configuration
    func configure(with message: EventGroupMessage, currentUserId: String) {
        nameLabel.text = message.userName
        timeLabel.text = dateFormatter.string(from: message.timestamp)
        
        // Configure text message
        if let text = message.text {
            messageLabel.text = text
            messageLabel.isHidden = false
        } else {
            messageLabel.isHidden = true
        }
        
        // Configure image message
        if let imageURLString = message.imageURL, let url = URL(string: imageURLString) {
            messageImageView.isHidden = false
            messageImageView.kf.setImage(
                with: url,
                options: [
                    .transition(.fade(0.3)),
                    .cacheOriginalImage
                ]
            )
        } else {
            messageImageView.isHidden = true
        }
        
        // Set constraints based on content
        if messageLabel.isHidden {
            messageImageView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8).isActive = true
        }
        
        // Configure user profile image
        if let profileImageURLString = message.profileImageURL, let url = URL(string: profileImageURLString) {
            userImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "person.circle.fill"),
                options: [
                    .transition(.fade(0.2)),
                    .cacheOriginalImage
                ]
            )
        } else {
            userImageView.image = UIImage(systemName: "person.circle.fill")
        }
        
        // Style for current user's messages
        if message.userId == currentUserId {
            messageContainer.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
            nameLabel.textColor = .systemBlue
        } else {
            messageContainer.backgroundColor = UIColor.systemGray6
            nameLabel.textColor = .label
        }
    }
    
    // MARK: - Actions
    @objc private func imageTapped() {
        // This will be handled by the cell delegate in the view controller
        NotificationCenter.default.post(name: NSNotification.Name("EventMessageImageTapped"), object: self)
    }
}
