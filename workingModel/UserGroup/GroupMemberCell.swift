import UIKit
import Kingfisher

class GroupMemberCell: UITableViewCell {
    
    // MARK: - UI Elements
    private let userImageView = UIImageView()
    private let nameLabel = UILabel()
    private let roleLabel = UILabel()
    private let statusIndicator = UIView()
    
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
        // Setup user image view
        userImageView.contentMode = .scaleAspectFill
        userImageView.clipsToBounds = true
        userImageView.layer.cornerRadius = 25
        userImageView.backgroundColor = .systemGray6
        userImageView.image = UIImage(systemName: "person.circle.fill")
        userImageView.tintColor = .systemGray3
        userImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(userImageView)
        
        // Setup name label
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        
        // Setup role label
        roleLabel.font = UIFont.systemFont(ofSize: 14)
        roleLabel.textColor = .secondaryLabel
        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(roleLabel)
        
        // Setup status indicator
        statusIndicator.layer.cornerRadius = 5
        statusIndicator.backgroundColor = .systemGreen
        statusIndicator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statusIndicator)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // User image
            userImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            userImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            userImageView.widthAnchor.constraint(equalToConstant: 50),
            userImageView.heightAnchor.constraint(equalToConstant: 50),
            
            // Name label
            nameLabel.leadingAnchor.constraint(equalTo: userImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            
            // Role label
            roleLabel.leadingAnchor.constraint(equalTo: userImageView.trailingAnchor, constant: 12),
            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            roleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            
            // Status indicator
            statusIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            statusIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusIndicator.widthAnchor.constraint(equalToConstant: 10),
            statusIndicator.heightAnchor.constraint(equalToConstant: 10)
        ])
        
        // Add selection style
        selectionStyle = .default
        accessoryType = .disclosureIndicator
    }
    
    // MARK: - Configuration
    func configure(with member: UserGroup.Member, viewedByOrganizer: Bool) {
        nameLabel.text = member.name
        
        // Configure role text with appropriate style
        if member.role == "admin" {
            roleLabel.text = "Admin"
            roleLabel.textColor = .systemBlue
        } else {
            roleLabel.text = "Member"
            roleLabel.textColor = .secondaryLabel
        }
        
        // Show status indicator if member can chat
        statusIndicator.isHidden = !member.canChat
        
        // Load profile image if available
        if let profileImageURL = member.profileImageURL, let url = URL(string: profileImageURL) {
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
        
        // Change background color if viewed by organizer (for highlighting UI)
        if viewedByOrganizer && member.role == "member" {
            contentView.alpha = 1.0
        } else if viewedByOrganizer && member.role == "admin" {
            contentView.alpha = 1.0
        } else {
            contentView.alpha = 0.8
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        userImageView.kf.cancelDownloadTask()
        userImageView.image = UIImage(systemName: "person.circle.fill")
        nameLabel.text = nil
        roleLabel.text = nil
        statusIndicator.isHidden = true
        contentView.alpha = 1.0
        contentView.backgroundColor = .systemBackground
    }
}
