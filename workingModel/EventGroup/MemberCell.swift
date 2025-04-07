import UIKit
import Kingfisher

class MemberCell: UITableViewCell {
    
    static let identifier = "MemberCell"
    
    // MARK: - Properties
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let roleLabel = UILabel()
    private let joinedDateLabel = UILabel()
    private let chatStatusLabel = UILabel()
    private let chatStatusIndicator = UIView()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        selectionStyle = .default
        
        // Profile image setup
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 25
        profileImageView.backgroundColor = .systemGray6
        profileImageView.tintColor = .systemGray3
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileImageView)
        
        // Name label setup
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        
        // Role label setup
        roleLabel.font = UIFont.systemFont(ofSize: 14)
        roleLabel.textColor = .secondaryLabel
        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(roleLabel)
        
        // Joined date label
        joinedDateLabel.font = UIFont.systemFont(ofSize: 12)
        joinedDateLabel.textColor = .tertiaryLabel
        joinedDateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(joinedDateLabel)
        
        // Chat status indicator
        chatStatusIndicator.layer.cornerRadius = 4
        chatStatusIndicator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(chatStatusIndicator)
        
        // Chat status label
        chatStatusLabel.font = UIFont.systemFont(ofSize: 12)
        chatStatusLabel.textColor = .secondaryLabel
        chatStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(chatStatusLabel)
        
        // Add constraints
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 50),
            profileImageView.heightAnchor.constraint(equalToConstant: 50),
            
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -80),
            
            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            roleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            roleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            
            joinedDateLabel.topAnchor.constraint(equalTo: roleLabel.bottomAnchor, constant: 2),
            joinedDateLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            joinedDateLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8),
            
            chatStatusIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chatStatusIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chatStatusIndicator.widthAnchor.constraint(equalToConstant: 8),
            chatStatusIndicator.heightAnchor.constraint(equalToConstant: 8),
            
            chatStatusLabel.trailingAnchor.constraint(equalTo: chatStatusIndicator.leadingAnchor, constant: -4),
            chatStatusLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }
    
    // MARK: - Configuration
    func configure(with member: EventGroup.Member, viewedByOrganizer: Bool) {
        nameLabel.text = member.name
        
        // Set role text and styling
        if member.role == "organizer" {
            roleLabel.text = "Organizer"
            roleLabel.textColor = .systemOrange
            roleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        } else {
            roleLabel.text = "Participant"
            roleLabel.textColor = .secondaryLabel
            roleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        }
        
        // Set joined date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        joinedDateLabel.text = "Joined: \(dateFormatter.string(from: member.joinedAt))"
        
        // Set chat status
        if member.canChat {
            chatStatusLabel.text = "Can chat"
            chatStatusIndicator.backgroundColor = .systemGreen
        } else {
            chatStatusLabel.text = "Can't chat"
            chatStatusIndicator.backgroundColor = .systemRed
        }
        
        // Only show chat status for organizers
        chatStatusLabel.isHidden = !viewedByOrganizer
        chatStatusIndicator.isHidden = !viewedByOrganizer
        
        // Load profile image if available
        if let imageURL = member.profileImageURL, let url = URL(string: imageURL) {
            profileImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "person.circle.fill"),
                options: [.transition(.fade(0.3))]
            )
        } else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        nameLabel.text = nil
        roleLabel.text = nil
        joinedDateLabel.text = nil
        chatStatusLabel.text = nil
    }
}
