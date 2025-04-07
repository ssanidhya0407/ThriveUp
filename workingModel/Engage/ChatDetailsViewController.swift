//
//  ChatDetailsViewController.swift
//  ThriveUp
//
//  Created by Yash's Mackbook on 07/04/25.
//


//
//  ChatDetailsViewController.swift
//  ThriveUp
//
//  Created by Sanidhya's MacBook Pro on 07/04/25.
//


import UIKit
import FirebaseFirestore
import FirebaseAuth
import Kingfisher

class ChatDetailsViewController: UIViewController {
    
    // MARK: - Properties
    private let chatId: String
    private let chatTitle: String
    private var isGroup: Bool
    private var participants: [User] = []
    private var currentUserID: String
    private let db = Firestore.firestore()
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let chatImageView = UIImageView()
    private let chatNameLabel = UILabel()
    private let membersHeaderLabel = UILabel()
    private let membersStackView = UIStackView()
    private let settingsHeaderLabel = UILabel()
    
    // MARK: - Initialization
    init(chatId: String, chatTitle: String, isGroup: Bool, participants: [User] = []) {
        self.chatId = chatId
        self.chatTitle = chatTitle
        self.isGroup = isGroup
        self.participants = participants
        self.currentUserID = Auth.auth().currentUser?.uid ?? ""
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadChatDetails()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Chat Details"
        
        // Add Edit button if group admin or direct chat
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .edit,
            target: self,
            action: #selector(editChatTapped)
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
        
        setupChatHeader()
        setupMembersSection()
        setupSettingsSection()
    }
    
    private func setupChatHeader() {
        // Chat image
        chatImageView.contentMode = .scaleAspectFill
        chatImageView.clipsToBounds = true
        chatImageView.layer.cornerRadius = 50
        chatImageView.backgroundColor = .systemGray6
        
        if isGroup {
            chatImageView.image = UIImage(systemName: "person.3")
        } else {
            chatImageView.image = UIImage(systemName: "person")
        }
        
        chatImageView.tintColor = .systemGray3
        chatImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(chatImageView)
        
        // Chat name label
        chatNameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        chatNameLabel.text = chatTitle
        chatNameLabel.textAlignment = .center
        chatNameLabel.numberOfLines = 0
        chatNameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(chatNameLabel)
        
        // Separator line
        let separatorLine = UIView()
        separatorLine.backgroundColor = .systemGray5
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        
        NSLayoutConstraint.activate([
            chatImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            chatImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            chatImageView.widthAnchor.constraint(equalToConstant: 100),
            chatImageView.heightAnchor.constraint(equalToConstant: 100),
            
            chatNameLabel.topAnchor.constraint(equalTo: chatImageView.bottomAnchor, constant: 16),
            chatNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            chatNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            separatorLine.topAnchor.constraint(equalTo: chatNameLabel.bottomAnchor, constant: 20),
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    private func setupMembersSection() {
        // Members header
        membersHeaderLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        membersHeaderLabel.text = isGroup ? "Participants" : "Contact"
        membersHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(membersHeaderLabel)
        
        // Add button for groups
        let addButton = UIButton(type: .system)
        addButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(addMemberTapped), for: .touchUpInside)
        addButton.isHidden = !isGroup
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
        
        // Delete chat / Leave group button
        let deleteChatButton = UIButton(type: .system)
        deleteChatButton.setTitle(isGroup ? "Leave Group" : "Delete Chat", for: .normal)
        deleteChatButton.setTitleColor(.systemRed, for: .normal)
        deleteChatButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        deleteChatButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        deleteChatButton.layer.cornerRadius = 8
        deleteChatButton.addTarget(self, action: #selector(deleteChatTapped), for: .touchUpInside)
        deleteChatButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(deleteChatButton)
        
        // Block user button (only for direct chats)
        let blockUserButton = UIButton(type: .system)
        blockUserButton.setTitle("Block User", for: .normal)
        blockUserButton.setTitleColor(.systemRed, for: .normal)
        blockUserButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        blockUserButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        blockUserButton.layer.cornerRadius = 8
        blockUserButton.addTarget(self, action: #selector(blockUserTapped), for: .touchUpInside)
        blockUserButton.translatesAutoresizingMaskIntoConstraints = false
        blockUserButton.isHidden = isGroup
        contentView.addSubview(blockUserButton)
        
        NSLayoutConstraint.activate([
            settingsHeaderLabel.topAnchor.constraint(equalTo: contentView.subviews.last { $0.backgroundColor == .systemGray5 }!.bottomAnchor, constant: 20),
            settingsHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            deleteChatButton.topAnchor.constraint(equalTo: settingsHeaderLabel.bottomAnchor, constant: 16),
            deleteChatButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            deleteChatButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            deleteChatButton.heightAnchor.constraint(equalToConstant: 50),
            
            blockUserButton.topAnchor.constraint(equalTo: deleteChatButton.bottomAnchor, constant: 16),
            blockUserButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            blockUserButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            blockUserButton.heightAnchor.constraint(equalToConstant: 50),
            blockUserButton.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    // MARK: - Data Loading
    private func loadChatDetails() {
        // Load profile images for participants
        if participants.isEmpty {
            // If no participants provided, fetch them
            fetchParticipants()
        } else {
            updateMembersStackView()
        }
        
        // If direct chat, load the other user's profile
        if !isGroup && participants.count > 0 {
            let otherUser = participants.first(where: { $0.id != currentUserID })
            if let profileURL = otherUser?.profileImageURL, let url = URL(string: profileURL) {
                chatImageView.kf.setImage(
                    with: url,
                    placeholder: UIImage(systemName: "person"),
                    options: [.transition(.fade(0.3))]
                )
            }
        }
        
        // If group, load group image if available
        if isGroup {
            db.collection("chats").document(chatId).getDocument { [weak self] snapshot, error in
                guard let self = self, let data = snapshot?.data() else { return }
                
                if let imageURL = data["imageURL"] as? String, let url = URL(string: imageURL) {
                    self.chatImageView.kf.setImage(
                        with: url,
                        placeholder: UIImage(systemName: "person.3"),
                        options: [.transition(.fade(0.3))]
                    )
                }
            }
        }
    }
    
    private func fetchParticipants() {
        db.collection("chats").document(chatId).getDocument { [weak self] snapshot, error in
            guard let self = self, let data = snapshot?.data() else { return }
            
            if let participantIDs = data["participants"] as? [String] {
                let group = DispatchGroup()
                var users: [User] = []
                
                for userId in participantIDs {
                    group.enter()
                    self.db.collection("users").document(userId).getDocument { snapshot, error in
                        if let userData = snapshot?.data(),
                           let name = userData["name"] as? String {
                            let profileImageURL = userData["profileImageURL"] as? String
                            users.append(User(id: userId, name: name, profileImageURL: profileImageURL))
                        }
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    self.participants = users
                    self.updateMembersStackView()
                }
            }
        }
    }
    
    private func updateMembersStackView() {
        // Clear existing views
        membersStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add participant views
        for participant in participants {
            let memberView = createMemberView(for: participant)
            membersStackView.addArrangedSubview(memberView)
        }
    }
    
    private func createMemberView(for user: User) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        // Profile image
        let profileImageView = UIImageView()
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 20
        profileImageView.backgroundColor = .systemGray5
        profileImageView.image = UIImage(systemName: "person")
        profileImageView.tintColor = .systemGray3
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(profileImageView)
        
        // Name label
        let nameLabel = UILabel()
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        nameLabel.text = user.name
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(nameLabel)
        
        // Role label (for groups)
        let roleLabel = UILabel()
        roleLabel.font = UIFont.systemFont(ofSize: 12)
        roleLabel.textColor = .secondaryLabel
        roleLabel.text = user.id == currentUserID ? "You" : ""
        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(roleLabel)
        
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 40),
            profileImageView.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            roleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            roleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            roleLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -10)
        ])
        
        // Load profile image
        if let imageURL = user.profileImageURL, let url = URL(string: imageURL) {
            profileImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "person"),
                options: [.transition(.fade(0.2))]
            )
        }
        
        // Add tap gesture for user profile
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(userProfileTapped(_:)))
        containerView.addGestureRecognizer(tapGesture)
        containerView.isUserInteractionEnabled = true
        containerView.tag = participants.firstIndex(where: { $0.id == user.id }) ?? 0
        
        return containerView
    }
    
