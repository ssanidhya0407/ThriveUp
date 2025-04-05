import UIKit

class UserMemberCell: UITableViewCell {
    static let identifier = "UserMemberCell"
    
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let roleLabel = UILabel()
    private let chatStatusLabel = UILabel()
    private let containerView = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Add some padding around the cell
        containerView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10))
    }
    
    private func setupUI() {
        selectionStyle = .none
        
        // Add container view for better styling
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 10
        containerView.clipsToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // Configure profile image view
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 22
        profileImageView.clipsToBounds = true
        profileImageView.backgroundColor = .systemGray5
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(profileImageView)
        
        // Configure name label
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(nameLabel)
        
        // Configure role label with badge style
        roleLabel.font = UIFont.systemFont(ofSize: 12)
        roleLabel.textColor = .white
        roleLabel.textAlignment = .center
        roleLabel.layer.cornerRadius = 10
        roleLabel.clipsToBounds = true
        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(roleLabel)
        
        // Configure chat status label
        chatStatusLabel.font = UIFont.systemFont(ofSize: 12)
        chatStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(chatStatusLabel)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            
            // Profile image constraints
            profileImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 44),
            profileImageView.heightAnchor.constraint(equalToConstant: 44),
            
            // Name label constraints
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: roleLabel.leadingAnchor, constant: -8),
            
            // Role label constraints
            roleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            roleLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            roleLabel.heightAnchor.constraint(equalToConstant: 20),
            roleLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            // Chat status constraints
            chatStatusLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            chatStatusLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            chatStatusLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -16),
            chatStatusLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with member: GroupMember) {
        nameLabel.text = member.name
        
        // Set role badge
        if member.role == "admin" {
            roleLabel.text = "Admin"
            roleLabel.backgroundColor = .systemBlue
        } else {
            roleLabel.text = "Member"
            roleLabel.backgroundColor = .systemGray
        }
        
        // Set chat status with icon
        let chatStatusIcon = member.canChat ? "✓" : "✗"
        let chatStatusColor = member.canChat ? UIColor.systemGreen : UIColor.systemRed
        chatStatusLabel.text = "\(chatStatusIcon) \(member.canChat ? "Can chat" : "No chat")"
        chatStatusLabel.textColor = chatStatusColor
        
        // Load profile image if available
        if let profileImageURL = member.profileImageURL, let url = URL(string: profileImageURL) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data = data, let image = UIImage(data: data) else {
                    DispatchQueue.main.async {
                        self?.profileImageView.image = UIImage(systemName: "person.circle.fill")
                        self?.profileImageView.tintColor = .systemGray
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self?.profileImageView.image = image
                }
            }.resume()
        } else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
            profileImageView.tintColor = .systemGray
        }
    }
}
