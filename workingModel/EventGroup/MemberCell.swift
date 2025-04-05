import UIKit
import Kingfisher

class MemberCell: UITableViewCell {
    
    static let identifier = "MemberCell"
    
    private let nameLabel = UILabel()
    private let roleLabel = UILabel()
    private let statusLabel = UILabel()
    public let profileImageView = UIImageView()
    private let separatorLine = UIView()
    
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
        profileImageView.image = UIImage(systemName: "person.fill")
        profileImageView.tintColor = .systemGray2
        statusLabel.isHidden = true
    }
    
    private func setupUI() {
        backgroundColor = .systemBackground
        selectionStyle = .none
        
        // Configure profile image view - elegant circular design
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 22
        profileImageView.clipsToBounds = true
        profileImageView.image = UIImage(systemName: "person.fill")
        profileImageView.tintColor = .systemGray2
        profileImageView.backgroundColor = .systemGray6
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileImageView)
        
        // Configure name label - clean and prominent
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        
        // Configure role label - subtle indication
        roleLabel.font = UIFont.systemFont(ofSize: 14)
        roleLabel.textColor = .secondaryLabel
        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(roleLabel)
        
        // Configure status label - elegant indication of permissions
        statusLabel.font = UIFont.systemFont(ofSize: 12)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statusLabel)
        
        // Separator line - subtle division between cells
        separatorLine.backgroundColor = .systemGray5
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        
        // Remove chevron indicator as we're handling selection differently now
        accessoryType = .none
        
        // Set constraints with clean spacing
        NSLayoutConstraint.activate([
            // Profile image constraints
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 44),
            profileImageView.heightAnchor.constraint(equalToConstant: 44),
            
            // Name label constraints
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            
            // Role label constraints
            roleLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            
            // Status label constraints
            statusLabel.centerYAnchor.constraint(equalTo: roleLabel.centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: roleLabel.trailingAnchor, constant: 12),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            
            // Separator
            separatorLine.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }
    
    func configure(with member: EventGroupMember, viewedByOrganizer: Bool = false) {
        nameLabel.text = member.name
        
        // Configure role text with color indication
        if member.role == "organizer" {
            roleLabel.text = "Organizer"
            roleLabel.textColor = .systemBlue
        } else {
            roleLabel.text = "Member"
            roleLabel.textColor = .secondaryLabel
        }
        
        // Show chat status only if viewed by an organizer
        if viewedByOrganizer {
            statusLabel.isHidden = false
            if member.canChat {
                statusLabel.text = "Can message"
                statusLabel.textColor = .systemGreen
            } else {
                statusLabel.text = "No messaging"
                statusLabel.textColor = .systemRed
            }
        } else {
            statusLabel.isHidden = true
        }
        
        // Load profile image using Kingfisher
        if let profileImageURL = member.profileImageURL, let url = URL(string: profileImageURL) {
            profileImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "person.fill"),
                options: [
                    .transition(.fade(0.2)),
                    .scaleFactor(UIScreen.main.scale),
                    .cacheOriginalImage
                ]
            )
        } else {
            profileImageView.image = UIImage(systemName: "person.fill")
            profileImageView.tintColor = .systemGray2
        }
    }
}
