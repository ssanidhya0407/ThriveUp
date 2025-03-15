//
//  MemberCell.swift
//  ThriveUp
//
//  Created by Sanidhya's MacBook Pro on 16/03/25.
//


import UIKit

class MemberCell: UITableViewCell {
    
    private let nameLabel = UILabel()
    private let roleLabel = UILabel()
    private let statusLabel = UILabel()
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
            
            // Status label constraints
            statusLabel.leadingAnchor.constraint(equalTo: roleLabel.trailingAnchor, constant: 8),
            statusLabel.centerYAnchor.constraint(equalTo: roleLabel.centerYAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with member: EventGroupMember) {
        nameLabel.text = member.name
        roleLabel.text = member.role.capitalized
        
        // Show chat status
        if member.canChat {
            statusLabel.text = "Can chat"
            statusLabel.textColor = .systemGreen
        } else {
            statusLabel.text = "Chat disabled"
            statusLabel.textColor = .systemRed
        }
        
        // Load profile image if available
        if let profileImageURL = member.profileImageURL, let url = URL(string: profileImageURL) {
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