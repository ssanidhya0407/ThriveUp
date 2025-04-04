import UIKit
import Kingfisher

class MemberCell: UITableViewCell {
    
    private let nameLabel = UILabel()
    private let roleLabel = UILabel()
    private let statusLabel = UILabel()
    public let profileImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Cancel any ongoing image download
        profileImageView.kf.cancelDownloadTask()
        // Reset to default image
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .systemGray
        statusLabel.isHidden = true
    }
    
    private func setupUI() {
        // Configure profile image view
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .systemGray
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileImageView)
        
        // Configure name label
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        
        // Configure role label
        roleLabel.font = UIFont.systemFont(ofSize: 14)
        roleLabel.textColor = .gray
        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(roleLabel)
        
        // Configure status label
        statusLabel.font = UIFont.systemFont(ofSize: 12)
        statusLabel.isHidden = true
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statusLabel)
        
        // Add chevron indicator for organizer view
        accessoryType = .disclosureIndicator
        
        NSLayoutConstraint.activate([
            // Profile image constraints
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 40),
            profileImageView.heightAnchor.constraint(equalToConstant: 40),
            
            // Name label constraints
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Role label constraints
            roleLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            roleLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusLabel.leadingAnchor, constant: -8),
            
            // Status label constraints
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            statusLabel.centerYAnchor.constraint(equalTo: roleLabel.centerYAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with member: EventGroupMember, viewedByOrganizer: Bool = false) {
        nameLabel.text = member.name
        roleLabel.text = member.role.capitalized
        
        // Show chat status only if viewed by an organizer
        if viewedByOrganizer {
            statusLabel.isHidden = false
            if member.canChat {
                statusLabel.text = "Can chat"
                statusLabel.textColor = .systemGreen
            } else {
                statusLabel.text = "Chat disabled"
                statusLabel.textColor = .systemRed
            }
        } else {
            statusLabel.isHidden = true
        }
        
        // Load profile image using Kingfisher
        if let profileImageURL = member.profileImageURL, let url = URL(string: profileImageURL) {
            profileImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "person.circle.fill"),
                options: [
                    .transition(.fade(0.2)),
                    .scaleFactor(UIScreen.main.scale),
                    .cacheOriginalImage
                ]
            )
        } else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
        }
    }
}
