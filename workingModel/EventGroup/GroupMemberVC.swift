import UIKit
import FirebaseFirestore
import FirebaseAuth
import Kingfisher

class EventGroupMemberVC: UIViewController {
    
    // MARK: - Properties
    private let eventId: String
    private let eventName: String
    private let tableView = UITableView()
    private var organizers: [EventGroup.Member] = []  // New array for organizers
    private var participants: [EventGroup.Member] = [] // New array for regular participants
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
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "SectionHeader")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.rowHeight = 70
        tableView.backgroundColor = .systemBackground
        tableView.sectionHeaderTopPadding = 0
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
        self.organizers = []
        self.participants = []
        
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
            
            // Temporary arrays to hold members while we load them
            var loadedOrganizers: [EventGroup.Member] = []
            var loadedParticipants: [EventGroup.Member] = []
            
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
                        let name = userData["name"] as? String ?? "Unknown User"
                        let profileImageURL = userData["profileImageURL"] as? String
                        
                        // Create member
                        let member = EventGroup.Member(
                            userId: userId,
                            name: name,
                            role: role,
                            joinedAt: joinedDate,
                            canChat: canChat,
                            profileImageURL: profileImageURL
                        )
                        
                        // Sort into appropriate array
                        if role == "organizer" {
                            loadedOrganizers.append(member)
                        } else {
                            loadedParticipants.append(member)
                        }
                    }
                }
            }
            
            // When all users have been fetched
            dispatchGroup.notify(queue: .main) {
                // Sort each array alphabetically by name
                self.organizers = loadedOrganizers.sorted { $0.name < $1.name }
                self.participants = loadedParticipants.sorted { $0.name < $1.name }
                
                // Check if current user is organizer
                if let currentMember = (loadedOrganizers + loadedParticipants).first(where: { $0.userId == self.currentUserID }),
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
        let participantCount = participants.count
        let organizerCount = organizers.count
        let totalCount = participantCount + organizerCount
        
        detailsLabel.text = "\(totalCount) Participant\(totalCount != 1 ? "s" : "") • \(organizerCount) Organizer\(organizerCount != 1 ? "s" : "")"
    }
    
    // MARK: - Actions
    @objc private func addMemberTapped() {
        // Only organizers can add members
        guard isCurrentUserOrganizer else { return }
        
        // Show add member dialog or go to friend selection screen
        let alert = UIAlertController(title: "Add Member", message: "Add a participant to this event", preferredStyle: .actionSheet)
        
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
        // Only organizers can manage members, and they can't modify other organizers
        guard isCurrentUserOrganizer,
              (member.role != "organizer" || member.userId == currentUserID) else { return }
        
        let alert = UIAlertController(title: member.name, message: nil, preferredStyle: .actionSheet)
        
        // Toggle chat permission
        let chatActionTitle = member.canChat ? "Disable Chat" : "Enable Chat"
        alert.addAction(UIAlertAction(title: chatActionTitle, style: .default) { [weak self] _ in
            self?.toggleMemberChatPermission(for: member)
        })
        
        // Remove member (but can't remove self if only organizer)
        if member.userId != currentUserID || organizers.count > 1 {
            alert.addAction(UIAlertAction(title: "Remove from Event", style: .destructive) { [weak self] _ in
                self?.removeMember(member)
            })
        }
        
        // Make organizer (if member is not already an organizer)
        if member.role != "organizer" {
            alert.addAction(UIAlertAction(title: "Make Organizer", style: .default) { [weak self] _ in
                self?.makeOrganizer(member)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func toggleMemberChatPermission(for member: EventGroup.Member) {
        let newChatStatus = !member.canChat
        
        db.collection("eventGroups").document(eventId)
            .collection("members").document(member.userId)
            .updateData(["canChat": newChatStatus]) { [weak self] error in
                if let error = error {
                    print("Error updating chat permission: \(error.localizedDescription)")
                    self?.showAlert(title: "Error", message: "Failed to update chat permissions.")
                } else {
                    self?.showAlert(
                        title: "Chat Permission Updated",
                        message: "\(member.name) can \(newChatStatus ? "now" : "no longer") chat in this event."
                    )
                    self?.loadMembers() // Refresh the list
                }
            }
    }
    
    private func removeMember(_ member: EventGroup.Member) {
        let confirmAlert = UIAlertController(
            title: "Remove Member",
            message: "Are you sure you want to remove \(member.name) from this event?",
            preferredStyle: .alert
        )
        
        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        confirmAlert.addAction(UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            self.db.collection("eventGroups").document(self.eventId)
                .collection("members").document(member.userId)
                .delete { error in
                    if let error = error {
                        print("Error removing member: \(error.localizedDescription)")
                        self.showAlert(title: "Error", message: "Failed to remove member.")
                    } else {
                        // Remove from local arrays and update UI
                        if member.role == "organizer" {
                            if let index = self.organizers.firstIndex(where: { $0.userId == member.userId }) {
                                self.organizers.remove(at: index)
                            }
                        } else {
                            if let index = self.participants.firstIndex(where: { $0.userId == member.userId }) {
                                self.participants.remove(at: index)
                            }
                        }
                        
                        self.updateMembersCount()
                        self.tableView.reloadData()
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
                        self.showAlert(title: "Error", message: "Failed to update member role. Please try again.")
                    } else {
                        self.showAlert(title: "Role Updated", message: "\(member.name) is now an organizer.")
                        self.loadMembers() // Refresh the list
                    }
                }
        })
        
        present(confirmAlert, animated: true)
    }
    
    private func showProfile(for member: EventGroup.Member) {
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
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // Section 0: Organizers, Section 1: Participants
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? organizers.count : participants.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventMemberCell", for: indexPath) as! EventMemberCell
        
        // Get the appropriate member based on section
        let member = indexPath.section == 0 ? organizers[indexPath.row] : participants[indexPath.row]
        
        cell.configure(with: member, isOrganizer: member.role == "organizer")
        
        // Highlight current user with a subtle indicator
        if member.userId == currentUserID {
            cell.contentView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.1)
        } else {
            cell.contentView.backgroundColor = .systemBackground
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Organizers" : "Participants"
    }
}

// MARK: - UITableViewDelegate
extension EventGroupMemberVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let member = indexPath.section == 0 ? organizers[indexPath.row] : participants[indexPath.row]
        
        if isCurrentUserOrganizer {
            showMemberOptions(for: member)
        } else {
            showProfile(for: member)
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "SectionHeader")
        
        var config = UIListContentConfiguration.groupedHeader()
        config.text = section == 0 ? "Organizers" : "Participants"
        config.textProperties.font = UIFont.boldSystemFont(ofSize: 16)
        config.textProperties.color = .label
        
        headerView?.contentConfiguration = config
        headerView?.backgroundConfiguration = .listPlainHeaderFooter()
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    // Add footer for spacing
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 0 && organizers.count == 0 {
            let emptyView = UIView()
            let label = UILabel()
            label.text = "No organizers found"
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            emptyView.addSubview(label)
            
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor)
            ])
            
            return emptyView
        } else if section == 1 && participants.count == 0 {
            let emptyView = UIView()
            let label = UILabel()
            label.text = "No participants found"
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            emptyView.addSubview(label)
            
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor)
            ])
            
            return emptyView
        }
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if (section == 0 && organizers.isEmpty) || (section == 1 && participants.isEmpty) {
            return 40
        }
        return 10
    }
}