    // MARK: - Actions
    @objc private func editChatTapped() {
        // Implementation for editing chat details
        print("Edit chat details")
    }
    
    @objc private func addMemberTapped() {
        // Implementation for adding members to group
        print("Add member to group")
    }
    
    @objc private func deleteChatTapped() {
        let title = isGroup ? "Leave Group" : "Delete Chat"
        let message = isGroup ? "Are you sure you want to leave this group?" : "Are you sure you want to delete this chat?"
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: title, style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            if self.isGroup {
                self.leaveGroup()
            } else {
                self.deleteChat()
            }
        })
        
        present(alert, animated: true)
    }
    
    @objc private func blockUserTapped() {
        guard !isGroup else { return }
        
        let alert = UIAlertController(
            title: "Block User",
            message: "Are you sure you want to block this user? They will no longer be able to send you messages.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Block", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.blockUser()
        })
        
        present(alert, animated: true)
    }
    
    @objc private func userProfileTapped(_ gesture: UITapGestureRecognizer) {
        guard let index = gesture.view?.tag, participants.indices.contains(index) else { return }
        
        let user = participants[index]
        print("View profile of user: \(user.name)")
        // Show user profile
    }
    
    // MARK: - Chat Actions
    private func leaveGroup() {
        // Remove current user from group
        db.collection("chats").document(chatId).updateData([
            "participants": FieldValue.arrayRemove([currentUserID])
        ]) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error leaving group: \(error.localizedDescription)")
                self.showAlert(title: "Error", message: "Failed to leave group. Please try again.")
            } else {
                // Navigate back to chat list
                self.navigateBackToChatList()
            }
        }
    }
    
    private func deleteChat() {
        // Mark chat as deleted for current user (don't actually delete the chat)
        db.collection("users").document(currentUserID)
            .collection("deletedChats").document(chatId)
            .setData([
                "deletedAt": FieldValue.serverTimestamp()
            ]) { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error deleting chat: \(error.localizedDescription)")
                    self.showAlert(title: "Error", message: "Failed to delete chat. Please try again.")
                } else {
                    // Navigate back to chat list
                    self.navigateBackToChatList()
                }
            }
    }
    
    private func blockUser() {
        // Get the other user's ID
        guard let otherUserId = participants.first(where: { $0.id != currentUserID })?.id else {
            return
        }
        
        // Add to blocked users list
        db.collection("users").document(currentUserID)
            .collection("blockedUsers").document(otherUserId)
            .setData([
                "blockedAt": FieldValue.serverTimestamp()
            ]) { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error blocking user: \(error.localizedDescription)")
                    self.showAlert(title: "Error", message: "Failed to block user. Please try again.")
                } else {
                    self.showAlert(title: "User Blocked", message: "You have blocked this user successfully.")
                }
            }
    }
    
    private func navigateBackToChatList() {
        // Navigate back to the chat list
        if let navigationController = navigationController {
            // Go back to the root or a specific view controller
            navigationController.popToRootViewController(animated: true)
        } else {
            // Just dismiss if no navigation controller
            dismiss(animated: true)
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}