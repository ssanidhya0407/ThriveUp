import UIKit
import FirebaseFirestore
import FirebaseAuth
import Kingfisher

class EventGroupMemberVC: UIViewController {
    
    // MARK: - Properties
    private let eventId: String
    private let eventName: String
    private let tableView = UITableView()
    private var members: [EventGroup.Member] = []
    private let currentUserID = Auth.auth().currentUser?.uid ?? ""
    private var isCurrentUserOrganizer = false
    private let db = Firestore.firestore()
    private let eventGroupManager = EventGroupManager()
    
    // UI Components
    private let headerView = UIView()
    private let eventImageView = UIImageView()
    private let eventNameLabel = UILabel()
    private let detailsLabel = UILabel()
    private let dividerLine = UIView()
    
    // MARK: - Initialization
    init(eventId: String, eventName: String) {
        self.eventId = eventId
        self.eventName = eventName
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadEventDetails()
        loadMembers()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Event Participants"
        
        // Configure header view
        setupHeaderView()
        
        // Setup table view
        setupTableView()
        
        // Setup add member button (will be visible only for organizers)
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addMemberTapped))
        navigationItem.rightBarButtonItem = addButton
        addButton.isEnabled = false // Will be enabled when we confirm user is organizer
    }
    
    private func setupHeaderView() {
        headerView.backgroundColor = .systemBackground
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        
        // Event image
        eventImageView.contentMode = .scaleAspectFill
        eventImageView.clipsToBounds = true
        eventImageView.layer.cornerRadius = 40
        eventImageView.backgroundColor = .systemGray6
        eventImageView.image = UIImage(systemName: "calendar")
        eventImageView.tintColor = .systemGray3
        eventImageView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(eventImageView)
        
        // Event name label
        eventNameLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        eventNameLabel.text = eventName
        eventNameLabel.textAlignment = .center
        eventNameLabel.numberOfLines = 2
        eventNameLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(eventNameLabel)
        
        // Details label (members count)
        detailsLabel.font = UIFont.systemFont(ofSize: 14)
        detailsLabel.textColor = .secondaryLabel
        detailsLabel.textAlignment = .center
        detailsLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(detailsLabel)
        
        // Divider line
        dividerLine.backgroundColor = .systemGray5
        dividerLine.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(dividerLine)
        
        // Set constraints
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            eventImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            eventImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            eventImageView.widthAnchor.constraint(equalToConstant: 80),
            eventImageView.heightAnchor.constraint(equalToConstant: 80),
            
            eventNameLabel.topAnchor.constraint(equalTo: eventImageView.bottomAnchor, constant: 12),
            eventNameLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            eventNameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            detailsLabel.topAnchor.constraint(equalTo: eventNameLabel.bottomAnchor, constant: 4),
            detailsLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            detailsLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            dividerLine.topAnchor.constraint(equalTo: detailsLabel.bottomAnchor, constant: 16),
            dividerLine.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            dividerLine.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            dividerLine.heightAnchor.constraint(equalToConstant: 0.5),
            dividerLine.bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(EventMemberCell.self, forCellReuseIdentifier: "EventMemberCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.rowHeight = 70
        tableView.backgroundColor = .systemBackground
        view.addSubview(tableView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Data Loading
    private func loadEventDetails() {
        db.collection("eventGroups").document(eventId).getDocument { [weak self] (snapshot, error) in
            guard let self = self, let data = snapshot?.data() else {
                print("Error fetching event details: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            // Update UI with event details
            DispatchQueue.main.async {
                if let name = data["name"] as? String {
                    self.eventNameLabel.text = name
                    self.title = name
                }
                
                // Load event image if available
                if let imageURL = data["imageURL"] as? String, let url = URL(string: imageURL) {
                    self.eventImageView.kf.setImage(
                        with: url,
                        placeholder: UIImage(systemName: "calendar"),
                        options: [.transition(.fade(0.3))]
                    )
                }
            }
        }
    }
    
    private func loadMembers() {
        // First, ensure we clear any existing members
        self.members = []
        
        // Create a reference to the members collection
        let membersCollection = db.collection("eventGroups").document(eventId).collection("members")
        
        // Fetch all documents in the members collection
        membersCollection.getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching members: \(error.localizedDescription)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No members found")
                self.updateMembersCount()
                self.tableView.reloadData()
                return
            }
            
            // Create a dispatch group to wait for all user data to be fetched
            let dispatchGroup = DispatchGroup()
            
            // Temporary array to hold members while we load them
            var loadedMembers: [EventGroup.Member] = []
            
            for document in documents {
                let data = document.data()
                let userId = document.documentID
                let role = data["role"] as? String ?? "participant"
                let canChat = data["canChat"] as? Bool ?? true
                
                // Get the joined timestamp
                let joinedTimestamp = data["joinedAt"] as? Timestamp ?? Timestamp(date: Date())
                let joinedDate = joinedTimestamp.dateValue()
                
                // Enter the dispatch group before fetching user data
                dispatchGroup.enter()
                
                // Get user details from users collection
                self.db.collection("users").document(userId).getDocument { (userDoc, userError) in
                    defer { dispatchGroup.leave() } // Always leave the group
                    
                    if let userError = userError {
                        print("Error fetching user details: \(userError.localizedDescription)")
                        return
                    }
                    
                    if let userData = userDoc?.data() {
                        let name = userData["displayName"] as? String ?? "Unknown User"
                        let profileImageURL = userData["profileImageURL"] as? String
                        
                        // Create member and add to our temporary array
                        let member = EventGroup.Member(
                            userId: userId,
                            name: name,
                            role: role,
                            joinedAt: joinedDate,
                            canChat: canChat,
                            profileImageURL: profileImageURL
                        )
                        loadedMembers.append(member)
                    }
                }
            }
            
            // When all users have been fetched
            dispatchGroup.notify(queue: .main) {
                // Sort members: organizers first, then alphabetically by name
                self.members = loadedMembers.sorted { (member1, member2) in
                    if member1.role == "organizer" && member2.role != "organizer" {
                        return true
                    } else if member1.role != "organizer" && member2.role == "organizer" {
                        return false
                    } else {
                        return member1.name < member2.name
                    }
                }
                
                // Check if current user is organizer
                if let currentMember = self.members.first(where: { $0.userId == self.currentUserID }),
                   currentMember.role == "organizer" {
                    self.isCurrentUserOrganizer = true
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }
                
                self.updateMembersCount()
                self.tableView.reloadData()
            }
        }
    }
    
    private func updateMembersCount() {
        let memberCount = members.count
        let organizerCount = members.filter { $0.role == "organizer" }.count
        detailsLabel.text = "\(memberCount) Participant\(memberCount != 1 ? "s" : "") • \(organizerCount) Organizer\(organizerCount != 1 ? "s" : "")"
    }
    
    // MARK: - Actions
    @objc private func addMemberTapped() {
        // Only organizers can add members
        guard isCurrentUserOrganizer else { return }
        
        // Show add member dialog or go to friend selection screen
        let alert = UIAlertController(title: "Add Participant", message: "Invite someone to this event", preferredStyle: .actionSheet)
        
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
    
    private func showMemberOptions(for member: EventGroup.Member) {
        // Only organizers can manage members, and they can't modify their own status
        guard isCurrentUserOrganizer, member.userId != currentUserID else {
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
        alert.addAction(UIAlertAction(title: "Remove from Event", style: .destructive) { [weak self] _ in
            self?.removeMember(member)
        })
        
        // Make organizer (if member is not already an organizer)
        if member.role != "organizer" {
            alert.addAction(UIAlertAction(title: "Make Organizer", style: .default) { [weak self] _ in
                self?.makeOrganizer(member)
            })
        }
        
        // View profile
        alert.addAction(UIAlertAction(title: "View Profile", style: .default) { [weak self] _ in
            self?.showProfileForMember(member)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func toggleMemberChatPermission(for member: EventGroup.Member) {
        let newChatStatus = !member.canChat
        
        // Update the member's chat permission in Firestore
        db.collection("eventGroups").document(eventId)
            .collection("members").document(member.userId)
            .updateData(["canChat": newChatStatus]) { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error updating chat permission: \(error.localizedDescription)")
                    self.showAlert(title: "Error", message: "Failed to update chat permission. Please try again.")
                    return
                }
                
                self.showAlert(
                    title: "Permission Updated",
                    message: "\(member.name) can \(newChatStatus ? "now" : "no longer") send messages"
                )
                self.loadMembers() // Refresh the list
            }
    }
    
    private func removeMember(_ member: EventGroup.Member) {
        let confirmAlert = UIAlertController(
            title: "Remove Participant",
            message: "Are you sure you want to remove \(member.name) from this event?",
            preferredStyle: .alert
        )
        
        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        confirmAlert.addAction(UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            // Remove the member from Firestore
            self.db.collection("eventGroups").document(self.eventId)
                .collection("members").document(member.userId)
                .delete { error in
                    if let error = error {
                        print("Error removing member: \(error.localizedDescription)")
                        self.showAlert(title: "Error", message: "Failed to remove participant. Please try again.")
                        return
                    }
                    
                    // Also remove from user's events collection
                    self.db.collection("users").document(member.userId)
                        .collection("events").document(self.eventId)
                        .delete { _ in
                            // Load members again regardless of the outcome of the second deletion
                            self.loadMembers()
                        }
                }
        })
        
        present(confirmAlert, animated: true)
    }
    
    private func makeOrganizer(_ member: EventGroup.Member) {
        let confirmAlert = UIAlertController(
            title: "Make Organizer",
            message: "Are you sure you want to make \(member.name) an organizer? They will have full control over the event.",
            preferredStyle: .alert
        )
        
        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        confirmAlert.addAction(UIAlertAction(title: "Make Organizer", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            // Update the user's role in Firestore
            self.db.collection("eventGroups").document(self.eventId)
                .collection("members").document(member.userId)
                .updateData(["role": "organizer"]) { error in
                    if let error = error {
                        print("Error making member an organizer: \(error.localizedDescription)")
                        self.showAlert(title: "Error", message: "Failed to update participant role. Please try again.")
                    } else {
                        self.showAlert(title: "Role Updated", message: "\(member.name) is now an organizer.")
                        self.loadMembers() // Refresh the list
                    }
                }
        })
        
        present(confirmAlert, animated: true)
    }
    
    private func showProfileForMember(_ member: EventGroup.Member) {
        let userProfileVC = UserProfileViewerController(userId: member.userId)
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
}

// MARK: - UITableViewDataSource
extension EventGroupMemberVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return members.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventMemberCell", for: indexPath) as! EventMemberCell
        let member = members[indexPath.row]
        
        // Configure the cell with EventGroup.Member
        cell.configure(with: member, viewedByOrganizer: isCurrentUserOrganizer)
        
        // Highlight current user with a subtle indicator
        if member.userId == currentUserID {
            cell.contentView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        } else {
            cell.contentView.backgroundColor = .systemBackground
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension EventGroupMemberVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedMember = members[indexPath.row]
        
        if isCurrentUserOrganizer && selectedMember.userId != currentUserID {
            showMemberOptions(for: selectedMember)
        } else {
            showProfileForMember(selectedMember)
        }
    }
    
    // Add footer to create space at the bottom
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView() // Empty view for spacing
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20
    }
}

// MARK: - Event Member Cell
class EventMemberCell: UITableViewCell {
    
    // MARK: - Properties
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let roleLabel = UILabel()
    private let joinedDateLabel = UILabel()
    private let chatStatusLabel = UILabel()
    private let chatStatusIndicator = UIView()
    
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
        selectionStyle = .default
        
        // Profile image setup
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 25
        profileImageView.backgroundColor = .systemGray6
        profileImageView.tintColor = .systemGray3
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileImageView)
        
        // Name label setup
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        
        // Role label setup
        roleLabel.font = UIFont.systemFont(ofSize: 14)
        roleLabel.textColor = .secondaryLabel
        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(roleLabel)
        
        // Joined date label
        joinedDateLabel.font = UIFont.systemFont(ofSize: 12)
        joinedDateLabel.textColor = .tertiaryLabel
        joinedDateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(joinedDateLabel)
        
        // Chat status indicator
        chatStatusIndicator.layer.cornerRadius = 4
        chatStatusIndicator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(chatStatusIndicator)
        
        // Chat status label
        chatStatusLabel.font = UIFont.systemFont(ofSize: 12)
        chatStatusLabel.textColor = .secondaryLabel
        chatStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(chatStatusLabel)
        
        // Add constraints
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 50),
            profileImageView.heightAnchor.constraint(equalToConstant: 50),
            
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -80),
            
            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            roleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            roleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            
            joinedDateLabel.topAnchor.constraint(equalTo: roleLabel.bottomAnchor, constant: 2),
            joinedDateLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            joinedDateLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8),
            
            chatStatusIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chatStatusIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chatStatusIndicator.widthAnchor.constraint(equalToConstant: 8),
            chatStatusIndicator.heightAnchor.constraint(equalToConstant: 8),
            
            chatStatusLabel.trailingAnchor.constraint(equalTo: chatStatusIndicator.leadingAnchor, constant: -4),
            chatStatusLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }
    
    // MARK: - Configuration
    func configure(with member: EventGroup.Member, viewedByOrganizer: Bool) {
        nameLabel.text = member.name
        
        // Set role text and styling
        if member.role == "organizer" {
            roleLabel.text = "Organizer"
            roleLabel.textColor = .systemBlue
            roleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        } else {
            roleLabel.text = "Participant"
            roleLabel.textColor = .secondaryLabel
            roleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        }
        
        // Set joined date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        joinedDateLabel.text = "Joined: \(dateFormatter.string(from: member.joinedAt))"
        
        // Set chat status
        if member.canChat {
            chatStatusLabel.text = "Can chat"
            chatStatusIndicator.backgroundColor = .systemGreen
        } else {
            chatStatusLabel.text = "Can't chat"
            chatStatusIndicator.backgroundColor = .systemRed
        }
        
        // Only show chat status for organizers
        chatStatusLabel.isHidden = !viewedByOrganizer
        chatStatusIndicator.isHidden = !viewedByOrganizer
        
        // Load profile image if available
        if let imageURL = member.profileImageURL, let url = URL(string: imageURL) {
            profileImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "person.circle.fill"),
                options: [.transition(.fade(0.3))]
            )
        } else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        nameLabel.text = nil
        roleLabel.text = nil
        joinedDateLabel.text = nil
        chatStatusLabel.text = nil
    }
}

