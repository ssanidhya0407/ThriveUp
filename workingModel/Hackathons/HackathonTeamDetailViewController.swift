import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import SDWebImage // We'll use this library for image loading

class HackathonTeamDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var team: HackathonTeam
    private var event: EventModel
    private var userId: String?
    private var isTeamLead: Bool = false
    private var pendingRequests: [TeamJoinRequest] = []
    private var memberProfiles: [String: UserProfile] = [:] // Cache for user profiles
    
    private let headerView = UIView()
    private let teamNameLabel = UILabel()
    private let eventNameLabel = UILabel()
    private let membersTableView = UITableView(frame: .zero, style: .plain)
    private let requestsTableView = UITableView(frame: .zero, style: .plain)
    private let requestsHeaderLabel = UILabel()
    
    // MARK: - Initializer
    init(team: HackathonTeam, event: EventModel) {
        self.team = team
        self.event = event
        super.init(nibName: nil, bundle: nil)
        
        // Get current user ID if available
        if let currentUser = Auth.auth().currentUser {
            self.userId = currentUser.uid
            self.isTeamLead = team.teamLeadId == currentUser.uid
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Fetch member profiles first
        fetchMemberProfiles {
            self.membersTableView.reloadData()
        }
        
        if isTeamLead {
            fetchPendingRequests()
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // (existing UI setup code remains the same)
        view.backgroundColor = .white
        title = "Team Details"
        
        // Setup Header View
        headerView.backgroundColor = UIColor(red: 1.0, green: 0.95, blue: 0.9, alpha: 1.0)
        view.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Team Name Label
        teamNameLabel.text = team.name
        teamNameLabel.font = UIFont.boldSystemFont(ofSize: 24)
        teamNameLabel.textAlignment = .center
        headerView.addSubview(teamNameLabel)
        teamNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Event Name Label
        eventNameLabel.text = "For: \(event.title)"
        eventNameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        eventNameLabel.textColor = .darkGray
        eventNameLabel.textAlignment = .center
        headerView.addSubview(eventNameLabel)
        eventNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Members Label
        let membersLabel = UILabel()
        membersLabel.text = "Team Members"
        membersLabel.font = UIFont.boldSystemFont(ofSize: 18)
        view.addSubview(membersLabel)
        membersLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Members Table View
        membersTableView.register(MemberCell1.self, forCellReuseIdentifier: "MemberCell1")
        membersTableView.delegate = self
        membersTableView.dataSource = self
        membersTableView.rowHeight = 60
        membersTableView.tag = 0 // To differentiate between tables
        membersTableView.separatorStyle = .none
        membersTableView.isScrollEnabled = false
        membersTableView.backgroundColor = .clear
        view.addSubview(membersTableView)
        membersTableView.translatesAutoresizingMaskIntoConstraints = false
        
        // Only show requests section if user is team lead
        if isTeamLead {
            // Requests Header Label
            requestsHeaderLabel.text = "Join Requests"
            requestsHeaderLabel.font = UIFont.boldSystemFont(ofSize: 18)
            view.addSubview(requestsHeaderLabel)
            requestsHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
            
            // Requests Table View
            requestsTableView.register(RequestCell.self, forCellReuseIdentifier: "RequestCell")
            requestsTableView.delegate = self
            requestsTableView.dataSource = self
            requestsTableView.rowHeight = 70
            requestsTableView.tag = 1 // To differentiate between tables
            view.addSubview(requestsTableView)
            requestsTableView.translatesAutoresizingMaskIntoConstraints = false
        }
        
        // Setup Constraints
        var constraints = [
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            teamNameLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            teamNameLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            teamNameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            eventNameLabel.topAnchor.constraint(equalTo: teamNameLabel.bottomAnchor, constant: 8),
            eventNameLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            eventNameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            eventNameLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -20),
            
            membersLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            membersLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            membersLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            membersTableView.topAnchor.constraint(equalTo: membersLabel.bottomAnchor, constant: 8),
            membersTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            membersTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            membersTableView.heightAnchor.constraint(equalToConstant: CGFloat(team.memberIds.count * 60))
        ]
        
        if isTeamLead {
            constraints.append(contentsOf: [
                requestsHeaderLabel.topAnchor.constraint(equalTo: membersTableView.bottomAnchor, constant: 16),
                requestsHeaderLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                requestsHeaderLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                
                requestsTableView.topAnchor.constraint(equalTo: requestsHeaderLabel.bottomAnchor, constant: 8),
                requestsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                requestsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                requestsTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])
        } else {
            constraints.append(
                membersTableView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
            )
        }
        
        NSLayoutConstraint.activate(constraints)
    }
    
    // MARK: - Data Fetching Methods
    
    // New method to fetch member profiles
    private func fetchMemberProfiles(completion: @escaping () -> Void) {
        let dispatchGroup = DispatchGroup()
        
        for memberId in team.memberIds {
            dispatchGroup.enter()
            
            db.collection("users").document(memberId).getDocument { [weak self] snapshot, error in
                defer { dispatchGroup.leave() }
                guard let self = self,
                      let snapshot = snapshot,
                      snapshot.exists,
                      let data = snapshot.data() else {
                    print("Error fetching user profile: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                // Extract user profile data
                let profileImageURL = data["profileImageURL"] as? String
                let name = data["name"] as? String ?? "Unknown"
                
                // Create and store user profile
                let userProfile = UserProfile(
                    id: memberId,
                    name: name,
                    profileImageURL: profileImageURL
                )
                
                self.memberProfiles[memberId] = userProfile
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion()
        }
    }
    
    // MARK: - Table View DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView.tag {
        case 0: // Members table
            return team.memberIds.count
        case 1: // Requests table
            return pendingRequests.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView.tag {
        case 0: // Members table
            let cell = tableView.dequeueReusableCell(withIdentifier: "MemberCell1", for: indexPath) as! MemberCell1
            let memberId = team.memberIds[indexPath.row]
            let memberName = team.memberNames[indexPath.row]
            let isLead = memberId == team.teamLeadId
            
            // Get user profile if available
            let profile = memberProfiles[memberId]
            
            // Configure cell with profile image URL
            cell.configure(name: memberName, isLead: isLead, profileImageURL: profile?.profileImageURL)
            
            return cell
            
        case 1: // Requests table
            let cell = tableView.dequeueReusableCell(withIdentifier: "RequestCell", for: indexPath) as! RequestCell
            let request = pendingRequests[indexPath.row]
            cell.configure(with: request)
            cell.acceptButton.tag = indexPath.row
            cell.rejectButton.tag = indexPath.row
            
            cell.acceptButton.addTarget(self, action: #selector(acceptRequest(_:)), for: .touchUpInside)
            cell.rejectButton.addTarget(self, action: #selector(rejectRequest(_:)), for: .touchUpInside)
            
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    // MARK: - Existing helper methods (fetchPendingRequests, updateRequestStatus, etc.)
    private func fetchPendingRequests() {
        db.collection("teamJoinRequests")
            .whereField("teamId", isEqualTo: team.id)
            .whereField("status", isEqualTo: "pending")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching requests: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                var requests: [TeamJoinRequest] = []
                
                for document in documents {
                    let data = document.data()
                    
                    let request = TeamJoinRequest(
                        id: document.documentID,
                        teamId: data["teamId"] as? String ?? "",
                        senderId: data["senderId"] as? String ?? "",
                        senderName: data["senderName"] as? String ?? "",
                        receiverId: data["receiverId"] as? String ?? "",
                        receiverName: data["receiverName"] as? String ?? "",
                        eventId: data["eventId"] as? String ?? "",
                        status: data["status"] as? String ?? "pending",
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                    
                    requests.append(request)
                }
                
                self.pendingRequests = requests
                
                DispatchQueue.main.async {
                    self.requestsTableView.reloadData()
                }
            }
    }
    
    @objc private func acceptRequest(_ sender: UIButton) {
        let index = sender.tag
        guard index < pendingRequests.count else { return }
        
        let request = pendingRequests[index]
        updateRequestStatus(request, status: "accepted")
    }
    
    @objc private func rejectRequest(_ sender: UIButton) {
        let index = sender.tag
        guard index < pendingRequests.count else { return }
        
        let request = pendingRequests[index]
        updateRequestStatus(request, status: "rejected")
    }
    
    private func updateRequestStatus(_ request: TeamJoinRequest, status: String) {
        let requestRef = db.collection("teamJoinRequests").document(request.id)
        
        // First, update the request status
        requestRef.updateData(["status": status]) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error updating request status: \(error.localizedDescription)")
                return
            }
            
            // If accepted, add user to the team
            if status == "accepted" {
                self.addUserToTeam(userId: request.senderId, userName: request.senderName)
            }
            
            // Send notification to the requester
            self.sendStatusNotification(to: request.senderId, status: status)
            
            // Remove the request from the list
            if let index = self.pendingRequests.firstIndex(where: { $0.id == request.id }) {
                self.pendingRequests.remove(at: index)
                
                DispatchQueue.main.async {
                    self.requestsTableView.reloadData()
                }
            }
        }
    }
    
    private func addUserToTeam(userId: String, userName: String) {
        let teamRef = db.collection("hackathonTeams").document(team.id)
        
        // Update team members arrays with the new user
        teamRef.updateData([
            "memberIds": FieldValue.arrayUnion([userId]),
            "memberNames": FieldValue.arrayUnion([userName])
        ]) { [weak self] error in
            if let error = error {
                print("Error adding user to team: \(error.localizedDescription)")
                return
            }
            
            // Reload the members table
            guard let self = self else { return }
            
            // Update local team data
            var updatedMemberIds = self.team.memberIds
            var updatedMemberNames = self.team.memberNames
            
            updatedMemberIds.append(userId)
            updatedMemberNames.append(userName)
            
            self.team = HackathonTeam(
                id: self.team.id,
                name: self.team.name,
                eventId: self.team.eventId,
                teamLeadId: self.team.teamLeadId,
                teamLeadName: self.team.teamLeadName,
                memberIds: updatedMemberIds,
                memberNames: updatedMemberNames,
                maxMembers: self.team.maxMembers,
                createdAt: self.team.createdAt
            )
            
            // Fetch the new member's profile
            self.db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
                guard let self = self,
                      let snapshot = snapshot,
                      snapshot.exists,
                      let data = snapshot.data() else {
                    return
                }
                
                // Extract user profile data
                let profileImageURL = data["profileImageURL"] as? String
                
                // Create and store user profile
                let userProfile = UserProfile(
                    id: userId,
                    name: userName,
                    profileImageURL: profileImageURL
                )
                
                self.memberProfiles[userId] = userProfile
                
                DispatchQueue.main.async {
                    // Update table view height
                    let heightConstraint = self.membersTableView.constraints.first { $0.firstAttribute == .height }
                    heightConstraint?.constant = CGFloat(self.team.memberIds.count * 60)
                    
                    self.membersTableView.reloadData()
                }
            }
        }
    }
    
    private func sendStatusNotification(to userId: String, status: String) {
        // Create notification message based on status
        let message = status == "accepted" ?
            "Your request to join team \(team.name) has been accepted!" :
            "Your request to join team \(team.name) has been declined."
        
        // Create notification data
        let notificationData: [String: Any] = [
            "title": "Team Join Request Update",
            "message": message,
            "timestamp": FieldValue.serverTimestamp(),
            "isRead": false,
            "senderId": self.userId ?? "",
            "eventId": event.eventId,
            "teamId": team.id
        ]
        
        // Add notification to user's notifications collection
        db.collection("users").document(userId).collection("notifications").addDocument(data: notificationData)
    }
}

// MARK: - User Profile Model
struct UserProfile {
    let id: String
    let name: String
    let profileImageURL: String?
}

// MARK: - Member Cell
class MemberCell1: UITableViewCell {
    
    private let nameLabel = UILabel()
    private let roleLabel = UILabel()
    private let avatarImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        // Avatar Image
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.backgroundColor = .lightGray
        avatarImageView.image = UIImage(systemName: "person.circle")
        avatarImageView.tintColor = .gray
        contentView.addSubview(avatarImageView)
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Name Label
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        contentView.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Role Label
        roleLabel.font = UIFont.systemFont(ofSize: 14)
        roleLabel.textColor = .gray
        contentView.addSubview(roleLabel)
        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            roleLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            roleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            roleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10)
        ])
    }
    
    func configure(name: String, isLead: Bool, profileImageURL: String?) {
        nameLabel.text = name
        roleLabel.text = isLead ? "Team Lead" : "Team Member"
        roleLabel.textColor = isLead ? .orange : .gray
        
        // Reset to default image
        avatarImageView.image = UIImage(systemName: "person.circle")
        avatarImageView.tintColor = .gray
        
        // Load profile image if available
        if let imageURLString = profileImageURL, let imageURL = URL(string: imageURLString) {
            // Using SDWebImage for image loading and caching
            avatarImageView.sd_setImage(with: imageURL, placeholderImage: UIImage(systemName: "person.circle")) { [weak self] (image, error, cacheType, url) in
                if let error = error {
                    print("Error loading profile image: \(error.localizedDescription)")
                    // Keep default image on error
                    self?.avatarImageView.image = UIImage(systemName: "person.circle")
                    self?.avatarImageView.tintColor = .gray
                }
            }
        }
    }
}