// MARK: - Additional cell class if needed
class EventMemberCell: UITableViewCell {
    static let identifier = "EventMemberCell"
    
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let roleLabel = UILabel()
    private let chatStatusImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Profile image
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 20
        profileImageView.backgroundColor = .systemGray5
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .systemGray3
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileImageView)
        
        // Name label
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        
        // Role label
        roleLabel.font = UIFont.systemFont(ofSize: 14)
        roleLabel.textColor = .secondaryLabel
        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(roleLabel)
        
        // Chat status image view
        chatStatusImageView.contentMode = .scaleAspectFit
        chatStatusImageView.tintColor = .systemGray
        chatStatusImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(chatStatusImageView)
        
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 40),
            profileImageView.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: chatStatusImageView.leadingAnchor, constant: -8),
            
            roleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            roleLabel.trailingAnchor.constraint(lessThanOrEqualTo: chatStatusImageView.leadingAnchor, constant: -8),
            
            chatStatusImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chatStatusImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chatStatusImageView.widthAnchor.constraint(equalToConstant: 24),
            chatStatusImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    func configure(with member: EventGroup.Member, isOrganizer: Bool = false) {
        nameLabel.text = member.name
        
        // Set role text
        if isOrganizer {
            roleLabel.text = "Organizer"
            roleLabel.textColor = .systemOrange
        } else {
            roleLabel.text = "Participant"
            roleLabel.textColor = .secondaryLabel
        }
        
        // Set chat status icon
        if member.canChat {
            chatStatusImageView.image = UIImage(systemName: "message")
            chatStatusImageView.tintColor = .systemGreen
        } else {
            chatStatusImageView.image = UIImage(systemName: "message.slash")
            chatStatusImageView.tintColor = .systemRed
        }
        
        // Load profile image if available
        if let imageURL = member.profileImageURL, let url = URL(string: imageURL) {
            profileImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "person.circle.fill"),
                options: [.transition(.fade(0.3))]
            )
        } else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
            profileImageView.tintColor = .systemGray3
        }
    }
}
