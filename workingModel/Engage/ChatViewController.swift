import UIKit
import FirebaseAuth
import FirebaseFirestore


class ChatViewController: UIViewController {
    let tableView = UITableView()
    let chatManager = FirestoreChatManager()
    let searchBar = UISearchBar()
    let titleLabel = UILabel()
    let friendsButton = UIButton(type: .system)
    let titleStackView = UIStackView()
    let friendRequestsButton = UIButton(type: .system)
    let createGroupButton = UIButton(type: .system)

    private func setupCreateGroupButton() {
        let createGroupIcon = UIImage(systemName: "plus.bubble.fill")
        createGroupButton.setImage(createGroupIcon, for: .normal)
        createGroupButton.tintColor = .systemOrange
        createGroupButton.addTarget(self, action: #selector(openCreateGroupView), for: .touchUpInside)
        titleStackView.addArrangedSubview(createGroupButton)
    }
    private let requestBadgeView: UILabel = {
        let label = UILabel()
        label.backgroundColor = .systemGray // Badge background color
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textAlignment = .center
        label.layer.cornerRadius = 11
        label.clipsToBounds = true
        label.isHidden = true // Initially hidden
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    var friends: [User] = [] // Friends fetched from Firestore
    var groups: [Group] = [] // Store fetched groups

    var filteredFriends: [User] = [] // Friends filtered by search
    var currentUser: User? // Current logged-in user
    var lastMessages: [String: ChatMessage] = [:] // Last messages for each
    var messageListeners: [String: ListenerRegistration] = [:] // Listeners for each chat thread
    // Add this property with your other properties
    var eventGroups: [(eventId: String, name: String, lastMessage: String?, timestamp: Date?, imageURL: String?)] = []
    private var db = Firestore.firestore()
    
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

    private func updateEmptyState() {
        let isEmpty = friends.isEmpty
        print("Empty state check - Friends count: \(friends.count), Show empty: \(isEmpty)")
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
        
        if isEmpty {
            for subview in emptyStateView.subviews {
                if let button = subview as? UIButton {
                    button.addTarget(self, action: #selector(openFriendsViewController), for: .touchUpInside)
                    break
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // Setup UI first
        setupTitleStackView()
        setupSearchBar()
        setupTableView()
        setupCreateGroupButton()
        
        // Add empty state view (hidden by default)
        view.addSubview(emptyStateView)
        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            emptyStateView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
        
        // Start with empty state hidden and table view shown
        emptyStateView.isHidden = true
        tableView.isHidden = false
        
        // Then fetch data
        fetchCurrentUser()
        
        // Setup notifications
        NotificationCenter.default.addObserver(self, selector: #selector(refreshFriendRequestBadge), name: NSNotification.Name("FriendRequestUpdated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshChatList), name: NSNotification.Name("ChatListUpdated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshChatList), name: NSNotification.Name("FriendAddedToChat"), object: nil)
        setupRealTimeListeners()
    }

    @objc private func goBack() {
        navigationController?.popViewController(animated: true)
    }

    
    @objc private func refreshChatList() {
        guard let currentUser = currentUser else { return }
        fetchFriends(for: currentUser)
    }
    deinit {
        // Remove all listeners
        messageListeners.values.forEach { $0.remove() }
    }
    private func setupTitleStackView() {
        
        view.addSubview(emptyStateView)
            NSLayoutConstraint.activate([
                emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                emptyStateView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
                emptyStateView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
            ])
        // Configure titleLabel
        titleLabel.text = "Chat"
        titleLabel.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        titleLabel.textAlignment = .left

        // Configure friendRequestsButton with an SF Symbol icon
        let friendsIcon = UIImage(systemName: "person.2.fill") // iOS Friends Icon
        friendRequestsButton.setImage(friendsIcon, for: .normal)
        friendRequestsButton.tintColor = .systemOrange // Change color to systemOrange
        friendRequestsButton.addTarget(self, action: #selector(openFriendRequestsViewController), for: .touchUpInside)

        // Shift the icon slightly to the left
        friendRequestsButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)

        // Add badge view (number of pending requests)
        friendRequestsButton.addSubview(requestBadgeView)
        NSLayoutConstraint.activate([
            requestBadgeView.topAnchor.constraint(equalTo: friendRequestsButton.topAnchor, constant: -5),
            requestBadgeView.trailingAnchor.constraint(equalTo: friendRequestsButton.trailingAnchor, constant: 5),
            requestBadgeView.widthAnchor.constraint(equalToConstant: 22),
            requestBadgeView.heightAnchor.constraint(equalToConstant: 22)
        ])
        

        // Configure titleStackView
        titleStackView.axis = .horizontal
        titleStackView.alignment = .center
        titleStackView.distribution = .equalSpacing
        titleStackView.spacing = 8

        // Add titleLabel and friendRequestsButton to titleStackView
        titleStackView.addArrangedSubview(titleLabel)
        titleStackView.addArrangedSubview(friendRequestsButton)

        // Add titleStackView to the view
        view.addSubview(titleStackView)
        titleStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            titleStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            titleStackView.heightAnchor.constraint(equalToConstant: 40)
        ])

        // Fetch and update pending requests count
        updateFriendRequestBadge()
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
    
    private func fetchGroups() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        db.collection("groups").whereField("members", arrayContains: currentUserID).getDocuments { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching groups: \(error.localizedDescription)")
                return
            }
            
            self.groups = snapshot?.documents.compactMap { doc in
                let data = doc.data()
                return Group(
                    id: doc.documentID,
                    name: data["name"] as? String ?? "Unnamed Group",
                    members: data["members"] as? [String] ?? []
                )
            } ?? []
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }


    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.placeholder = "Search"
        
        // Reverting to original grey background
        let greyColor = UIColor.systemGray6
        searchBar.barTintColor = greyColor
        searchBar.layer.cornerRadius = 12
        searchBar.clipsToBounds = true

        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = greyColor // Grey Input Field
            textField.layer.cornerRadius = 12
            textField.borderStyle = .none // Remove border for a cleaner look
        }

        view.addSubview(searchBar)
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchBar.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ChatCell.self, forCellReuseIdentifier: ChatCell.identifier)
        tableView.separatorStyle = .none // Hide default separators
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
    
    
    @objc private func refreshFriendRequestBadge() {
        updateFriendRequestBadge() // Refresh the count when a request is accepted/rejected
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
            sheet.detents = [.medium(), .large()] // Show as a sheet
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
        present(navController, animated: true, completion: nil)
    }

    private func fetchCurrentUser() {
        guard let firebaseUser = Auth.auth().currentUser else {
            print("No user is logged in")
            return
        }

        let currentUserID = firebaseUser.uid
        chatManager.fetchUsers { [weak self] users in
            guard let self = self else { return }

            if let currentUser = users.first(where: { $0.id == currentUserID }) {
                self.currentUser = currentUser
                self.fetchFriends(for: currentUser)
            } else {
                print("Current user not found in users collection.")
            }
        }
    }

    
    private func fetchFriends(for user: User) {
        print("Fetching friends for user:", user.id)
        FriendsService.shared.fetchFriends(forUserID: user.id) { [weak self] friends, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching friends:", error)
                self.updateEmptyState()
                return
            }
            
            let friendIDs = friends?.map { $0.friendID } ?? []
            print("Found friend IDs:", friendIDs)
            
            if friendIDs.isEmpty {
                print("No friends found - showing empty state")
                self.friends = []
                self.filteredFriends = []
                DispatchQueue.main.async {
                    self.updateEmptyState()
                    self.tableView.reloadData()
                }
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
            FriendsService.shared.fetchUserDetails(uid: friendID) { user, error in
                if let user = user {
                    fetchedFriends.append(user)
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
               guard let self = self else { return }
               
               self.friends = fetchedFriends
               self.filteredFriends = fetchedFriends
               self.updateEmptyState()
               self.updateMessageListeners() // Replaces fetchLastMessages()
               self.sortAndReloadData()
               
               // Now fetch groups and event groups after friends are loaded
               self.fetchGroups()
               self.fetchEventGroups()
        }
    }
    
    

    private func fetchLastMessages() {
        let dispatchGroup = DispatchGroup()
        guard let currentUser = currentUser else { return }

        for friend in friends {
            dispatchGroup.enter()
            chatManager.fetchOrCreateChatThread(for: currentUser.id, with: friend.id) { [weak self] thread in
                guard let self = self, let thread = thread else {
                    dispatchGroup.leave()
                    return
                }
                self.chatManager.fetchLastMessage(for: thread, currentUserID: currentUser.id) { message in
                    if let message = message {
                        self.lastMessages[friend.id] = message
                    }
                    dispatchGroup.leave()
                }
            }
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
    
    // Add this method to fetch event groups where the user is a member
    private func fetchEventGroups() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        // We need to find all event groups where the current user is a member
        db.collection("eventGroups").getDocuments { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching event groups: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                return
            }
            
            var pendingGroups = documents.count
            var newEventGroups: [(eventId: String, name: String, lastMessage: String?, timestamp: Date?, imageURL: String?)] = []
            
            for document in documents {
                let eventId = document.documentID
                
                // Check if the user is a member of this event group
                self.db.collection("eventGroups")
                    .document(eventId)
                    .collection("members")
                    .document(currentUserID)
                    .getDocument { [weak self] (userDoc, error) in
                        guard let self = self else { return }
                        pendingGroups -= 1
                        
                        // If the document exists, the user is a member of this event group
                        if let userDoc = userDoc, userDoc.exists {
                            // Get event details from events collection
                            self.db.collection("events").document(eventId).getDocument { (eventDoc, error) in
                                if let eventData = eventDoc?.data(),
                                   let eventName = eventData["title"] as? String {
                                    
                                    // Get the image URL
                                    let imageURL = eventData["imageName"] as? String
                                    
                                    // Fetch the most recent message if any
                                    self.db.collection("eventGroups").document(eventId)
                                        .collection("messages")
                                        .order(by: "timestamp", descending: true)
                                        .limit(to: 1)
                                        .getDocuments { (msgSnapshot, msgError) in
                                            
                                            var lastMessage: String? = nil
                                            var timestamp: Date? = nil
                                            
                                            if let msgDoc = msgSnapshot?.documents.first {
                                                lastMessage = msgDoc.data()["text"] as? String
                                                timestamp = (msgDoc.data()["timestamp"] as? Timestamp)?.dateValue()
                                            }
                                            
                                            let group = (
                                                eventId: eventId,
                                                name: eventName,
                                                lastMessage: lastMessage,
                                                timestamp: timestamp,
                                                imageURL: imageURL
                                            )
                                            
                                            newEventGroups.append(group)
                                            
                                            // When all groups are processed, update the UI
                                            if pendingGroups == 0 {
                                                self.eventGroups = newEventGroups.sorted(by: {
                                                    ($0.timestamp ?? Date.distantPast) > ($1.timestamp ?? Date.distantPast)
                                                })
                                                
                                                DispatchQueue.main.async {
                                                    self.tableView.reloadData()
                                                }
                                            }
                                        }
                                } else if pendingGroups == 0 && newEventGroups.isEmpty {
                                    DispatchQueue.main.async {
                                        self.tableView.reloadData()
                                    }
                                }
                            }
                        } else if pendingGroups == 0 && newEventGroups.isEmpty {
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        }
                    }
            }
        }
    }

    
    // Add this method to navigate to an event group
    private func openEventGroupChat(eventId: String) {
        // Check user role in this event group
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        db.collection("eventGroups").document(eventId)
            .collection("members").document(currentUserID)
            .getDocument { [weak self] (document, error) in
                guard let self = self else { return }
                
                let isOrganizer = document?.data()?["role"] as? String == "organizer"
                
                DispatchQueue.main.async {
                    let eventGroupVC = EventGroupViewController(eventId: eventId, isOrganizer: isOrganizer)
                    self.navigationController?.pushViewController(eventGroupVC, animated: true)
                }
            }
    }
    
    

    private func addMessageListeners() {
        guard let currentUser = currentUser else { return }

        for friend in friends {
            chatManager.fetchOrCreateChatThread(for: currentUser.id, with: friend.id) { [weak self] thread in
                guard let self = self, let thread = thread else { return }
                let listener = self.db.collection("chats")
                    .document(thread.id)
                    .collection("messages")
                    .order(by: "timestamp", descending: true)
                    .limit(to: 1)
                    .addSnapshotListener { [weak self] (snapshot: QuerySnapshot?, error: Error?) in
                        guard let self = self else { return }
                        if let error = error {
                            print("Error listening for messages: \(error)")
                            return
                        }
                        guard let document = snapshot?.documents.first else { return }
                        let data = document.data()
                        let messageContent = data["messageContent"] as? String ?? ""
                        let senderId = data["senderId"] as? String ?? ""
                        let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()

                        let sender = thread.participants.first { $0.id == senderId } ?? User(id: senderId, name: "Unknown")
                        let message = ChatMessage(id: document.documentID, sender: sender, messageContent: messageContent, timestamp: timestamp, isSender: senderId == currentUser.id)

                        self.lastMessages[friend.id] = message
                        self.tableView.reloadData()
                    }
                self.messageListeners[thread.id] = listener
            }
        }
    }

    public func startChat(with friend: User) {
        guard let currentUser = currentUser else {
            print("Current user is nil. Cannot start chat.")
            return
        }

        chatManager.fetchOrCreateChatThread(for: currentUser.id, with: friend.id) { [weak self] thread in
            guard let self = self, let thread = thread else {
                print("Error creating or fetching chat thread.")
                return
            }

            DispatchQueue.main.async {
                let chatDetailVC = ChatDetailViewController()
                chatDetailVC.chatThread = thread
                chatDetailVC.delegate = self

                // Present ChatDetailViewController in full-screen mode without the tab bar
                let navController = UINavigationController(rootViewController: chatDetailVC)
                navController.modalPresentationStyle = .fullScreen
                self.present(navController, animated: true, completion: nil)
            }
        }
    }
    
    private func openGroupChat(group: Group) {
        print("Opening Group Chat for group ID: \(group.id)") // Debugging

        let chatDetailVC = ChatDetailViewController()
        chatDetailVC.group = group // Pass group data
        chatDetailVC.isGroupChat = true // Indicate it's a group chat

        let navController = UINavigationController(rootViewController: chatDetailVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }


}

// MARK: - UITableViewDataSource and UITableViewDelegate

extension ChatViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredFriends.count + groups.count + eventGroups.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ChatCell.identifier, for: indexPath) as? ChatCell else {
            return UITableViewCell()
        }

        if indexPath.row < groups.count {
            // Display Group Chat
            let group = groups[indexPath.row]
            cell.configure(
                with: group.name,
                message: "Group Chat",
                time: "",
                profileImageURL: nil
            )
        } else if indexPath.row < groups.count + eventGroups.count {
            // Display Event Group Chat
            let eventGroupIndex = indexPath.row - groups.count
            let eventGroup = eventGroups[eventGroupIndex]
            
            let messageText = eventGroup.lastMessage ?? "Event Group Chat"
            var timeString = ""
            if let timestamp = eventGroup.timestamp {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                timeString = formatter.string(from: timestamp)
            }
            
            cell.configure(
                with: "🎯 \(eventGroup.name)",
                message: messageText,
                time: timeString,
                profileImageURL: eventGroup.imageURL // Pass the image URL
            )
        } else {
            // Display Individual Chat
            let friendIndex = indexPath.row - groups.count - eventGroups.count
            let friend = filteredFriends[friendIndex]
            let lastMessage = lastMessages[friend.id]
            let messageText = lastMessage?.messageContent ?? "Tap to start a chat"
            let messageTime = lastMessage?.formattedTime() ?? ""

            cell.configure(
                with: friend.name,
                message: messageText,
                time: messageTime,
                profileImageURL: friend.profileImageURL
            )
        }

        return cell
    }
    
    
    // Update tableView didSelectRowAt
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row < groups.count {
            // Open Group Chat
            let selectedGroup = groups[indexPath.row]
            openGroupChat(group: selectedGroup)
        } else if indexPath.row < groups.count + eventGroups.count {
            // Open Event Group Chat
            let eventGroupIndex = indexPath.row - groups.count
            let selectedEventGroup = eventGroups[eventGroupIndex]
            openEventGroupChat(eventId: selectedEventGroup.eventId)
        } else {
            // Open Individual Chat
            let friendIndex = indexPath.row - groups.count - eventGroups.count
            let selectedFriend = filteredFriends[friendIndex]
            startChat(with: selectedFriend)
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
// MARK: - Real-time Updates Implementation
extension ChatViewController {
    
    private func setupRealTimeListeners() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        // 1. Friends listener
        setupFriendsListener(currentUserID: currentUserID)
        
        // 2. Groups listener
        setupGroupsListener(currentUserID: currentUserID)
        
        // 3. Event groups listener
        setupEventGroupsListener(currentUserID: currentUserID)
    }
    
    private func setupFriendsListener(currentUserID: String) {
        FriendsService.shared.friendsListener(forUserID: currentUserID) { [weak self] result in
            switch result {
            case .success(let friendIDs):
                self?.fetchFriendDetails(for: friendIDs)
            case .failure(let error):
                print("Error listening for friends: \(error.localizedDescription)")
            }
        }
    }
    
    private func setupGroupsListener(currentUserID: String) {
        db.collection("groups")
            .whereField("members", arrayContains: currentUserID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening for groups: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.groups = documents.compactMap { doc in
                    let data = doc.data()
                    return Group(
                        id: doc.documentID,
                        name: data["name"] as? String ?? "Unnamed Group",
                        members: data["members"] as? [String] ?? []
                    )
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }
    
    private func setupEventGroupsListener(currentUserID: String) {
        db.collection("eventGroups")
            .whereField("members.\(currentUserID)", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening for event groups: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                var newEventGroups: [(eventId: String, name: String, lastMessage: String?, timestamp: Date?, imageURL: String?)] = []
                let dispatchGroup = DispatchGroup()
                
                for document in documents {
                    let eventId = document.documentID
                    dispatchGroup.enter()
                    
                    // Get event details
                    self.db.collection("events").document(eventId).getDocument { eventDoc, _ in
                        let eventName = eventDoc?.data()?["title"] as? String ?? "Event"
                        let imageURL = eventDoc?.data()?["imageName"] as? String
                        
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
                                
                                newEventGroups.append((
                                    eventId: eventId,
                                    name: eventName,
                                    lastMessage: lastMessage,
                                    timestamp: timestamp,
                                    imageURL: imageURL
                                ))
                                
                                dispatchGroup.leave()
                            }
                    }
                }
                
                dispatchGroup.notify(queue: .main) {
                    self.eventGroups = newEventGroups.sorted {
                        ($0.timestamp ?? Date.distantPast) > ($1.timestamp ?? Date.distantPast)
                    }
                    self.tableView.reloadData()
                }
            }
    }
    
    private func updateMessageListeners() {
        // Remove existing listeners
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
                        
                        if let error = error {
                            print("Error listening for messages: \(error.localizedDescription)")
                            return
                        }
                        
                        guard let document = snapshot?.documents.first else { return }
                        
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
                
                self.messageListeners[thread.id] = listener
            }
        }
    }
    
    private func sortAndReloadData() {
        // Sort friends by last message timestamp (newest first)
        filteredFriends.sort { (friend1, friend2) -> Bool in
            let time1 = lastMessages[friend1.id]?.timestamp ?? Date.distantPast
            let time2 = lastMessages[friend2.id]?.timestamp ?? Date.distantPast
            return time1 > time2
        }
        
        // Groups are already sorted by creation date or other criteria
        // Event groups are sorted by last message timestamp
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}
#Preview{
    ChatViewController()
}
