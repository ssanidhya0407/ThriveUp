import UIKit
import FirebaseFirestore
import FirebaseAuth
import Kingfisher

class UserGroupMemberVC: UIViewController {
    
    // MARK: - Properties
    private let groupId: String
    private let groupName: String
    private let tableView = UITableView()
    private var members: [UserGroup.Member] = [] // Updated to use namespaced type
    private let currentUserID = Auth.auth().currentUser?.uid ?? ""
    private var isCurrentUserAdmin = false
    private let db = Firestore.firestore()
    private let userGroupManager = UserGroupManager()
    
    // UI Components
    private let headerView = UIView()
    private let groupImageView = UIImageView()
    private let groupNameLabel = UILabel()
    private let detailsLabel = UILabel()
    private let dividerLine = UIView()
    
    // MARK: - Initialization
    init(groupId: String, groupName: String) {
        self.groupId = groupId
        self.groupName = groupName
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadGroupDetails()
        loadMembers()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Group Details"
        
        // Configure header view
        setupHeaderView()
        
        // Setup table view
        setupTableView()
        
        // Setup add member button (will be visible only for admins)
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addMemberTapped))
        navigationItem.rightBarButtonItem = addButton
        addButton.isEnabled = false // Will be enabled when we confirm user is admin
    }
    
    private func setupHeaderView() {
        headerView.backgroundColor = .systemBackground
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        
        // Group image
        groupImageView.contentMode = .scaleAspectFill
        groupImageView.clipsToBounds = true
        groupImageView.layer.cornerRadius = 40
        groupImageView.backgroundColor = .systemGray6
        groupImageView.image = UIImage(systemName: "person.3")
        groupImageView.tintColor = .systemGray3
        groupImageView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(groupImageView)
        
        // Group name label
        groupNameLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        groupNameLabel.text = groupName
        groupNameLabel.textAlignment = .center
        groupNameLabel.numberOfLines = 2
        groupNameLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(groupNameLabel)
        
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
            
            groupImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            groupImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            groupImageView.widthAnchor.constraint(equalToConstant: 80),
            groupImageView.heightAnchor.constraint(equalToConstant: 80),
            
            groupNameLabel.topAnchor.constraint(equalTo: groupImageView.bottomAnchor, constant: 12),
            groupNameLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            groupNameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            detailsLabel.topAnchor.constraint(equalTo: groupNameLabel.bottomAnchor, constant: 4),
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
        tableView.register(GroupMemberCell.self, forCellReuseIdentifier: "GroupMemberCell")
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
    private func loadGroupDetails() {
        db.collection("groups").document(groupId).getDocument { [weak self] (snapshot, error) in
            guard let self = self, let data = snapshot?.data() else {
                print("Error fetching group details: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            // Update UI with group details
            DispatchQueue.main.async {
                if let name = data["name"] as? String {
                    self.groupNameLabel.text = name
                    self.title = name
                }
                
                // Load group image if available
                if let imageURL = data["imageURL"] as? String, let url = URL(string: imageURL) {
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
            
            self.members = members
            
            // Check if current user is admin
            if let currentMember = members.first(where: { $0.userId == self.currentUserID }),
               currentMember.role == "admin" {
                self.isCurrentUserAdmin = true
                DispatchQueue.main.async {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }
            }
            
            // Sort members: admins first, then alphabetically by name
            self.members.sort { (member1, member2) in
                if member1.role == "admin" && member2.role != "admin" {
                    return true
                } else if member1.role != "admin" && member2.role == "admin" {
                    return false
                } else {
                    return member1.name < member2.name
                }
            }
            
            DispatchQueue.main.async {
                self.updateMembersCount()
                self.tableView.reloadData()
            }
        }
    }
    
    private func updateMembersCount() {
        let adminCount = members.filter { $0.role == "admin" }.count
        detailsLabel.text = "\(members.count) Members • \(adminCount) Admin\(adminCount != 1 ? "s" : "")"
    }
    
    // MARK: - Actions
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
    
    private func showMemberOptions(for member: UserGroup.Member) {
        // Only admins can manage members, and they can't modify their own status
        guard isCurrentUserAdmin, member.userId != currentUserID else { return }
        
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
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func toggleMemberChatPermission(for member: UserGroup.Member) {
        let newChatStatus = !member.canChat
        
        userGroupManager.updateMemberChatPermission(groupId: groupId, userId: member.userId, canChat: newChatStatus) { [weak self] success in
            guard let self = self else { return }
            
            if !success {
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
                
                if let index = self.members.firstIndex(where: { $0.userId == member.userId }) {
                    self.members.remove(at: index)
                    DispatchQueue.main.async {
                        self.updateMembersCount()
                        self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                    }
                }
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
        // Use the renamed profile viewer
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
}

// MARK: - UITableViewDataSource
extension UserGroupMemberVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return members.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupMemberCell", for: indexPath) as! GroupMemberCell
        let member = members[indexPath.row]
        
        // Configure the cell with UserGroup.Member directly
        cell.configure(with: member, viewedByOrganizer: isCurrentUserAdmin)
        
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
extension UserGroupMemberVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedMember = members[indexPath.row]
        
        if isCurrentUserAdmin && selectedMember.userId != currentUserID {
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
