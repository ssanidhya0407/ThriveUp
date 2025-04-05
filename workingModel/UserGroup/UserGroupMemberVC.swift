import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class UserGroupMemberVC: UIViewController {
    
    // MARK: - Properties
    private let groupId: String
    private let tableView = UITableView()
    private let groupManager = GroupManager()
    private var members: [GroupMember] = []
    private let currentUserID = Auth.auth().currentUser?.uid ?? ""
    private var isCurrentUserAdmin = false
    private let db = Firestore.firestore()
    
    // UI Components
    private let headerView = UIView()
    private let groupImageView = UIImageView()
    private let groupNameLabel = UILabel()
    private let membersLabel = UILabel()
    private let dividerLine = UIView()
    
    // MARK: - Initialization
    init(groupId: String) {
        self.groupId = groupId
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
        
        // Configure group image view
        groupImageView.contentMode = .scaleAspectFill
        groupImageView.clipsToBounds = true
        groupImageView.layer.cornerRadius = 60
        groupImageView.backgroundColor = .systemGray5
        groupImageView.image = UIImage(systemName: "person.3.fill")
        groupImageView.tintColor = .systemGray
        groupImageView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(groupImageView)
        
        // Configure group name label
        groupNameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        groupNameLabel.textAlignment = .center
        groupNameLabel.numberOfLines = 0
        groupNameLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(groupNameLabel)
        
        // Configure members label
        membersLabel.text = "MEMBERS"
        membersLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        membersLabel.textColor = .systemGray
        membersLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(membersLabel)
        
        // Configure divider line
        dividerLine.backgroundColor = .systemGray4
        dividerLine.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(dividerLine)
        
        // Set header view constraints
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Image view in the center
            groupImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            groupImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            groupImageView.widthAnchor.constraint(equalToConstant: 120),
            groupImageView.heightAnchor.constraint(equalToConstant: 120),
            
            // Group name below image
            groupNameLabel.topAnchor.constraint(equalTo: groupImageView.bottomAnchor, constant: 16),
            groupNameLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            groupNameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            
            // Members label below group name
            membersLabel.topAnchor.constraint(equalTo: groupNameLabel.bottomAnchor, constant: 24),
            membersLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            
            // Divider line below members label
            dividerLine.topAnchor.constraint(equalTo: membersLabel.bottomAnchor, constant: 8),
            dividerLine.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            dividerLine.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            dividerLine.heightAnchor.constraint(equalToConstant: 1),
            dividerLine.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -10)
        ])
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UserMemberCell.self, forCellReuseIdentifier: UserMemberCell.identifier)
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
        db.collection("groups").document(groupId).getDocument { [weak self] snapshot, error in
            guard let self = self, let data = snapshot?.data() else {
                print("Failed to load group details")
                return
            }
            
            // Set group name
            if let name = data["name"] as? String {
                self.groupNameLabel.text = name
            }
            
            // Load group image if available
            if let imageURL = data["imageURL"] as? String, let url = URL(string: imageURL) {
                URLSession.shared.dataTask(with: url) { data, _, error in
                    if let error = error {
                        print("Error loading group image: \(error.localizedDescription)")
                        return
                    }
                    
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.groupImageView.image = image
                            self.groupImageView.tintColor = .clear // Hide the tint color when image is loaded
                        }
                    }
                }.resume()
            }
        }
    }
    
    private func loadMembers() {
        groupManager.getGroupMembers(groupId: groupId) { [weak self] members in
            guard let self = self else { return }
            
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
            
            // Check if current user is admin
            if let currentMember = members.first(where: { $0.userId == self.currentUserID }) {
                self.isCurrentUserAdmin = currentMember.role == "admin"
                
                DispatchQueue.main.async {
                    self.navigationItem.rightBarButtonItem?.isEnabled = self.isCurrentUserAdmin
                    self.updateMembersLabel()
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    private func updateMembersLabel() {
        let adminCount = members.filter { $0.role == "admin" }.count
        let totalCount = members.count
        membersLabel.text = "MEMBERS (\(totalCount)) • ADMINS (\(adminCount))"
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
        // For simplicity, let's show a mock implementation
        showAlert(title: "Feature Coming Soon", message: "Friend selection will be implemented in a future update.")
    }
    
    private func showMemberOptions(for member: GroupMember) {
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
    
    private func toggleMemberChatPermission(for member: GroupMember) {
        let newChatStatus = !member.canChat
        
        groupManager.updateMemberChatPermission(groupId: groupId, userId: member.userId, canChat: newChatStatus) { [weak self] success in
            guard let self = self else { return }
            
            if success {
                self.showAlert(
                    title: "Permission Updated",
                    message: "\(member.name) can \(newChatStatus ? "now" : "no longer") send messages"
                )
                self.loadMembers() // Refresh the list
            } else {
                self.showAlert(
                    title: "Error",
                    message: "Failed to update chat permission. Please try again."
                )
            }
        }
    }
    
    private func removeMember(_ member: GroupMember) {
        let confirmAlert = UIAlertController(
            title: "Remove Member",
            message: "Are you sure you want to remove \(member.name) from this group?",
            preferredStyle: .alert
        )
        
        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        confirmAlert.addAction(UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            self.groupManager.removeUserFromGroup(groupId: self.groupId, userId: member.userId) { success in
                if success {
                    DispatchQueue.main.async {
                        if let index = self.members.firstIndex(where: { $0.userId == member.userId }) {
                            self.members.remove(at: index)
                            self.updateMembersLabel()
                            self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                        }
                    }
                } else {
                    self.showAlert(title: "Error", message: "Failed to remove member. Please try again.")
                }
            }
        })
        
        present(confirmAlert, animated: true)
    }
    
    private func makeAdmin(_ member: GroupMember) {
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UserMemberCell.identifier, for: indexPath) as? UserMemberCell else {
            return UITableViewCell()
        }
        
        let member = members[indexPath.row]
        
        // Configure the cell with member data
        cell.configure(with: member)
        
        // Add styling for admins
        if member.role == "admin" {
            cell.backgroundColor = UIColor.systemGray6
        } else {
            cell.backgroundColor = .black
        }
        
        // Highlight current user
        if member.userId == currentUserID {
            cell.contentView.layer.borderColor = UIColor.systemBlue.cgColor
            cell.contentView.layer.borderWidth = 1
            cell.contentView.layer.cornerRadius = 8
        } else {
            cell.contentView.layer.borderWidth = 0
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
