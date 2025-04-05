import UIKit

class UserMemberCell: UITableViewCell {
    static let identifier = "UserMemberCell"
    
    // UI Elements
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let roleLabel = UILabel()
    private let statusLabel = UILabel()
    private let separatorLine = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .systemBackground
        selectionStyle = .none
        
        // Avatar image - simple circular design
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 22
        avatarImageView.backgroundColor = .systemGray6
        avatarImageView.image = UIImage(systemName: "person.fill")
        avatarImageView.tintColor = .systemGray2
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(avatarImageView)
        
        // Name label - clean and prominent
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        
        // Role label - subtle indication
        roleLabel.font = UIFont.systemFont(ofSize: 14)
        roleLabel.textColor = .secondaryLabel
        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(roleLabel)
        
        // Status label - elegant indication of permissions
        statusLabel.font = UIFont.systemFont(ofSize: 12)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statusLabel)
        
        // Separator line - subtle division between cells
        separatorLine.backgroundColor = .systemGray5
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        
        // Constraints - clean spacing
        NSLayoutConstraint.activate([
            // Avatar
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 44),
            avatarImageView.heightAnchor.constraint(equalToConstant: 44),
            
            // Name label
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            
            // Role label
            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            roleLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            
            // Status label - aligned with role label
            statusLabel.centerYAnchor.constraint(equalTo: roleLabel.centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: roleLabel.trailingAnchor, constant: 12),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            
            // Separator
            separatorLine.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }
    
    func configure(with member: GroupMember) {
        nameLabel.text = member.name
        
        // Configure role text
        if member.role == "admin" {
            roleLabel.text = "Admin"
            roleLabel.textColor = .systemBlue
        } else {
            roleLabel.text = "Member"
            roleLabel.textColor = .secondaryLabel
        }
        
        // Configure chat permission status
        if member.canChat {
            statusLabel.text = "Can message"
            statusLabel.textColor = .systemGreen
        } else {
            statusLabel.text = "No messaging"
            statusLabel.textColor = .systemRed
        }
        
        // Load profile image if available
        if let profileURL = member.profileImageURL, let url = URL(string: profileURL) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
                guard let data = data, let image = UIImage(data: data) else { return }
                
                DispatchQueue.main.async {
                    self?.avatarImageView.image = image
                }
            }.resume()
        } else {
            avatarImageView.image = UIImage(systemName: "person.fill")
            avatarImageView.tintColor = .systemGray2
        }
    }
}
