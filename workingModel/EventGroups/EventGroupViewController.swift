//
//  EventGroupViewController.swift
//  ThriveUp
//
//  Created by Sanidhya's MacBook Pro on 16/03/25.
//


import UIKit
import FirebaseFirestore
import FirebaseAuth

class EventGroupViewController: UIViewController {
    
    // MARK: - Properties
    private let eventId: String
    private let isOrganizer: Bool
    private let eventGroupManager = EventGroupManager()
    private var members: [EventGroupMember] = []
    private var messages: [EventGroupMessage] = []
    private var chatEnabled: Bool = true
    private let db = Firestore.firestore()
    
    // Add this property to store organizer IDs
    private var organizerIds: [String] = []
    
    // UI Components
    private let tableView = UITableView()
    private let segmentedControl = UISegmentedControl(items: ["Chat", "Members"])
    private let messageField = UITextField()
    private let sendButton = UIButton()
    private let noPermissionLabel = UILabel()
    private let settingsButton = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: nil, action: nil)
    
    // MARK: - Initialization
    init(eventId: String, isOrganizer: Bool = false) {
        self.eventId = eventId
        self.isOrganizer = isOrganizer
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadGroupSettings()
        loadMembers()
        loadMessages()
        
        // Add observer for new messages if viewing chat
        if segmentedControl.selectedSegmentIndex == 0 {
            addMessageObserver()
        }
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .white
        title = "Event Group"
        
        // Setup segmented control
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentedControl)
        
        // Setup table view
        tableView.register(MessageCell.self, forCellReuseIdentifier: "MessageCell")
        tableView.register(MemberCell.self, forCellReuseIdentifier: "MemberCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        // Setup message input area
        let inputContainer = UIView()
        inputContainer.backgroundColor = .systemGray6
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputContainer)
        
        messageField.placeholder = "Type a message..."
        messageField.borderStyle = .roundedRect
        messageField.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(messageField)
        
        sendButton.setTitle("Send", for: .normal)
        sendButton.setTitleColor(.systemBlue, for: .normal)
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(sendButton)
        
        // Setup no permission label
        noPermissionLabel.text = "Chat is disabled"
        noPermissionLabel.textAlignment = .center
        noPermissionLabel.isHidden = true
        noPermissionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(noPermissionLabel)
        
        // Add settings button for organizers
        if isOrganizer {
            settingsButton.target = self
            settingsButton.action = #selector(showSettings)
            navigationItem.rightBarButtonItem = settingsButton
        }
        
        // Setup constraints
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor),
            
            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainer.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            inputContainer.heightAnchor.constraint(equalToConstant: 60),
            
            messageField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 16),
            messageField.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            messageField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            
            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 60),
            
            noPermissionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noPermissionLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Data Loading
    private func loadGroupSettings() {
        db.collection("eventGroups").document(eventId)
            .getDocument { [weak self] (snapshot, error) in
                guard let self = self,
                      let data = snapshot?.data(),
                      let settings = data["settings"] as? [String: Any] else {
                    return
                }
                
                if let chatEnabled = settings["chatEnabled"] as? Bool {
                    self.chatEnabled = chatEnabled
                    self.updateChatUI()
                }
            }
    }
    
    // MARK: - Load Members
    private func loadMembers() {
        eventGroupManager.getGroupMembers(eventId: eventId) { [weak self] members in
            guard let self = self else { return }
            self.members = members
            
            // Extract organizer IDs for later use in chat
            self.organizerIds = members.filter { $0.role == "organizer" }.map { $0.userId }
            
            if self.segmentedControl.selectedSegmentIndex == 1 {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    private func loadMessages() {
        eventGroupManager.getMessages(eventId: eventId) { [weak self] messages in
            guard let self = self else { return }
            self.messages = messages.sorted(by: { $0.timestamp < $1.timestamp })
            
            if self.segmentedControl.selectedSegmentIndex == 0 {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.scrollToLatestMessage()
                }
            }
        }
    }
    
    private func addMessageObserver() {
        // Setup a real-time listener for new messages
        db.collection("eventGroups").document(eventId)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { [weak self] (snapshot, error) in
                guard let self = self,
                      self.segmentedControl.selectedSegmentIndex == 0,
                      let documents = snapshot?.documentChanges else {
                    return
                }
                
                var shouldScroll = false
                
                // Only process new messages
                for change in documents where change.type == .added {
                    let data = change.document.data()
                    
                    if let id = data["id"] as? String,
                       let userId = data["userId"] as? String,
                       let userName = data["userName"] as? String,
                       let text = data["text"] as? String,
                       let timestamp = data["timestamp"] as? Timestamp,
                       !self.messages.contains(where: { $0.id == id }) {
                        
                        let newMessage = EventGroupMessage(
                            id: id,
                            userId: userId,
                            userName: userName,
                            text: text,
                            timestamp: timestamp.dateValue(),
                            profileImageURL: data["profileImageURL"] as? String
                        )
                        
                        self.messages.append(newMessage)
                        shouldScroll = true
                    }
                }
                
                if shouldScroll {
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.scrollToLatestMessage()
                    }
                }
            }
    }
    
    private func scrollToLatestMessage() {
        guard !messages.isEmpty else { return }
        
        let lastIndex = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: lastIndex, at: .bottom, animated: true)
    }
    
    private func updateChatUI() {
        // Show/hide chat UI based on permissions
        if segmentedControl.selectedSegmentIndex == 0 {
            if !chatEnabled {
                messageField.isEnabled = false
                sendButton.isEnabled = false
                noPermissionLabel.isHidden = false
                noPermissionLabel.text = "Chat is disabled for this event"
            } else {
                // Check if current user has chat permission
                checkCurrentUserChatPermission()
            }
        } else {
            noPermissionLabel.isHidden = true
        }
    }
    
    private func checkCurrentUserChatPermission() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            messageField.isEnabled = false
            sendButton.isEnabled = false
            noPermissionLabel.isHidden = false
            noPermissionLabel.text = "You must be logged in to chat"
            return
        }
        
        // Find the current user in members
        if let currentMember = members.first(where: { $0.userId == currentUserId }) {
            messageField.isEnabled = currentMember.canChat
            sendButton.isEnabled = currentMember.canChat
            noPermissionLabel.isHidden = currentMember.canChat
            
            if !currentMember.canChat {
                noPermissionLabel.text = "You don't have permission to chat"
            }
        } else {
            // If user isn't found in members, fetch from Firestore
            db.collection("eventGroups").document(eventId)
                .collection("members").document(currentUserId)
                .getDocument { [weak self] (snapshot, error) in
                    guard let self = self else { return }
                    
                    if let data = snapshot?.data(),
                       let canChat = data["canChat"] as? Bool {
                        DispatchQueue.main.async {
                            self.messageField.isEnabled = canChat
                            self.sendButton.isEnabled = canChat
                            self.noPermissionLabel.isHidden = canChat
                            
                            if !canChat {
                                self.noPermissionLabel.text = "You don't have permission to chat"
                            }
                        }
                    } else {
                        // User is not in the group
                        DispatchQueue.main.async {
                            self.messageField.isEnabled = false
                            self.sendButton.isEnabled = false
                            self.noPermissionLabel.isHidden = false
                            self.noPermissionLabel.text = "You are not a member of this event group"
                        }
                    }
                }
        }
    }
    
    // MARK: - Actions
    @objc private func segmentChanged() {
        if segmentedControl.selectedSegmentIndex == 0 {
            // Show chat
            loadMessages()
            updateChatUI()
        } else {
            // Show members
            loadMembers()
            noPermissionLabel.isHidden = true
        }
        
        tableView.reloadData()
    }
    
    @objc private func sendMessage() {
        guard let messageText = messageField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !messageText.isEmpty else {
            return
        }
        
        eventGroupManager.sendMessage(eventId: eventId, text: messageText) { [weak self] success in
            if success {
                DispatchQueue.main.async {
                    self?.messageField.text = ""
                }
            } else {
                // Show an error
                let alert = UIAlertController(
                    title: "Error",
                    message: "Failed to send message. Please try again.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
        }
    }

    @objc private func showSettings() {
        // Create action sheet with group management options
        let actionSheet = UIAlertController(
            title: "Event Group Settings",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        // Add options
        actionSheet.addAction(UIAlertAction(title: "Manage Members", style: .default) { [weak self] _ in
            self?.showMemberManagement()
        })
        
        // Check if any non-organizer member has chat enabled
        let anyNonOrganizerCanChat = members.contains { member in
            member.role != "organizer" && member.canChat
        }
        
        // Set button text based on whether any non-organizer can chat
        let chatActionTitle = anyNonOrganizerCanChat ? "Disable Chat" : "Enable Chat"
        
        actionSheet.addAction(UIAlertAction(title: chatActionTitle, style: .default) { [weak self] _ in
            self?.toggleGroupChat()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Present the action sheet
        present(actionSheet, animated: true)
    }
    
    private func showMemberManagement() {
        // Switch to members tab
        segmentedControl.selectedSegmentIndex = 1
        segmentChanged()
    }
    
    private func toggleGroupChat() {
        // Check if any non-organizer can currently chat
        let anyNonOrganizerCanChat = members.contains { member in
            member.role != "organizer" && member.canChat
        }
        
        // Get the current user (organizer) ID
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Show loading indicator
        let loadingAlert = UIAlertController(title: "Updating Permissions", message: "Please wait...", preferredStyle: .alert)
        present(loadingAlert, animated: true)
        
        // Get all members from database
        db.collection("eventGroups").document(eventId)
            .collection("members")
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self, let documents = snapshot?.documents else {
                    loadingAlert.dismiss(animated: true)
                    return
                }
                
                let dispatchGroup = DispatchGroup()
                var updateCount = 0
                
                // For each member, update their chat permission
                for doc in documents {
                    let userId = doc.documentID
                    
                    // Skip the organizer - always keep their chat enabled
                    if userId == currentUserId {
                        continue
                    }
                    
                    dispatchGroup.enter()
                    
                    // Set everyone else's permission based on our toggle state
                    // If some can chat now, disable all. If none can chat, enable all.
                    self.eventGroupManager.updateMemberChatPermission(
                        eventId: self.eventId,
                        userId: userId,
                        canChat: !anyNonOrganizerCanChat
                    ) { success in
                        if success {
                            updateCount += 1
                        }
                        dispatchGroup.leave()
                    }
                }
                
                // When all updates are complete
                dispatchGroup.notify(queue: .main) {
                    loadingAlert.dismiss(animated: true) {
                        // Refresh the member list to show updated permissions
                        self.loadMembers()
                        
                        // Show confirmation
                        let message = anyNonOrganizerCanChat ?
                            "Chat disabled for all members except You" :
                            "Chat enabled for all members"
                        
                        let alert = UIAlertController(
                            title: "Settings Updated",
                            message: message,
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                    }
                }
            }
    }
    
    private func showMemberOptions(for member: EventGroupMember) {
        // Don't show options for the organizer (yourself)
        guard member.role != "organizer" else { return }
        
        let actionSheet = UIAlertController(
            title: "Manage \(member.name)",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        // Toggle chat permission
        let chatActionTitle = member.canChat ? "Disable Chat Permission" : "Enable Chat Permission"
        actionSheet.addAction(UIAlertAction(title: chatActionTitle, style: .default) { [weak self] _ in
            self?.toggleMemberChatPermission(member: member)
        })
        
        // Remove from group
        actionSheet.addAction(UIAlertAction(title: "Remove from Group", style: .destructive) { [weak self] _ in
            self?.removeMemberFromGroup(member: member)
        })
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(actionSheet, animated: true)
    }
    
    private func toggleMemberChatPermission(member: EventGroupMember) {
        let newChatPermission = !member.canChat
        
        eventGroupManager.updateMemberChatPermission(eventId: eventId, userId: member.userId, canChat: newChatPermission) { [weak self] success in
            if success {
                // Refresh the member list
                self?.loadMembers()
                
                // Show confirmation
                let message = newChatPermission ?
                    "\(member.name) can now chat in the group" :
                    "\(member.name) can no longer chat in the group"
                    
                let alert = UIAlertController(
                    title: "Member Updated",
                    message: message,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            } else {
                // Show error
                let alert = UIAlertController(
                    title: "Error",
                    message: "Failed to update member permission. Please try again.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
        }
    }
    
    private func removeMemberFromGroup(member: EventGroupMember) {
        // Show confirmation first
        let alert = UIAlertController(
            title: "Remove Member",
            message: "Are you sure you want to remove \(member.name) from this event group?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            self.eventGroupManager.removeUserFromEventGroup(eventId: self.eventId, userId: member.userId) { success in
                if success {
                    // Refresh the member list
                    self.loadMembers()
                    
                    // Show confirmation
                    let successAlert = UIAlertController(
                        title: "Member Removed",
                        message: "\(member.name) has been removed from the group",
                        preferredStyle: .alert
                    )
                    successAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(successAlert, animated: true)
                } else {
                    // Show error
                    let errorAlert = UIAlertController(
                        title: "Error",
                        message: "Failed to remove member. Please try again.",
                        preferredStyle: .alert
                    )
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(errorAlert, animated: true)
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Profile Display Methods
    private func showProfileForMember(_ member: EventGroupMember) {
        if member.role == "organizer" {
            // Show organizer profile
            let organizerProfileVC = OrganizerProfileViewerController(organizerId: member.userId)
            navigationController?.pushViewController(organizerProfileVC, animated: true)
        } else {
            // Show regular user profile
            let userProfileVC = UserProfileViewerController(userId: member.userId)
            navigationController?.pushViewController(userProfileVC, animated: true)
        }
    }
}

// MARK: - UITableViewDataSource
extension EventGroupViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentedControl.selectedSegmentIndex == 0 {
            return messages.count
        } else {
            return members.count
        }
    }
    
    // Update the tableView cellForRowAt method to pass the organizer status
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if segmentedControl.selectedSegmentIndex == 0 {
            // Chat mode
            let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
            let message = messages[indexPath.row]
            cell.configure(with: message, organizers: organizerIds) // Pass organizer IDs
            return cell
        } else {
            // Members mode
            let cell = tableView.dequeueReusableCell(withIdentifier: "MemberCell", for: indexPath) as! MemberCell
            let member = members[indexPath.row]
            cell.configure(with: member, viewedByOrganizer: isOrganizer)
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension EventGroupViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if segmentedControl.selectedSegmentIndex == 1 {
            // In members tab
            let member = members[indexPath.row]
            
            if isOrganizer {
                // If current user is organizer, show member management options
                showMemberOptions(for: member)
            } else {
                // Regular user viewing member list - show appropriate profile
                showProfileForMember(member)
            }
        }
    }
}

// MARK: - Profile Viewer Controllers
// Modified UserProfileViewerController class to match ProfileViewController functionality
class UserProfileViewerController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let userId: String
    private let db = Firestore.firestore()
    private var registeredEvents: [EventModel] = []
    private var userInterests: [String] = []
    
    // UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let emailLabel = UILabel()
    private let friendsLabel = UILabel()
    private let segmentControl = UISegmentedControl(items: ["Details", "Events"])
    private let detailsStackView = UIStackView()
    private let descriptionLabel = UILabel()
    private let contactDetailsLabel = UILabel()
    private let githubLabel = UILabel()
    private let linkedinLabel = UILabel()
    private let techStackLabel = UILabel()
    private let interestsView = UIView()
    private let interestsLabel = UILabel()
    private let interestsGridView = UIStackView()
    private let eventsTableView = UITableView()
    
    init(userId: String) {
        self.userId = userId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        loadUserDetails()
        loadUserInterests()
        loadRegisteredEvents()
        fetchFriendsCount()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        title = "User Profile"
        view.backgroundColor = .white
        
        // Configure scrollView and contentView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Configure profileImageView
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 50
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor.white.cgColor
        profileImageView.backgroundColor = .lightGray
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileImageView)
        
        // Configure name label
        nameLabel.font = UIFont.boldSystemFont(ofSize: 22)
        nameLabel.textColor = .black
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        
        // Configure email label
        emailLabel.font = UIFont.systemFont(ofSize: 16)
        emailLabel.textColor = .gray
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(emailLabel)
        
        // Configure friends label
        friendsLabel.font = UIFont.systemFont(ofSize: 18)
        friendsLabel.textColor = .darkGray
        friendsLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(friendsLabel)
        
        // Configure segment control
        segmentControl.selectedSegmentIndex = 0
        segmentControl.selectedSegmentTintColor = UIColor.orange
        segmentControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(segmentControl)
        
        // Configure details stack view
        detailsStackView.axis = .vertical
        detailsStackView.distribution = .fill
        detailsStackView.spacing = 12
        detailsStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(detailsStackView)
        
        // Configure description label
        descriptionLabel.text = "Description: Loading..."
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textColor = .darkGray
        descriptionLabel.numberOfLines = 0
        detailsStackView.addArrangedSubview(descriptionLabel)
        
        // Configure contact details label
        contactDetailsLabel.text = "Contact: Loading..."
        contactDetailsLabel.font = UIFont.systemFont(ofSize: 16)
        contactDetailsLabel.textColor = .gray
        contactDetailsLabel.numberOfLines = 0
        detailsStackView.addArrangedSubview(contactDetailsLabel)
        
        // Configure github label
        githubLabel.text = "GitHub: Loading..."
        githubLabel.font = UIFont.systemFont(ofSize: 16)
        githubLabel.textColor = .gray
        githubLabel.numberOfLines = 0
        detailsStackView.addArrangedSubview(githubLabel)
        
        // Configure linkedin label
        linkedinLabel.text = "LinkedIn: Loading..."
        linkedinLabel.font = UIFont.systemFont(ofSize: 16)
        linkedinLabel.textColor = .gray
        linkedinLabel.numberOfLines = 0
        detailsStackView.addArrangedSubview(linkedinLabel)
        
        // Configure tech stack label
        techStackLabel.text = "Tech Stack: Loading..."
        techStackLabel.font = UIFont.systemFont(ofSize: 16)
        techStackLabel.textColor = .gray
        techStackLabel.numberOfLines = 0
        detailsStackView.addArrangedSubview(techStackLabel)
        
        // Configure interests view
        interestsView.translatesAutoresizingMaskIntoConstraints = false
        detailsStackView.addArrangedSubview(interestsView)
        
        // Configure interests label
        interestsLabel.text = "Interests"
        interestsLabel.font = UIFont.boldSystemFont(ofSize: 18)
        interestsLabel.textColor = .black
        interestsLabel.translatesAutoresizingMaskIntoConstraints = false
        interestsView.addSubview(interestsLabel)
        
        // Configure interests grid view
        interestsGridView.axis = .vertical
        interestsGridView.spacing = 16
        interestsGridView.distribution = .fillEqually
        interestsGridView.translatesAutoresizingMaskIntoConstraints = false
        interestsView.addSubview(interestsGridView)
        
        // Configure events table view
        eventsTableView.register(RegisteredEventCell.self, forCellReuseIdentifier: RegisteredEventCell.identifier)
        eventsTableView.delegate = self
        eventsTableView.dataSource = self
        eventsTableView.isHidden = true
        eventsTableView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(eventsTableView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),
            
            nameLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            emailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            emailLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            friendsLabel.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 4),
            friendsLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            friendsLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            segmentControl.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            segmentControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            segmentControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            detailsStackView.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 20),
            detailsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            detailsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            detailsStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20),
            
            interestsLabel.topAnchor.constraint(equalTo: interestsView.topAnchor),
            interestsLabel.leadingAnchor.constraint(equalTo: interestsView.leadingAnchor),
            
            interestsGridView.topAnchor.constraint(equalTo: interestsLabel.bottomAnchor, constant: 8),
            interestsGridView.leadingAnchor.constraint(equalTo: interestsView.leadingAnchor),
            interestsGridView.trailingAnchor.constraint(equalTo: interestsView.trailingAnchor),
            interestsGridView.bottomAnchor.constraint(equalTo: interestsView.bottomAnchor),
            
            eventsTableView.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 16),
            eventsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            eventsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            eventsTableView.heightAnchor.constraint(equalToConstant: 400),
            eventsTableView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Load User Details
    private func loadUserDetails() {
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching user details: \(error.localizedDescription)")
                return
            }
            
            guard let data = document?.data() else {
                print("No user data found for userId: \(userId)")
                return
            }
            
            self.nameLabel.text = data["name"] as? String ?? "Name"
            self.emailLabel.text = data["email"] as? String ?? "Email"
            self.contactDetailsLabel.text = "Contact: \(data["ContactDetails"] as? String ?? "Not Available")"
            self.descriptionLabel.text = "Description: \(data["Description"] as? String ?? "No Description Available")"
            self.githubLabel.text = "GitHub: \(data["githubUrl"] as? String ?? "Not Available")"
            self.linkedinLabel.text = "LinkedIn: \(data["linkedinUrl"] as? String ?? "Not Available")"
            self.techStackLabel.text = "Tech Stack: \(data["techStack"] as? String ?? "Not Available")"
            
            if let profileImageURLString = data["profileImageURL"] as? String,
               let profileImageURL = URL(string: profileImageURLString) {
                self.loadProfileImage(from: profileImageURL)
            } else {
                self.profileImageView.image = UIImage(named: "default_profile")
            }
        }
    }
    
    // MARK: - Load User Interests
    private func loadUserInterests() {
        db.collection("Interest").document(userId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching user interests: \(error.localizedDescription)")
                return
            }
            
            guard let data = document?.data(), let interests = data["interests"] as? [String] else {
                print("No interests data found.")
                return
            }
            
            self.userInterests = interests
            self.updateInterestsUI()
        }
    }
    
    private func updateInterestsUI() {
        interestsGridView.arrangedSubviews.forEach { $0.removeFromSuperview() } // Clear existing views
        
        let columns = 2
        var currentRowStack: UIStackView?
        
        for (index, interest) in userInterests.enumerated() {
            if index % columns == 0 {
                currentRowStack = UIStackView()
                currentRowStack?.axis = .horizontal
                currentRowStack?.spacing = 12
                currentRowStack?.distribution = .fillEqually
                interestsGridView.addArrangedSubview(currentRowStack!)
            }
            
            let button = UIButton(type: .system)
            button.setTitle(interest, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            button.backgroundColor = UIColor.systemGray5
            button.layer.cornerRadius = 8
            button.clipsToBounds = true
            
            currentRowStack?.addArrangedSubview(button)
        }
        
        interestsView.isHidden = false
    }
    
    // MARK: - Load Profile Image
    private func loadProfileImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Error downloading profile image: \(error.localizedDescription)")
                return
            }
            
            guard
                let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode),
                let data = data,
                let image = UIImage(data: data)
            else {
                print("Invalid response or image data.")
                return
            }
            
            DispatchQueue.main.async {
                self?.profileImageView.image = image
            }
        }.resume()
    }
    
    // MARK: - Load Registered Events
    private func loadRegisteredEvents() {
        db.collection("registrations").whereField("uid", isEqualTo: userId).getDocuments { [weak self] querySnapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching registrations: \(error.localizedDescription)")
                return
            }
            
            let eventIds = querySnapshot?.documents.compactMap { $0.data()["eventId"] as? String } ?? []
            if eventIds.isEmpty {
                print("No registered events found.")
            } else {
                self.fetchEvents(for: eventIds)
            }
        }
    }
    
    private func fetchEvents(for eventIds: [String]) {
        let group = DispatchGroup()
        registeredEvents.removeAll()
        
        for eventId in eventIds {
            group.enter()
            db.collection("events").document(eventId).getDocument { [weak self] document, error in
                defer { group.leave() }
                
                if let error = error {
                    print("Error fetching event details for \(eventId): \(error.localizedDescription)")
                    return
                }
                
                guard let data = document?.data(), let self = self else {
                    print("No data found for eventId: \(eventId)")
                    return
                }
                
                let imageNameOrUrl = data["imageName"] as? String ?? ""
                let isImageUrl = URL(string: imageNameOrUrl)?.scheme != nil
                
                let event = EventModel(
                    eventId: eventId,
                    title: data["title"] as? String ?? "Untitled",
                    category: data["category"] as? String ?? "Uncategorized",
                    attendanceCount: data["attendanceCount"] as? Int ?? 0,
                    organizerName: data["organizerName"] as? String ?? "Unknown",
                    date: data["date"] as? String ?? "Unknown Date",
                    time: data["time"] as? String ?? "Unknown Time",
                    location: data["location"] as? String ?? "Unknown Location",
                    locationDetails: data["locationDetails"] as? String ?? "",
                    imageName: isImageUrl ? imageNameOrUrl : "",
                    speakers: [],
                    userId: data["userId"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    latitude: data["latitude"] as? Double,
                    longitude: data["longitude"] as? Double,
                    tags: []
                )
                self.registeredEvents.append(event)
            }
        }
        
        group.notify(queue: .main) {
            self.eventsTableView.reloadData()
        }
    }
    
    // MARK: - Fetch Friends Count
    private func fetchFriendsCount() {
        db.collection("friends")
            .whereField("userID", isEqualTo: userId)
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching friends count: \(error.localizedDescription)")
                    return
                }
                
                let count = snapshot?.documents.count ?? 0
                DispatchQueue.main.async {
                    self.friendsLabel.text = "Friends: \(count)"
                }
            }
    }
    
    // MARK: - UITableView DataSource & Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return registeredEvents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RegisteredEventCell.identifier, for: indexPath) as! RegisteredEventCell
        cell.configure(with: registeredEvents[indexPath.row])
        cell.delegate = nil // Don't allow unregistering from another user's profile
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Display event details but don't allow actions
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Actions
    @objc private func segmentChanged() {
        let isShowingEvents = segmentControl.selectedSegmentIndex == 1
        detailsStackView.isHidden = isShowingEvents
        eventsTableView.isHidden = !isShowingEvents
        
        if isShowingEvents {
            loadRegisteredEvents()
        }
    }
}



