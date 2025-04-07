import UIKit
import FirebaseFirestore
import FirebaseAuth

// Add this at the top of NotificationViewController.swift
extension Notification.Name {
    static let newMessageReceived = Notification.Name("newMessageReceived")
}

class NotificationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private var notifications: [NotificationModel] = []
    private let db = Firestore.firestore()
    private var notificationListener: ListenerRegistration?
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(NotificationTableViewCell.self, forCellReuseIdentifier: NotificationTableViewCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        return tableView
    }()
    
    private let emptyStateView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()
    
    private let emptyStateImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "bell.slash"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray3
        return imageView
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No notifications yet"
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotifications()
        loadNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateBadgeCount()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Notifications"
        
        // Setup navigation bar
        if #available(iOS 13.0, *) {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "trash"),
                style: .plain,
                target: self,
                action: #selector(clearAllNotifications)
            )
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "Clear All",
                style: .plain,
                target: self,
                action: #selector(clearAllNotifications)
            )
        }
        
        // Setup tableView
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = view.bounds
        
        // Setup empty state view
        view.addSubview(emptyStateView)
        emptyStateView.addSubview(emptyStateImageView)
        emptyStateView.addSubview(emptyStateLabel)
        
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateImageView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.widthAnchor.constraint(equalToConstant: 200),
            emptyStateView.heightAnchor.constraint(equalToConstant: 200),
            
            emptyStateImageView.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateImageView.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 60),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 60),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor, constant: 16),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor)
        ])
        
        // Setup refresh control
        setupRefreshControl()
    }
    
    private func setupNotifications() {
        // Start real-time notification updates
        startRealTimeNotificationUpdates()
        
        // Listen for new message notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshNotifications),
            name: .newMessageReceived,
            object: nil
        )
    }
    
    private func setupRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshNotifications), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    @objc private func refreshNotifications() {
        loadNotifications()
    }
    
    @objc private func clearAllNotifications() {
        // Ask for confirmation
        let alertController = UIAlertController(
            title: "Clear All Notifications",
            message: "Are you sure you want to clear all notifications? This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(UIAlertAction(title: "Clear All", style: .destructive) { [weak self] _ in
            self?.deleteAllNotifications()
        })
        
        present(alertController, animated: true)
    }
    
    
    private func deleteNotification(_ notificationId: String) {
        db.collection("notifications").document(notificationId).delete { [weak self] error in
            if let error = error {
                print("Error deleting notification: \(error.localizedDescription)")
            } else {
                print("Notification successfully deleted")
                
                // Also remove from local array and update UI
                if let index = self?.notifications.firstIndex(where: { $0.id == notificationId }) {
                    DispatchQueue.main.async {
                        self?.notifications.remove(at: index)
                        self?.tableView.reloadData()
                        self?.updateEmptyState()
                        self?.updateBadgeCount()
                    }
                }
            }
        }
    }
    
    private func deleteAllNotifications() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let batch = db.batch()
        
        db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                for document in documents {
                    batch.deleteDocument(document.reference)
                }
                
                batch.commit { error in
                    if let error = error {
                        print("Error deleting notifications: \(error.localizedDescription)")
                    } else {
                        DispatchQueue.main.async {
                            self?.notifications.removeAll()
                            self?.tableView.reloadData()
                            self?.updateEmptyState()
                            self?.updateBadgeCount()
                        }
                    }
                }
            }
    }
    
    private func startRealTimeNotificationUpdates() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not authenticated.")
            return
        }
        
        // Stop previous listener if exists
        notificationListener?.remove()
        
        // Listen for real-time updates
        notificationListener = db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                if let error = error {
                    print("Error listening for notification updates: \(error.localizedDescription)")
                    return
                }
                
                self?.loadNotificationsFromSnapshot(querySnapshot)
            }
    }
    
    private func loadNotificationsFromSnapshot(_ querySnapshot: QuerySnapshot?) {
        self.notifications = querySnapshot?.documents.compactMap { document in
            return NotificationModel(document: document)
        } ?? []
        
        DispatchQueue.main.async {
            self.tableView.refreshControl?.endRefreshing()
            self.tableView.reloadData()
            self.updateEmptyState()
            self.updateBadgeCount()
        }
    }
    
    // Add this to the loadNotifications method in NotificationViewController.swift

    private func loadNotifications() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not authenticated.")
            return
        }
        
        print("🔍 Attempting to load notifications for user: \(userId)")
        
        db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .getDocuments { [weak self] querySnapshot, error in
                if let error = error {
                    print("❌ Error fetching notifications: \(error.localizedDescription)")
                    return
                }
                
                guard let snapshot = querySnapshot else {
                    print("❌ No snapshot returned for notifications query")
                    return
                }
                
                print("📄 Found \(snapshot.documents.count) notification documents")
                
                // Debug print each notification document
                for (index, doc) in snapshot.documents.enumerated() {
                    print("📄 Notification[\(index)]: ID=\(doc.documentID)")
                    print("📄 Data: \(doc.data())")
                }
                
                self?.loadNotificationsFromSnapshot(querySnapshot)
            }
    }
    
    private func updateEmptyState() {
        emptyStateView.isHidden = !notifications.isEmpty
    }
    
    private func updateBadgeCount() {
        let unreadCount = notifications.filter { !$0.isRead }.count
        if unreadCount > 0 {
            self.tabBarItem.badgeValue = "\(unreadCount)"
        } else {
            self.tabBarItem.badgeValue = nil
        }
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NotificationTableViewCell.identifier, for: indexPath) as! NotificationTableViewCell
        cell.configure(with: notifications[indexPath.row])
        return cell
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let notification = notifications[indexPath.row]
        deleteNotification(notification.id)
        
        // Handle different types of notifications
        if let chatId = notification.chatId {
            // This is a chat message notification
            navigateToChat(chatId: chatId, senderId: notification.senderId)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completion) in
            guard let self = self else { return }
            
            // Delete notification from Firestore
            let notification = self.notifications[indexPath.row]
            self.db.collection("notifications").document(notification.id).delete { error in
                if let error = error {
                    print("Error deleting notification: \(error.localizedDescription)")
                } else {
                    // Remove from local array
                    self.notifications.remove(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath], with: .automatic)
                    self.updateEmptyState()
                    self.updateBadgeCount()
                }
            }
            
            completion(true)
        }
        
        // Create a mark as read/unread action
        let isRead = self.notifications[indexPath.row].isRead
        let readTitle = isRead ? "Mark as Unread" : "Mark as Read"
        let readAction = UIContextualAction(style: .normal, title: readTitle) { [weak self] (action, view, completion) in
            guard let self = self else { return }
            
            let notification = self.notifications[indexPath.row]
            
            // Toggle read status
            let newReadStatus = !notification.isRead
            self.db.collection("notifications").document(notification.id).updateData([
                "isRead": newReadStatus
            ]) { error in
                if let error = error {
                    print("Error updating notification read status: \(error.localizedDescription)")
                } else {
                    // Update local model
                    self.notifications[indexPath.row].isRead = newReadStatus
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                    self.updateBadgeCount()
                }
            }
            
            completion(true)
        }
        
        // Set background color for read/unread action
        readAction.backgroundColor = .systemBlue
        
        return UISwipeActionsConfiguration(actions: [deleteAction, readAction])
    }
    
    private func markNotificationAsRead(_ notification: NotificationModel) {
        // Skip if already read
        if notification.isRead {
            return
        }
        
        db.collection("notifications").document(notification.id).updateData(["isRead": true]) { [weak self] error in
            if let error = error {
                print("Error marking notification as read: \(error.localizedDescription)")
            } else {
                if let index = self?.notifications.firstIndex(where: { $0.id == notification.id }) {
                    self?.notifications[index].isRead = true
                    DispatchQueue.main.async {
                        self?.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                        self?.updateBadgeCount()
                    }
                }
            }
        }
    }
    
    private func navigateToChat(chatId: String, senderId: String?) {
        // First mark all messages in this chat as read
        MessageNotificationService.shared.markAllMessagesAsRead(chatId: chatId)
        
        // Fetch the sender user details
        if let senderId = senderId {
            // Fetch user details for the sender
            FriendsService.shared.fetchUserDetails(uid: senderId) { [weak self] user, error in
                guard let self = self, let friendUser = user else {
                    if let error = error {
                        print("Error fetching sender details: \(error)")
                    }
                    return
                }
                
                // Get the current user ID
                guard let currentUserId = Auth.auth().currentUser?.uid else { return }
                
                // Create a new ChatViewController
                let chatViewController = ChatViewController()
                
                // First get the current user and then start chat with friend
                FriendsService.shared.fetchUserDetails(uid: currentUserId) { currentUser, error in
                    guard let currentUser = currentUser else { return }
                    
                    // Set the current user on the ChatViewController
                    chatViewController.currentUser = currentUser
                    
                    // Wait a moment for the ChatViewController to be ready
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        // Start chat with this friend
                        chatViewController.startChat(with: friendUser)
                    }
                }
                
                // Navigate to the ChatViewController first
                self.navigationController?.pushViewController(chatViewController, animated: true)
            }
        } else {
            // If we don't have the sender ID, just navigate to the main chat list
            let chatViewController = ChatViewController()
            self.navigationController?.pushViewController(chatViewController, animated: true)
        }
    }
    
    
    
    deinit {
        // Clean up listeners
        notificationListener?.remove()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Supporting Types
// You may need to create this class if it doesn't exist or modify it to accept a chatId