// MARK: - Request Cell (unchanged)
class RequestCell: UITableViewCell {
    
    private let nameLabel = UILabel()
    private let dateLabel = UILabel()
    let acceptButton = UIButton(type: .system)
    let rejectButton = UIButton(type: .system)
    private let containerView = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        // Container View
        containerView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
        containerView.layer.cornerRadius = 10
        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Name Label
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        containerView.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Date Label
        dateLabel.font = UIFont.systemFont(ofSize: 12)
        dateLabel.textColor = .gray
        containerView.addSubview(dateLabel)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Accept Button
        acceptButton.setTitle("Accept", for: .normal)
        acceptButton.backgroundColor = .systemGreen
        acceptButton.setTitleColor(.white, for: .normal)
        acceptButton.layer.cornerRadius = 12
        containerView.addSubview(acceptButton)
        acceptButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Reject Button
        rejectButton.setTitle("Reject", for: .normal)
        rejectButton.backgroundColor = .systemRed
        rejectButton.setTitleColor(.white, for: .normal)
        rejectButton.layer.cornerRadius = 12
        containerView.addSubview(rejectButton)
        rejectButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            dateLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            dateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            acceptButton.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8),
            acceptButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            acceptButton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.42),
            acceptButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10),
            acceptButton.heightAnchor.constraint(equalToConstant: 24),
            
            rejectButton.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8),
            rejectButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            rejectButton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.42),
            rejectButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10),
            rejectButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    func configure(with request: TeamJoinRequest) {
        nameLabel.text = "\(request.senderName) wants to join"
        
        // Format the date
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        dateLabel.text = "Requested: \(formatter.string(from: request.createdAt))"
    }
}
