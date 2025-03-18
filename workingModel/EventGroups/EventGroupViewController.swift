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
    
    private func loadMembers() {
        eventGroupManager.getGroupMembers(eventId: eventId) { [weak self] members in
            guard let self = self else { return }
            self.members = members
            
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if segmentedControl.selectedSegmentIndex == 0 {
            // Chat mode
            let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
            let message = messages[indexPath.row]
            cell.configure(with: message)
            return cell
        } else {
            // Members mode
            let cell = tableView.dequeueReusableCell(withIdentifier: "MemberCell", for: indexPath) as! MemberCell
            let member = members[indexPath.row]
            cell.configure(with: member)
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension EventGroupViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if segmentedControl.selectedSegmentIndex == 1 && isOrganizer {
            // Show member management options when tapping on a member
            let member = members[indexPath.row]
            showMemberOptions(for: member)
        }
    }
}
