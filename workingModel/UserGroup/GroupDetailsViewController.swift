import UIKit
import FirebaseFirestore
import FirebaseAuth
import Kingfisher

class GroupDetailsViewController: UIViewController {
    
    // MARK: - Properties
    private let groupId: String
    private let groupName: String
    private var groupImageURL: String?
    private var members: [UserGroup.Member] = []
    private let db = Firestore.firestore()
    private let userGroupManager = UserGroupManager()
    private let currentUserID = Auth.auth().currentUser?.uid ?? ""
    private var isCurrentUserAdmin = false
    
    // UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let groupImageView = UIImageView()
    private let groupNameLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let membersHeaderLabel = UILabel()
    private let membersStackView = UIStackView()
    private let settingsHeaderLabel = UILabel()
    
    // MARK: - Initialization
    init(groupId: String, groupName: String, imageURL: String? = nil) {
        self.groupId = groupId
        self.groupName = groupName
        self.groupImageURL = imageURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadGroupDetails()
        loadMembers()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Group Details"
        
        // Add Edit button if user is admin (to be implemented later)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .edit,
            target: self,
            action: #selector(editGroupTapped)
        )
        
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ])
        
        setupGroupHeader()
        setupMembersSection()
        setupSettingsSection()
    }
    
    private func setupGroupHeader() {
        // Group image
        groupImageView.contentMode = .scaleAspectFill
        groupImageView.clipsToBounds = true
        groupImageView.layer.cornerRadius = 50
        groupImageView.backgroundColor = .systemGray6
        groupImageView.image = UIImage(systemName: "person.3")
        groupImageView.tintColor = .systemGray3
        groupImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(groupImageView)
        
        // Group name label
        groupNameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        groupNameLabel.text = groupName
        groupNameLabel.textAlignment = .center
        groupNameLabel.numberOfLines = 0
        groupNameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(groupNameLabel)
        
        // Description label
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.text = "Group description will appear here"
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(descriptionLabel)
        
        // Separator line
        let separatorLine = UIView()
        separatorLine.backgroundColor = .systemGray5
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        
        NSLayoutConstraint.activate([
            groupImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            groupImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            groupImageView.widthAnchor.constraint(equalToConstant: 100),
            groupImageView.heightAnchor.constraint(equalToConstant: 100),
            
            groupNameLabel.topAnchor.constraint(equalTo: groupImageView.bottomAnchor, constant: 16),
            groupNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            groupNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            descriptionLabel.topAnchor.constraint(equalTo: groupNameLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            separatorLine.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    private func setupMembersSection() {
        // Members header
        membersHeaderLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        membersHeaderLabel.text = "Members"
        membersHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(membersHeaderLabel)
        
        // Add button
        let addButton = UIButton(type: .system)
        addButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(addMemberTapped), for: .touchUpInside)
        contentView.addSubview(addButton)
        
        // Members stack view - will add member views here dynamically
        membersStackView.axis = .vertical
        membersStackView.spacing = 8
        membersStackView.distribution = .fillProportionally
        membersStackView.alignment = .fill
        membersStackView.translatesAutoresizingMaskIntoConstraints = false
        membersStackView.backgroundColor = .clear
        contentView.addSubview(membersStackView)
        
        // Separator line
        let separatorLine = UIView()
        separatorLine.backgroundColor = .systemGray5
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        
        NSLayoutConstraint.activate([
            membersHeaderLabel.topAnchor.constraint(equalTo: contentView.subviews.first { $0.backgroundColor == .systemGray5 }!.bottomAnchor, constant: 20),
            membersHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            addButton.centerYAnchor.constraint(equalTo: membersHeaderLabel.centerYAnchor),
            addButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            membersStackView.topAnchor.constraint(equalTo: membersHeaderLabel.bottomAnchor, constant: 12),
            membersStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            membersStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            separatorLine.topAnchor.constraint(equalTo: membersStackView.bottomAnchor, constant: 20),
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    private func setupSettingsSection() {
        // Settings header
        settingsHeaderLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        settingsHeaderLabel.text = "Settings"
        settingsHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(settingsHeaderLabel)
        
        // For now, just show a leave group button
        let leaveGroupButton = UIButton(type: .system)
        leaveGroupButton.setTitle("Leave Group", for: .normal)
        leaveGroupButton.setTitleColor(.systemRed, for: .normal)
        leaveGroupButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        leaveGroupButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        leaveGroupButton.layer.cornerRadius = 8
        leaveGroupButton.addTarget(self, action: #selector(leaveGroupTapped), for: .touchUpInside)
        leaveGroupButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(leaveGroupButton)
        
        NSLayoutConstraint.activate([
            settingsHeaderLabel.topAnchor.constraint(equalTo: contentView.subviews.last { $0.backgroundColor == .systemGray5 }!.bottomAnchor, constant: 20),
            settingsHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            leaveGroupButton.topAnchor.constraint(equalTo: settingsHeaderLabel.bottomAnchor, constant: 16),
            leaveGroupButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            leaveGroupButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            leaveGroupButton.heightAnchor.constraint(equalToConstant: 50),
            leaveGroupButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    private func createMemberView(for member: UserGroup.Member) -> UIView {
        // Creating a custom view for each member
        let memberView = UIView()
        memberView.translatesAutoresizingMaskIntoConstraints = false
        memberView.heightAnchor.constraint(equalToConstant: 70).isActive = true
        memberView.backgroundColor = .systemBackground
        memberView.layer.cornerRadius = 8
        
        // Add subtle border
        memberView.layer.borderWidth = 0.5
        memberView.layer.borderColor = UIColor.systemGray4.cgColor
        
        // Profile image
        let profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 20
        profileImageView.backgroundColor = .systemGray5
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .systemGray3
        memberView.addSubview(profileImageView)
        
        // Load profile image if available
        if let imageURL = member.profileImageURL, let url = URL(string: imageURL) {
            profileImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "person.circle.fill"),
                options: [.transition(.fade(0.3))]
            )
        }
        
        // Name label
        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        nameLabel.text = member.name
        memberView.addSubview(nameLabel)
        
        // Role label
        let roleLabel = UILabel()
        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        roleLabel.font = UIFont.systemFont(ofSize: 12)
        roleLabel.text = member.role.capitalized
        roleLabel.textColor = member.role == "admin" ? .systemOrange : .secondaryLabel
        memberView.addSubview(roleLabel)
        
        // Chat permission indicator
        let chatIndicator = UIView()
        chatIndicator.translatesAutoresizingMaskIntoConstraints = false
        chatIndicator.layer.cornerRadius = 6
        chatIndicator.backgroundColor = member.canChat ? .systemGreen : .systemRed
        memberView.addSubview(chatIndicator)
        
        // Chat status label
        let chatLabel = UILabel()
        chatLabel.translatesAutoresizingMaskIntoConstraints = false
        chatLabel.font = UIFont.systemFont(ofSize: 12)
        chatLabel.text = member.canChat ? "Can chat" : "Cannot chat"
        chatLabel.textColor = .secondaryLabel
        memberView.addSubview(chatLabel)
        
        // If this is current user, add indication
        if member.userId == currentUserID {
            memberView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.1)
            let youLabel = UILabel()
            youLabel.translatesAutoresizingMaskIntoConstraints = false
            youLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
            youLabel.text = "YOU"
            youLabel.textColor = .systemBlue
            memberView.addSubview(youLabel)
            
            NSLayoutConstraint.activate([
                youLabel.topAnchor.constraint(equalTo: memberView.topAnchor, constant: 8),
                youLabel.trailingAnchor.constraint(equalTo: memberView.trailingAnchor, constant: -12),
            ])
        }
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(memberTapped(_:)))
        memberView.addGestureRecognizer(tapGesture)
        memberView.isUserInteractionEnabled = true
        memberView.tag = members.firstIndex(where: { $0.userId == member.userId }) ?? -1
        
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: memberView.leadingAnchor, constant: 12),
            profileImageView.centerYAnchor.constraint(equalTo: memberView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 40),
            profileImageView.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: memberView.topAnchor, constant: 14),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: memberView.trailingAnchor, constant: -70),
            
            roleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            
            chatIndicator.trailingAnchor.constraint(equalTo: memberView.trailingAnchor, constant: -12),
            chatIndicator.centerYAnchor.constraint(equalTo: memberView.centerYAnchor),
            chatIndicator.widthAnchor.constraint(equalToConstant: 12),
            chatIndicator.heightAnchor.constraint(equalToConstant: 12),
            
            chatLabel.trailingAnchor.constraint(equalTo: chatIndicator.leadingAnchor, constant: -4),
            chatLabel.centerYAnchor.constraint(equalTo: memberView.centerYAnchor),
        ])
        
        return memberView
    }
    
    private func updateMembersStackView() {
        // Clear the stack view
        for subview in membersStackView.arrangedSubviews {
            membersStackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        
        // Add member views to stack view
        for member in members {
            let memberView = createMemberView(for: member)
            membersStackView.addArrangedSubview(memberView)
        }
    }
    
    // MARK: - Data Loading
    private func loadGroupDetails() {
        db.collection("groups").document(groupId).getDocument { [weak self] snapshot, error in
            guard let self = self, let data = snapshot?.data() else {
                print("Error fetching group details: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                // Update group name
                if let name = data["name"] as? String {
                    self.groupNameLabel.text = name
                }
                
                // Update group description if available
                if let description = data["description"] as? String {
                    self.descriptionLabel.text = description
                } else {
                    self.descriptionLabel.text = "No description available"
                }
                
                // Load group image
                if let imageURL = data["imageURL"] as? String, let url = URL(string: imageURL) {
                    self.groupImageView.kf.setImage(
                        with: url,
                        placeholder: UIImage(systemName: "person.3"),
                        options: [.transition(.fade(0.3))]
                    )
                    self.groupImageURL = imageURL
                } else if let imageURL = self.groupImageURL, let url = URL(string: imageURL) {
                    self.groupImageView.kf.setImage(
                        with: url,
                        placeholder: UIImage(systemName: "person.3"),
                        options: [.transition(.fade(0.3))]
                    )
                }
            }
        }
    }
    
    private func loadMembers() {
        userGroupManager.getGroupMembers(groupId: groupId) { [weak self] members in
            guard let self = self else { return }
            
            // Check if current user is admin
            if let currentMember = members.first(where: { $0.userId == self.currentUserID }),
               currentMember.role == "admin" {
                self.isCurrentUserAdmin = true
                DispatchQueue.main.async {
                    // Enable add button for admin
                    let addButton = self.contentView.subviews.first { $0 is UIButton && ($0 as! UIButton).currentImage?.accessibilityIdentifier == "plus.circle.fill" }
                    addButton?.isHidden = false
                }
            } else {
                DispatchQueue.main.async {
                    // Hide add button for non-admin
                    let addButton = self.contentView.subviews.first { $0 is UIButton && ($0 as! UIButton).currentImage?.accessibilityIdentifier == "plus.circle.fill" }
                    addButton?.isHidden = true
                }
            }
            
            // Sort members: admins first, then alphabetically by name
            self.members = members.sorted { (member1, member2) in
                if member1.role == "admin" && member2.role != "admin" {
                    return true
                } else if member1.role != "admin" && member2.role == "admin" {
                    return false
                } else {
                    return member1.name < member2.name
                }
            }
            
            DispatchQueue.main.async {
                self.updateMembersStackView()
                self.view.layoutIfNeeded()
            }
        }
    }
    
    // MARK: - Actions
    @objc private func memberTapped(_ sender: UITapGestureRecognizer) {
        guard let tappedView = sender.view, tappedView.tag >= 0, tappedView.tag < members.count else { return }
        
        let member = members[tappedView.tag]
        showMemberOptions(for: member)
    }
    
    @objc private func editGroupTapped() {
        // To be implemented: Edit group details
        let alert = UIAlertController(title: "Edit Group", message: "Group editing functionality will be available in a future update.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func addMemberTapped() {
        // Only admins can add members
        guard isCurrentUserAdmin else { return }
        
        // Show add member dialog or go to friend selection screen
        let alert = UIAlertController(title: "Add Member", message: "Invite a friend to this group", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Select from Friends", style: .default) { [weak self] _ in
            self?.showFriendSelection()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showFriendSelection() {
        // This would navigate to a friend selection screen
        showAlert(title: "Feature Coming Soon", message: "Friend selection will be implemented in a future update.")
    }
    
    @objc private func leaveGroupTapped() {
        let alert = UIAlertController(title: "Leave Group", message: "Are you sure you want to leave this group?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Leave", style: .destructive) { [weak self] _ in
            guard let self = self, let userId = Auth.auth().currentUser?.uid else { return }
            
            self.userGroupManager.removeUserFromGroup(groupId: self.groupId, userId: userId) { success in
                DispatchQueue.main.async {
                    if success {
                        // Pop back to chat list
                        self.navigationController?.popToRootViewController(animated: true)
                    } else {
                        self.showErrorAlert(message: "Failed to leave the group. Please try again.")
                    }
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    private func showMemberOptions(for member: UserGroup.Member) {
        // Non-admins can only view profiles
        if !isCurrentUserAdmin || member.userId == currentUserID {
            showProfileForMember(member)
            return
        }
        
        let alert = UIAlertController(title: member.name, message: nil, preferredStyle: .actionSheet)
        
        // Toggle chat permission
        let chatActionTitle = member.canChat ? "Disable Chat" : "Enable Chat"
        alert.addAction(UIAlertAction(title: chatActionTitle, style: .default) { [weak self] _ in
            self?.toggleMemberChatPermission(for: member)
        })
        
        // Remove member
        alert.addAction(UIAlertAction(title: "Remove from Group", style: .destructive) { [weak self] _ in
            self?.removeMember(member)
        })
        
        // Make admin (if member is not already an admin)
        if member.role != "admin" {
            alert.addAction(UIAlertAction(title: "Make Admin", style: .default) { [weak self] _ in
                self?.makeAdmin(member)
            })
        }
        
        // View profile
        alert.addAction(UIAlertAction(title: "View Profile", style: .default) { [weak self] _ in
            self?.showProfileForMember(member)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func toggleMemberChatPermission(for member: UserGroup.Member) {
        let newChatStatus = !member.canChat
        
        userGroupManager.updateMemberChatPermission(groupId: groupId, userId: member.userId, canChat: newChatStatus) { [weak self] success in
            guard let self = self else { return }
            
            if !success {
                self.showErrorAlert(message: "Failed to update chat permission. Please try again.")
                return
            }
            
            self.showAlert(
                title: "Permission Updated",
                message: "\(member.name) can \(newChatStatus ? "now" : "no longer") send messages"
            )
            self.loadMembers() // Refresh the list
        }
    }
    
    private func removeMember(_ member: UserGroup.Member) {
        let confirmAlert = UIAlertController(
            title: "Remove Member",
            message: "Are you sure you want to remove \(member.name) from this group?",
            preferredStyle: .alert
        )
        
        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        confirmAlert.addAction(UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            self.userGroupManager.removeUserFromGroup(groupId: self.groupId, userId: member.userId) { success in
                if !success {
                    self.showAlert(title: "Error", message: "Failed to remove member. Please try again.")
                    return
                }
                
                self.loadMembers() // Refresh the list
            }
        })
        
        present(confirmAlert, animated: true)
    }
    
    private func makeAdmin(_ member: UserGroup.Member) {
        let confirmAlert = UIAlertController(
            title: "Make Admin",
            message: "Are you sure you want to make \(member.name) an admin? They will have full control over the group.",
            preferredStyle: .alert
        )
        
        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        confirmAlert.addAction(UIAlertAction(title: "Make Admin", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            // Update the user's role in Firestore
            self.db.collection("groups").document(self.groupId)
                .collection("members").document(member.userId)
                .updateData(["role": "admin"]) { error in
                    if let error = error {
                        print("Error making member an admin: \(error.localizedDescription)")
                        self.showAlert(title: "Error", message: "Failed to update member role. Please try again.")
                    } else {
                        self.showAlert(title: "Role Updated", message: "\(member.name) is now an admin.")
                        self.loadMembers() // Refresh the list
                    }
                }
        })
        
        present(confirmAlert, animated: true)
    }
    
    private func showProfileForMember(_ member: UserGroup.Member) {
        let userProfileVC = GroupUserProfileViewer(userId: member.userId)
        navigationController?.pushViewController(userProfileVC, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showErrorAlert(message: String) {
        showAlert(title: "Error", message: message)
    }
}
