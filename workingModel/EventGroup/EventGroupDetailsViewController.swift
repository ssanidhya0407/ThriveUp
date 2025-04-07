//
//  EventGroupDetailsViewController.swift
//  ThriveUp
//
//  Created by Sanidhya's MacBook Pro on 06/04/25.
//

//
//  EventGroupDetailsViewController.swift
//  ThriveUp
//
//  Created by Sanidhya's MacBook Pro on 06/04/25.
//


import UIKit
import FirebaseFirestore
import FirebaseAuth
import Kingfisher

class EventGroupDetailsViewController: UIViewController {
    
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
    private let membersSectionLabel = UILabel()
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
        title = "Event Details"
        
        // Configure header view
        setupHeaderView()
        
        // Setup table view
        setupTableView()
        
        // Setup navigation bar buttons
        setupNavigationButtons()
    }
    
    private func setupNavigationButtons() {
        let chatButton = UIBarButtonItem(image: UIImage(systemName: "message.fill"), style: .plain, target: self, action: #selector(chatTapped))
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addMemberTapped))
//        navigationItem.rightBarButtonItems = [addButton, chatButton]
        
        // Initially disable the add button until we confirm user is organizer
        addButton.isEnabled = false
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
        eventNameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        eventNameLabel.text = eventName
        eventNameLabel.textAlignment = .center
        eventNameLabel.numberOfLines = 2
        eventNameLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(eventNameLabel)
        
        // Details label (date, location, etc.)
        detailsLabel.font = UIFont.systemFont(ofSize: 14)
        detailsLabel.textColor = .secondaryLabel
        detailsLabel.textAlignment = .center
        detailsLabel.numberOfLines = 2
        detailsLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(detailsLabel)
        
        // Members section label
        membersSectionLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        membersSectionLabel.text = "Participants"
        membersSectionLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(membersSectionLabel)
        
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
            eventNameLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            eventNameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            
            detailsLabel.topAnchor.constraint(equalTo: eventNameLabel.bottomAnchor, constant: 8),
            detailsLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            detailsLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            
            membersSectionLabel.topAnchor.constraint(equalTo: detailsLabel.bottomAnchor, constant: 20),
            membersSectionLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            
            dividerLine.topAnchor.constraint(equalTo: membersSectionLabel.bottomAnchor, constant: 8),
            dividerLine.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            dividerLine.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            dividerLine.heightAnchor.constraint(equalToConstant: 0.5),
            dividerLine.bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
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
        db.collection("eventGroups").document(eventId).getDocument { [weak self] (snapshot, error) in
            guard let self = self, let data = snapshot?.data() else {
                print("Error fetching event details: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                // Update event name
                if let name = data["name"] as? String {
                    self.eventNameLabel.text = name
                    self.title = name
                }
                
                // Update event details (date, location)
                var detailsText = ""
                
                if let dateTimestamp = data["date"] as? Timestamp {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    dateFormatter.timeStyle = .short
                    detailsText += dateFormatter.string(from: dateTimestamp.dateValue())
                }
                
                if let location = data["location"] as? String, !location.isEmpty {
                    if !detailsText.isEmpty {
                        detailsText += " • "
                    }
                    detailsText += location
                }
                
                self.detailsLabel.text = detailsText
                
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
        eventGroupManager.getEventMembers(eventId: eventId) { [weak self] members in
            guard let self = self else { return }
            
            // Sort members: organizers first, then alphabetically by name
            self.members = members.sorted { (member1, member2) in
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
                self.navigationItem.rightBarButtonItems?[0].isEnabled = true
            }
            
            self.updateMembersCount()
            self.tableView.reloadData()
        }
    }
    
    private func updateMembersCount() {
        let memberCount = members.count
        let organizerCount = members.filter { $0.role == "organizer" }.count
        membersSectionLabel.text = "Participants (\(memberCount))"
    }
    
    // MARK: - Actions
    @objc private func chatTapped() {
        // Navigate to event chat
        let chatVC = EventGroupViewController(eventId: eventId, eventName: eventNameLabel.text ?? "Event")
        navigationController?.pushViewController(chatVC, animated: true)
    }
    
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
extension EventGroupDetailsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return members.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MemberCell", for: indexPath) as! MemberCell
        let member = members[indexPath.row]
        
        // Configure the cell with member
        cell.configure(with: member, viewedByOrganizer: isCurrentUserOrganizer)
        
        // Highlight current user with a subtle indicator
        if member.userId == currentUserID {
            cell.contentView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.1)
        } else {
            cell.contentView.backgroundColor = .systemBackground
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension EventGroupDetailsViewController: UITableViewDelegate {
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
