import UIKit
import FirebaseAuth
import FirebaseFirestore

class ChatViewController: UIViewController {
    // MARK: - UI Components
    let tableView = UITableView()
    let chatManager = FirestoreChatManager()
    let searchBar = UISearchBar()
    let titleLabel = UILabel()
    let friendsButton = UIButton(type: .system)
    let titleStackView = UIStackView()
    let friendRequestsButton = UIButton(type: .system)
    let createGroupButton = UIButton(type: .system)
    private let requestBadgeView: UILabel = {
        let label = UILabel()
        label.backgroundColor = .systemRed // Changed to red for better visibility
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textAlignment = .center
        label.layer.cornerRadius = 9 // Slightly smaller than before
        label.clipsToBounds = true
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        // Set a minimum width so single digits look good
        label.widthAnchor.constraint(greaterThanOrEqualToConstant: 18).isActive = true
        label.heightAnchor.constraint(equalToConstant: 18).isActive = true
        return label
    }()
    
    // MARK: - Data Properties
    var friends: [User] = []
    var groups: [Group] = []
    var filteredFriends: [User] = []
    var currentUser: User?
    var lastMessages: [String: ChatMessage] = [:]
    var messageListeners: [String: ListenerRegistration] = [:]
    var eventGroups: [(eventId: String, name: String, lastMessage: String?, timestamp: Date?, imageURL: String?)] = []
    
    private var db = Firestore.firestore()
    
    // MARK: - Empty State View
    private let emptyStateView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView(image: UIImage(systemName: "person.2.slash"))
        imageView.tintColor = .systemGray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "No Chats Yet"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .systemGray
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Add friends or join groups to start chatting"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textColor = .systemGray2
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let addFriendButton = UIButton(type: .system)
        addFriendButton.setTitle("Add Friends", for: .normal)
        addFriendButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        addFriendButton.addTarget(ChatViewController.self, action: #selector(openFriendRequestsViewController), for: .touchUpInside)
        addFriendButton.tintColor = .systemOrange
        addFriendButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(imageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(addFriendButton)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            
            addFriendButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addFriendButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            addFriendButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        return view
    }()

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        fetchCurrentUser()
        setupNotifications()
        updateFriendRequestBadge()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshChatList()
    }
    
    deinit {
        messageListeners.values.forEach { $0.remove() }
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        setupTitleStackView()
        setupSearchBar()
        setupTableView()
        setupCreateGroupButton()
        setupEmptyStateView()
    }
    
    private func setupTitleStackView() {
        titleLabel.text = "Chat"
        titleLabel.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        titleLabel.textAlignment = .left
        
        let friendsIcon = UIImage(systemName: "person.2.fill")
          friendRequestsButton.setImage(friendsIcon, for: .normal)
          friendRequestsButton.tintColor = .systemOrange
          friendRequestsButton.addTarget(self, action: #selector(openFriendRequestsViewController), for: .touchUpInside)
          friendRequestsButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        friendRequestsButton.addSubview(requestBadgeView)
        NSLayoutConstraint.activate([
             requestBadgeView.topAnchor.constraint(equalTo: friendRequestsButton.topAnchor, constant: -6),
             requestBadgeView.trailingAnchor.constraint(equalTo: friendRequestsButton.trailingAnchor, constant: 6)
         ])
          
        
        titleStackView.axis = .horizontal
        titleStackView.alignment = .center
        titleStackView.distribution = .equalSpacing
        titleStackView.spacing = 8
        titleStackView.addArrangedSubview(titleLabel)
        titleStackView.addArrangedSubview(friendRequestsButton)
        
        view.addSubview(titleStackView)
        titleStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            titleStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            titleStackView.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        updateFriendRequestBadge()
    }
    
    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.placeholder = "Search"
        searchBar.barTintColor = .systemGray6
        searchBar.layer.cornerRadius = 12
        searchBar.clipsToBounds = true

        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = .systemGray6
            textField.layer.cornerRadius = 12
            textField.borderStyle = .none
        }