class OrganizerProfileViewerController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let organizerId: String
    private let db = Firestore.firestore()
    private var createdEvents: [EventModel] = []
    
    // UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let emailLabel = UILabel()
    private let segmentControl = UISegmentedControl(items: ["Details", "Events"])
    private let aboutLabel = UILabel()
    private let aboutDescriptionLabel = UILabel()
    private let detailsStackView = UIStackView()
    private let eventsTableView = UITableView()
    
    init(organizerId: String) {
        self.organizerId = organizerId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        fetchOrganizerData()
        fetchCreatedEvents()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        title = "Organizer Profile"
        view.backgroundColor = .white
        
        // Configure scrollView and contentView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Configure profileImageView
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 50
        profileImageView.layer.borderWidth = 3
        profileImageView.layer.borderColor = UIColor.systemOrange.cgColor
        profileImageView.backgroundColor = .lightGray
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileImageView)
        
        // Configure name label
        nameLabel.font = UIFont.boldSystemFont(ofSize: 24)
        nameLabel.textColor = .black
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        
        // Configure email label
        emailLabel.font = UIFont.systemFont(ofSize: 16)
        emailLabel.textColor = .gray
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(emailLabel)
        
        // Configure segment control
        segmentControl.selectedSegmentIndex = 0
        segmentControl.selectedSegmentTintColor = UIColor.orange
        segmentControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(segmentControl)
        
        // Configure about label
        aboutLabel.text = "About"
        aboutLabel.font = UIFont.boldSystemFont(ofSize: 20)
        aboutLabel.textColor = .black
        aboutLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(aboutLabel)
        
        // Configure about description label
        aboutDescriptionLabel.text = "Loading description..."
        aboutDescriptionLabel.font = UIFont.systemFont(ofSize: 16)
        aboutDescriptionLabel.textColor = .darkGray
        aboutDescriptionLabel.numberOfLines = 0
        aboutDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(aboutDescriptionLabel)
        
        // Configure details stack view
        detailsStackView.axis = .vertical
        detailsStackView.distribution = .fillEqually
        detailsStackView.spacing = 16
        detailsStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(detailsStackView)
        
        // Add detail views
        let eventsCountView = createDetailView(title: "Number of Events", value: "Loading...")
        let contactView = createDetailView(title: "Contact", value: "Loading...")
        let pocView = createDetailView(title: "Person of Contact", value: "Loading...")
        [eventsCountView, contactView, pocView].forEach { detailsStackView.addArrangedSubview($0) }
        
        // Configure events table view
        eventsTableView.register(EventTableViewCell.self, forCellReuseIdentifier: EventTableViewCell.identifier)
        eventsTableView.delegate = self
        eventsTableView.dataSource = self
        eventsTableView.isHidden = true
        eventsTableView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(eventsTableView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),
            
            nameLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            emailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            emailLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            segmentControl.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            segmentControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            segmentControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            aboutLabel.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 20),
            aboutLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            aboutDescriptionLabel.topAnchor.constraint(equalTo: aboutLabel.bottomAnchor, constant: 8),
            aboutDescriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            aboutDescriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            detailsStackView.topAnchor.constraint(equalTo: aboutDescriptionLabel.bottomAnchor, constant: 20),
            detailsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            detailsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            detailsStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20),
            
            eventsTableView.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 16),
            eventsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            eventsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            eventsTableView.heightAnchor.constraint(equalToConstant: 400),
            eventsTableView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func createDetailView(title: String, value: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = .orange
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 14)
        valueLabel.textColor = .gray
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .leading
        return stackView
    }
    
    // MARK: - Load Organizer Data
    private func fetchOrganizerData() {
        db.collection("users").document(organizerId).getDocument { [weak self] document, error in
            guard let self = self, let data = document?.data(), error == nil else { return }
            
            self.nameLabel.text = data["name"] as? String ?? "Organizer Name"
            self.emailLabel.text = data["email"] as? String ?? "Email"
            self.aboutDescriptionLabel.text = data["Description"] as? String ?? "No description provided."
            
            if let contact = data["ContactDetails"] as? String,
               let contactLabel = self.detailsStackView.arrangedSubviews[1].subviews.last as? UILabel {
                contactLabel.text = contact
            }
            
            if let poc = data["POC"] as? String,
               let pocLabel = self.detailsStackView.arrangedSubviews[2].subviews.last as? UILabel {
                pocLabel.text = poc
            }
            
            if let profileImageURLString = data["profileImageURL"] as? String,
               let profileImageURL = URL(string: profileImageURLString) {
                self.loadProfileImage(from: profileImageURL)
            }
        }
    }
    
    private func loadProfileImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.profileImageView.image = image
            }
        }.resume()
    }
    
    // MARK: - Fetch Created Events
    private func fetchCreatedEvents() {
        db.collection("events").whereField("userId", isEqualTo: organizerId)
            .whereField("status", isEqualTo: "accepted")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents, error == nil else { return }
                
                self.createdEvents = documents.map { doc in
                    let data = doc.data()
                    
                    // Handle speakers conversion from Firestore data to Speaker objects
                    var speakersArray: [Speaker] = []
                    if let speakersData = data["speakers"] as? [[String: Any]] {
                        speakersArray = speakersData.compactMap { speakerData in
                            // Convert each dictionary to a Speaker object
                            let name = speakerData["name"] as? String ?? ""
                            let bio = speakerData["bio"] as? String ?? ""
                            let imageUrl = speakerData["imageUrl"] as? String ?? ""
                            
                            return Speaker(name: name, imageURL: imageUrl)
                        }
                    }
                    
                    return EventModel(
                        eventId: doc.documentID,
                        title: data["title"] as? String ?? "Untitled Event",
                        category: data["category"] as? String ?? "Uncategorized",
                        attendanceCount: data["attendanceCount"] as? Int ?? 0,
                        organizerName: data["organizerName"] as? String ?? "Unknown Organizer",
                        date: data["date"] as? String ?? "Unknown Date",
                        time: data["time"] as? String ?? "Unknown Time",
                        location: data["location"] as? String ?? "Unknown Location",
                        locationDetails: data["locationDetails"] as? String ?? "",
                        imageName: data["imageName"] as? String ?? "",
                        speakers: speakersArray,
                        userId: self.organizerId,
                        description: data["description"] as? String ?? "",
                        tags: data["tags"] as? [String] ?? [String]()
                    )
                }
                
                // Update events count in the details section
                if let eventsCountLabel = self.detailsStackView.arrangedSubviews[0].subviews.last as? UILabel {
                    eventsCountLabel.text = "\(self.createdEvents.count)"
                }
                
                DispatchQueue.main.async {
                    self.eventsTableView.reloadData()
                }
            }
    }
    
    // MARK: - UITableView DataSource & Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return createdEvents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: EventTableViewCell.identifier, for: indexPath) as! EventTableViewCell
        cell.configure(with: createdEvents[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Show event details but don't navigate to registration list
        tableView.deselectRow(at: indexPath, animated: true)
        
        // You could implement showing event details here if needed
    }
    
    // MARK: - Actions
    @objc private func segmentChanged() {
        let isEventsSelected = segmentControl.selectedSegmentIndex == 1
        aboutLabel.isHidden = isEventsSelected
        aboutDescriptionLabel.isHidden = isEventsSelected
        detailsStackView.isHidden = isEventsSelected
        eventsTableView.isHidden = !isEventsSelected
        
        if isEventsSelected && createdEvents.isEmpty {
            fetchCreatedEvents()
        }
    }
}
