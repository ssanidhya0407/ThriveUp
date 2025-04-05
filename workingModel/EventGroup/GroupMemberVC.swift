//
//  GroupMemberVC.swift
//  ThriveUp
//
//  Created by Sanidhya's MacBook Pro on 05/04/25.
//


import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class GroupMemberVC: UIViewController {
    
    // MARK: - Properties
    private let eventId: String
    private let tableView = UITableView()
    private var members: [EventGroupMember] = []
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
    init(eventId: String) {
        self.eventId = eventId
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
        title = "Event Details"
        
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
        
        // Configure event image view
        eventImageView.contentMode = .scaleAspectFill
        eventImageView.clipsToBounds = true
        eventImageView.layer.cornerRadius = 60
        eventImageView.backgroundColor = .systemGray6
        eventImageView.image = UIImage(systemName: "calendar")
        eventImageView.tintColor = .systemGray3
        eventImageView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(eventImageView)
        
        // Configure event name label
        eventNameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        eventNameLabel.textAlignment = .center
        eventNameLabel.numberOfLines = 0
        eventNameLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(eventNameLabel)
        
        // Configure details label
        detailsLabel.text = "Event Details"
        detailsLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        detailsLabel.textColor = .secondaryLabel
        detailsLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(detailsLabel)
        
        // Configure divider line
        dividerLine.backgroundColor = .systemGray5
        dividerLine.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(dividerLine)
        
        // Set header view constraints
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Image view in the center
            eventImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            eventImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            eventImageView.widthAnchor.constraint(equalToConstant: 120),
            eventImageView.heightAnchor.constraint(equalToConstant: 120),
            
            // Event name below image
            eventNameLabel.topAnchor.constraint(equalTo: eventImageView.bottomAnchor, constant: 16),
            eventNameLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            eventNameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            
            // Details label below event name
            detailsLabel.topAnchor.constraint(equalTo: eventNameLabel.bottomAnchor, constant: 24),
            detailsLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            
            // Divider line below details label
            dividerLine.topAnchor.constraint(equalTo: detailsLabel.bottomAnchor, constant: 8),
            dividerLine.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            dividerLine.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            dividerLine.heightAnchor.constraint(equalToConstant: 1),
            dividerLine.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -10)
        ])
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MemberCell.self, forCellReuseIdentifier: "MemberCell")
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
        db.collection("events").document(eventId).getDocument { [weak self] snapshot, error in
            guard let self = self, let data = snapshot?.data() else {
                print("Failed to load event details")
                return
            }
            
            // Set event name
            if let name = data["name"] as? String {
                self.eventNameLabel.text = name
            }
            
            // Load event image if available
            if let imageURL = data["imageURL"] as? String, let url = URL(string: imageURL) {
                URLSession.shared.dataTask(with: url) { data, _, error in
                    if let error = error {
                        print("Error loading event image: \(error.localizedDescription)")
                        return
                    }
                    
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.eventImageView.image = image
                            self.eventImageView.tintColor = .clear
                        }
                    }
                }.resume()
            }
        }
    }
    
    private func loadMembers() {
        db.collection("eventGroups").document(eventId)
            .collection("members")
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self, let documents = snapshot?.documents else {
                    print("Error fetching members: \(error?.localizedDescription ?? "unknown error")")
                    return
                }
                
                self.members = documents.compactMap { document -> EventGroupMember? in
                    let userId = document.documentID
                    guard let role = document.data()["role"] as? String,
                          let name = document.data()["name"] as? String else {
                        return nil
                    }
                    
                    // Check if current user is organizer
                    if userId == self.currentUserID && role == "organizer" {
                        self.isCurrentUserOrganizer = true
                        DispatchQueue.main.async {
                            self.navigationItem.rightBarButtonItem?.isEnabled = true
                        }
                    }
                    
                    return EventGroupMember(
                        userId: userId,
                        name: name,
                        role: role,
                        joinedAt: (document.data()["joinedAt"] as? Timestamp)?.dateValue() ?? Date(),
                        canChat: document.data()["canChat"] as? Bool ?? false,
                        profileImageURL: document.data()["profileImageURL"] as? String
                    )
                }
                
                // Sort members: organizers first, then alphabetically by name
                self.members.sort { (member1, member2) in
                    if member1.role == "organizer" && member2.role != "organizer" {
                        return true
                    } else if member1.role != "organizer" && member2.role == "organizer" {
                        return false
                    } else {
                        return member1.name < member2.name
                    }
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }
    
    // MARK: - Actions
    @objc private func addMemberTapped() {
        // Only organizers can add members
        guard isCurrentUserOrganizer else { return }
        
        // Show add member dialog or go to friend selection screen
        let alert = UIAlertController(title: "Add Member", message: "Invite a friend to this event", preferredStyle: .actionSheet)
        
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
    
    private func showMemberOptions(for member: EventGroupMember) {
        // Only organizers can manage members, and they can't modify their own status
        guard isCurrentUserOrganizer, member.userId != currentUserID else { return }
        
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
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func toggleMemberChatPermission(for member: EventGroupMember) {
        let newChatStatus = !member.canChat
        
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
    
    private func removeMember(_ member: EventGroupMember) {
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
                .delete() { error in
                    if let error = error {
                        print("Error removing member: \(error.localizedDescription)")
                        self.showAlert(title: "Error", message: "Failed to remove member. Please try again.")
                        return
                    }
                    
                    if let index = self.members.firstIndex(where: { $0.userId == member.userId }) {
                        self.members.remove(at: index)
                        DispatchQueue.main.async {
                            self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                        }
                    }
                }
        })
        
        present(confirmAlert, animated: true)
    }
    
    private func makeOrganizer(_ member: EventGroupMember) {
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
    
    private func showProfileForMember(_ member: EventGroupMember) {
        // You can implement profile viewer here or call existing functionality
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
extension GroupMemberVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return members.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MemberCell", for: indexPath) as! MemberCell
        let member = members[indexPath.row]
        
        // Configure the cell with member data
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
extension GroupMemberVC: UITableViewDelegate {
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