        view.addSubview(searchBar)
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: titleStackView.bottomAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchBar.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ChatCell.self, forCellReuseIdentifier: ChatCell.identifier)
        tableView.separatorStyle = .none
        tableView.rowHeight = 80
        tableView.backgroundColor = .white
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupCreateGroupButton() {
        let createGroupIcon = UIImage(systemName: "plus.bubble.fill")
        createGroupButton.setImage(createGroupIcon, for: .normal)
        createGroupButton.tintColor = .systemOrange
        createGroupButton.addTarget(self, action: #selector(openCreateGroupView), for: .touchUpInside)
        titleStackView.addArrangedSubview(createGroupButton)
    }
    
    private func setupEmptyStateView() {
        view.addSubview(emptyStateView)
        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            emptyStateView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshFriendRequestBadge),
                                               name: NSNotification.Name("FriendRequestUpdated"),
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshFriendRequestBadge),
                                             name: NSNotification.Name("FriendRequestUpdated"),
                                             object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshChatList),
                                             name: NSNotification.Name("ChatListUpdated"),
                                             object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshChatList),
                                             name: NSNotification.Name("FriendAddedToChat"),
                                             object: nil)
        
    }
    @objc private func refreshFriendRequestBadge() {
        updateFriendRequestBadge()
    }
    
    // MARK: - Data Loading
    private func fetchCurrentUser() {
        guard let firebaseUser = Auth.auth().currentUser else { return }
        
        let currentUserID = firebaseUser.uid
        chatManager.fetchUsers { [weak self] users in
            guard let self = self else { return }
            
            if let currentUser = users.first(where: { $0.id == currentUserID }) {
                self.currentUser = currentUser
                self.fetchFriends(for: currentUser)
            }
        }
    }
    
    private func fetchFriends(for user: User) {
        FriendsService.shared.fetchFriends(forUserID: user.id) { [weak self] friends, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching friends:", error)
                self.updateEmptyState()
                return
            }
            
            let friendIDs = friends?.map { $0.friendID } ?? []
            
            if friendIDs.isEmpty {
                self.friends = []
                self.filteredFriends = []
                self.fetchGroups() // Still fetch groups even if no friends
                self.fetchEventGroups()
                return
            }
            
            self.fetchFriendDetails(for: friendIDs)
        }
    }
    
    private func fetchFriendDetails(for friendIDs: [String]) {
        let dispatchGroup = DispatchGroup()
        var fetchedFriends: [User] = []

        for friendID in friendIDs {
            dispatchGroup.enter()
            FriendsService.shared.fetchUserDetails(uid: friendID) { user, _ in
                if let user = user { fetchedFriends.append(user) }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.friends = fetchedFriends
            self.filteredFriends = fetchedFriends
            self.updateMessageListeners()
            self.fetchGroups()
            self.fetchEventGroups()
        }
    }
    
    private func fetchGroups() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        db.collection("groups").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching groups:", error)
                self.updateEmptyState()
                return
            }
            
            let dispatchGroup = DispatchGroup()
            var userGroups: [Group] = []
            
            for document in snapshot?.documents ?? [] {
                let groupID = document.documentID
                dispatchGroup.enter()
                
                self.db.collection("groups")
                    .document(groupID)
                    .collection("members")
                    .document(currentUserID)
                    .getDocument { memberDoc, _ in
                        if memberDoc?.exists == true {
                            let data = document.data()
                            let group = Group(
                                id: groupID,
                                name: data["name"] as? String ?? "Unnamed Group",
                                members: [],
                                imageURL: data["imageURL"] as? String ?? ""
                            )
                            userGroups.append(group)
                        }
                        dispatchGroup.leave()
                    }
            }
            
            dispatchGroup.notify(queue: .main) {
                self.groups = userGroups
                self.updateEmptyState()
                self.tableView.reloadData()
            }
        }
    }
    
    private func fetchEventGroups() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        db.collection("eventGroups").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching event groups:", error)
                self.updateEmptyState()
                return
            }
            
            let dispatchGroup = DispatchGroup()
            var tempEventGroups: [(eventId: String, name: String, lastMessage: String?, timestamp: Date?, imageURL: String?)] = []
            
            for document in snapshot?.documents ?? [] {
                let eventId = document.documentID
                dispatchGroup.enter()
                
                // Check membership
                self.db.collection("eventGroups").document(eventId)
                    .collection("members").document(currentUserID)
                    .getDocument { [weak self] memberDoc, error in
                        guard let self = self else {
                            dispatchGroup.leave()
                            return
                        }
                        
                        if memberDoc?.exists == true {
                            // Get event details
                            self.db.collection("events").document(eventId).getDocument { eventDoc, _ in
                                if let eventData = eventDoc?.data() {
                                    let eventName = eventData["title"] as? String ?? "Event"
                                    let imageURL = eventData["imageName"] as? String
                                    
                                    // Get last message
                                    self.db.collection("eventGroups").document(eventId)
                                        .collection("messages")
                                        .order(by: "timestamp", descending: true)
                                        .limit(to: 1)
                                        .getDocuments { msgSnapshot, _ in
                                            var lastMessage: String?
                                            var timestamp: Date?
                                            
                                            if let msgDoc = msgSnapshot?.documents.first {
                                                lastMessage = msgDoc.data()["text"] as? String
                                                timestamp = (msgDoc.data()["timestamp"] as? Timestamp)?.dateValue()
                                            }
                                            
                                            tempEventGroups.append((
                                                eventId: eventId,
                                                name: eventName,
                                                lastMessage: lastMessage,
                                                timestamp: timestamp,
                                                imageURL: imageURL
                                            ))
                                            dispatchGroup.leave()
                                        }
                                } else {
                                    dispatchGroup.leave()
                                }
                            }
                        } else {
                            dispatchGroup.leave()
                        }
                    }
            }
            
            dispatchGroup.notify(queue: .main) {
                self.eventGroups = tempEventGroups.sorted {
                    ($0.timestamp ?? Date.distantPast) > ($1.timestamp ?? Date.distantPast)
                }
                print("Fetched \(self.eventGroups.count) event groups")
                self.updateEmptyState()
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Empty State
    private func updateEmptyState() {
        let isEmpty = friends.isEmpty && groups.isEmpty && eventGroups.isEmpty
        print("Empty state check - Friends: \(friends.count), Groups: \(groups.count), Events: \(eventGroups.count), Show empty: \(isEmpty)")
        
        DispatchQueue.main.async {
            self.emptyStateView.isHidden = !isEmpty
            self.tableView.isHidden = isEmpty
            
            if isEmpty {
                for subview in self.emptyStateView.subviews {
                    if let button = subview as? UIButton {
                        button.addTarget(self, action: #selector(self.openFriendsViewController), for: .touchUpInside)
                        break
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    @objc private func refreshChatList() {
        guard let currentUser = currentUser else { return }
        fetchFriends(for: currentUser)
    }
    
    @objc private func openFriendsViewController() {
        let friendsVC = FriendsViewController()
        friendsVC.currentUser = currentUser
        navigationController?.pushViewController(friendsVC, animated: true)
    }
    
    @objc private func openCreateGroupView() {
        let createGroupVC = CreateGroupViewController()
        createGroupVC.currentUser = currentUser
        createGroupVC.friends = friends
        let navController = UINavigationController(rootViewController: createGroupVC)
        
        if let sheet = navController.presentationController as? UISheetPresentationController {
            sheet.detents = [.medium(), .large()]
        }
        
        present(navController, animated: true)
    }
    
    @objc private func openFriendRequestsViewController() {
        let friendRequestsVC = FriendRequestsViewController()
        friendRequestsVC.currentUser = currentUser
        let navController = UINavigationController(rootViewController: friendRequestsVC)
        navController.modalPresentationStyle = .pageSheet
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
        }
        present(navController, animated: true)
    }
    
  
    
    private func updateFriendRequestBadge() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        db.collection("friend_requests")
            .whereField("toUserID", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching friend requests count: \(error.localizedDescription)")
                    return
                }
                
                let pendingRequests = snapshot?.documents.count ?? 0
                
                DispatchQueue.main.async {
                    if pendingRequests > 0 {
                        self.requestBadgeView.text = "\(pendingRequests)"
                        self.requestBadgeView.isHidden = false
                    } else {
                        self.requestBadgeView.isHidden = true
                    }
                }
            }
    }
    
    // MARK: - Chat Functions
    private func updateMessageListeners() {
        messageListeners.values.forEach { $0.remove() }
        messageListeners.removeAll()
        
        guard let currentUser = currentUser else { return }
        
        for friend in friends {
            chatManager.fetchOrCreateChatThread(for: currentUser.id, with: friend.id) { [weak self] thread in
                guard let self = self, let thread = thread else { return }
                
                let listener = self.db.collection("chats")
                    .document(thread.id)
                    .collection("messages")
                    .order(by: "timestamp", descending: true)
                    .limit(to: 1)
                    .addSnapshotListener { [weak self] snapshot, error in
                        guard let self = self else { return }
                        
                        if let document = snapshot?.documents.first {
                            let data = document.data()
                            let messageContent = data["messageContent"] as? String ?? ""
                            let senderId = data["senderId"] as? String ?? ""
                            let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                            
                            let sender = thread.participants.first { $0.id == senderId } ?? User(id: senderId, name: "Unknown")
                            let message = ChatMessage(
                                id: document.documentID,
                                sender: sender,
                                messageContent: messageContent,
                                timestamp: timestamp,
                                isSender: senderId == currentUser.id
                            )
                            
                            self.lastMessages[friend.id] = message
                            self.sortAndReloadData()
                        }
                    }
                
                self.messageListeners[thread.id] = listener
            }
        }
    }
    
    private func sortAndReloadData() {
        filteredFriends.sort { (friend1, friend2) -> Bool in
            let time1 = lastMessages[friend1.id]?.timestamp ?? Date.distantPast
            let time2 = lastMessages[friend2.id]?.timestamp ?? Date.distantPast
            return time1 > time2
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    public func startChat(with friend: User) {
        guard let currentUser = currentUser else { return }

        chatManager.fetchOrCreateChatThread(for: currentUser.id, with: friend.id) { [weak self] thread in
            guard let self = self, let thread = thread else { return }

            DispatchQueue.main.async {
                let chatDetailVC = ChatDetailViewController()
                chatDetailVC.chatThread = thread
                chatDetailVC.delegate = self
                
                let navController = UINavigationController(rootViewController: chatDetailVC)
                navController.modalPresentationStyle = .fullScreen
                self.present(navController, animated: true)
            }
        }
    }
    
    private func openGroupChat(group: Group) {
        let currentUserID = Auth.auth().currentUser?.uid ?? ""
        
        db.collection("groups")
            .document(group.id)
            .collection("members")
            .document(currentUserID)
            .getDocument { [weak self] document, _ in
                guard let self = self else { return }
                
                let isAdmin = document?.data()?["role"] as? String == "admin"
                
                self.db.collection("groups")
                    .document(group.id)
                    .collection("members")
                    .getDocuments { snapshot, _ in
                        var members: [UserGroup.Member] = []
                        
                        for memberDoc in snapshot?.documents ?? [] {
                            let userId = memberDoc.documentID
                            let data = memberDoc.data()
                            let member = UserGroup.Member(
                                userId: userId,
                                name: data["name"] as? String ?? "Unknown",
                                role: data["role"] as? String ?? "member",
                                joinedAt: (data["joinedAt"] as? Timestamp)?.dateValue() ?? Date(),
                                canChat: data["canChat"] as? Bool ?? true,
                                profileImageURL: data["profileImageURL"] as? String
                            )
                            members.append(member)
                        }
                        
                        DispatchQueue.main.async {
                            let groupVC = GroupViewController(
                                groupId: group.id,
                                groupName: group.name,
                                members: members
                            )
                            self.navigationController?.pushViewController(groupVC, animated: true)
                        }
                    }
            }
    }
    
    private func openEventGroupChat(eventId: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        db.collection("eventGroups")
            .document(eventId)
            .collection("members")
            .document(currentUserID)
            .getDocument { [weak self] document, _ in
                guard let self = self else { return }
                
                let eventName = self.eventGroups.first(where: { $0.eventId == eventId })?.name ?? "Event Group"
                
                self.db.collection("eventGroups")
                    .document(eventId)
                    .collection("members")
                    .getDocuments { snapshot, _ in
                        var members: [EventGroup.Member] = []
                        
                        for memberDoc in snapshot?.documents ?? [] {
                            let userId = memberDoc.documentID
                            let data = memberDoc.data()
                            let member = EventGroup.Member(
                                userId: userId,
                                name: data["name"] as? String ?? "Unknown",
                                role: data["role"] as? String ?? "member",
                                joinedAt: (data["joinedAt"] as? Timestamp)?.dateValue() ?? Date(),
                                canChat: data["canChat"] as? Bool ?? true,
                                profileImageURL: data["profileImageURL"] as? String
                            )
                            members.append(member)
                        }
                        
                        DispatchQueue.main.async {
                            let eventGroupVC = EventGroupViewController(
                                eventId: eventId,
                                eventName: eventName,
                                members: members
                            )
                            self.navigationController?.pushViewController(eventGroupVC, animated: true)
                        }
                    }
            }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension ChatViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let total = filteredFriends.count + groups.count + eventGroups.count
        print("Total rows: \(total) (friends: \(filteredFriends.count), groups: \(groups.count), events: \(eventGroups.count))")
        return total
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ChatCell.identifier, for: indexPath) as? ChatCell else {
            return UITableViewCell()
        }
        
        if indexPath.row < groups.count {
            let group = groups[indexPath.row]
            cell.configure(
                with: group.name,
                message: "Group Chat",
                time: "",
                profileImageURL: group.imageURL
            )
        }
        else if indexPath.row < groups.count + eventGroups.count {
            let eventIndex = indexPath.row - groups.count
            let event = eventGroups[eventIndex]
            
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            let timeString = event.timestamp != nil ? formatter.string(from: event.timestamp!) : ""
            
            cell.configure(
                with: "🎯 \(event.name)",
                message: event.lastMessage ?? "Event Group Chat",
                time: timeString,
                profileImageURL: event.imageURL
            )
        }
        else {
            let friendIndex = indexPath.row - groups.count - eventGroups.count
            let friend = filteredFriends[friendIndex]
            let lastMessage = lastMessages[friend.id]
            
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            let timeString = lastMessage?.timestamp != nil ? formatter.string(from: lastMessage!.timestamp) : ""
            
            cell.configure(
                with: friend.name,
                message: lastMessage?.messageContent ?? "Tap to start a chat",
                time: timeString,
                profileImageURL: friend.profileImageURL
            )
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row < groups.count {
            openGroupChat(group: groups[indexPath.row])
        }
        else if indexPath.row < groups.count + eventGroups.count {
            let eventGroupIndex = indexPath.row - groups.count
            openEventGroupChat(eventId: eventGroups[eventGroupIndex].eventId)
        }
        else {
            let friendIndex = indexPath.row - groups.count - eventGroups.count
            startChat(with: filteredFriends[friendIndex])
        }
    }
}

// MARK: - UISearchBarDelegate
extension ChatViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredFriends = friends
        } else {
            filteredFriends = friends.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - ChatDetailViewControllerDelegate
extension ChatViewController: ChatDetailViewControllerDelegate {
    func didSendMessage(_ message: ChatMessage, to friend: User) {
        lastMessages[friend.id] = message
        tableView.reloadData()
    }
}

// MARK: - Preview
#Preview {
    ChatViewController()
}
#Preview{
    ChatViewController()
}

extension Date {
    func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }
}
