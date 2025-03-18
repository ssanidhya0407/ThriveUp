import UIKit
import FirebaseFirestore
import FirebaseAuth

class NotificationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properties
    private let tableView = UITableView()
    private var notifications: [NotificationModel] = []
    private let db = Firestore.firestore()
    private let refreshControl = UIRefreshControl()
    private let emptyStateLabel = UILabel()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchNotifications() // Refresh notifications when view appears
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
        title = "Notifications"
        
        // Setup TableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(NotificationCell.self, forCellReuseIdentifier: "NotificationCell")
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        
        // Add refresh control
        refreshControl.addTarget(self, action: #selector(refreshNotifications), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        // Setup empty state label
        emptyStateLabel.text = "You have no notifications"
        emptyStateLabel.font = UIFont.systemFont(ofSize: 16)
        emptyStateLabel.textColor = .gray
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.isHidden = true
        
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Data Operations
    @objc private func refreshNotifications() {
        fetchNotifications()
    }
    
    func fetchNotifications() {
        guard let userId = Auth.auth().currentUser?.uid else {
            refreshControl.endRefreshing()
            return
        }
        
        db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .getDocuments { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                self.refreshControl.endRefreshing()
                
                if let error = error {
                    print("Error fetching notifications: \(error)")
                    return
                }
                
                var newNotifications: [NotificationModel] = []
                
                for document in querySnapshot?.documents ?? [] {
                    if let notification = NotificationModel(document: document) {
                        newNotifications.append(notification)
                    }
                }
                
                self.notifications = newNotifications
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.emptyStateLabel.isHidden = !self.notifications.isEmpty
                }
                
                // Mark all as seen (not necessarily read)
                self.markNotificationsAsSeen()
            }
    }
    
    private func markNotificationsAsSeen() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).updateData([
            "lastNotificationCheck": FieldValue.serverTimestamp()
        ])
    }
    
    private func markNotificationAsRead(_ notification: NotificationModel) {
        db.collection("notifications").document(notification.id).updateData([
            "isRead": true
        ]) { [weak self] error in
            if let error = error {
                print("Error marking notification as read: \(error)")
                return
            }
            
            // Update local copy
            if let index = self?.notifications.firstIndex(where: { $0.id == notification.id }) {
                self?.notifications[index] = notification.withUpdatedReadStatus(true)
                
                DispatchQueue.main.async {
                    self?.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                }
            }
        }
    }
    
    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationCell", for: indexPath) as! NotificationCell
        let notification = notifications[indexPath.row]
        cell.configure(with: notification)
        return cell
    }
    
    // MARK: - TableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let notification = notifications[indexPath.row]
        
        // Mark notification as read
        markNotificationAsRead(notification)
        
        // Handle notification based on type
        handleNotificationTap(notification)
    }
    
    // MARK: - Notification Handling
    private func handleNotificationTap(_ notification: NotificationModel) {
        // Get notification type from data
        guard let notificationType = getNotificationType(for: notification) else {
            // If no type is found, treat as a regular notification
            showNotificationDetail(notification)
            return
        }
        
        switch notificationType {
        case "team_invitation":
            handleTeamInvitation(notification)
        case "team_join_request":
            handleTeamJoinRequest(notification)
        case "team_join_accepted", "team_join_rejected":
            // Show notification with acknowledgment
            showTeamResponseNotification(notification)
        default:
            // Default behavior for other notifications
            showNotificationDetail(notification)
        }
    }
    
    private func getNotificationType(for notification: NotificationModel) -> String? {
        // First try to get the document with additional data
        let docRef = db.collection("notifications").document(notification.id)
        var notificationType: String?
        
        // We'll use a semaphore for synchronous behavior in this method
        let semaphore = DispatchSemaphore(value: 0)
        
        docRef.getDocument { documentSnapshot, error in
            if let document = documentSnapshot, document.exists,
               let data = document.data(),
               let type = data["notificationType"] as? String {
                notificationType = type
            }
            semaphore.signal()
        }
        
        // Wait for the Firestore call to complete
        _ = semaphore.wait(timeout: .now() + 2.0)
        return notificationType
    }
    
    // MARK: - Team Notification Handlers
    private func handleTeamInvitation(_ notification: NotificationModel) {
        // First get additional data about the team
        let docRef = db.collection("notifications").document(notification.id)
        
        docRef.getDocument { [weak self] documentSnapshot, error in
            guard let self = self,
                  let document = documentSnapshot,
                  let data = document.data(),
                  let teamId = data["teamId"] as? String,
                  let teamName = data["teamName"] as? String,
                  let eventName = data["eventName"] as? String else {
                // Fallback to standard notification if we can't get team data
                self?.showNotificationDetail(notification)
                return
            }
            
            // Show team invitation alert
            let alert = UIAlertController(
                title: "Team Invitation",
                message: "You've been invited to join team '\(teamName)' for the event '\(eventName)'. Would you like to accept?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Decline", style: .destructive) { [weak self] _ in
                NotificationHandler.shared.respondToTeamInvitation(
                    notificationId: notification.id,
                    teamId: teamId,
                    accept: false
                ) { success, message in
                    DispatchQueue.main.async {
                        if success {
                            self?.showToast(message: message)
                            self?.fetchNotifications() // Refresh notifications
                        } else {
                            self?.showAlert(title: "Error", message: message)
                        }
                    }
                }
            })
            
            alert.addAction(UIAlertAction(title: "Accept", style: .default) { [weak self] _ in
                NotificationHandler.shared.respondToTeamInvitation(
                    notificationId: notification.id,
                    teamId: teamId,
                    accept: true
                ) { success, message in
                    DispatchQueue.main.async {
                        if success {
                            self?.showToast(message: message)
                            self?.fetchNotifications() // Refresh notifications
                        } else {
                            self?.showAlert(title: "Error", message: message)
                        }
                    }
                }
            })
            
            self.present(alert, animated: true)
        }
    }
    
    private func handleTeamJoinRequest(_ notification: NotificationModel) {
        // First get additional data about the join request
        let docRef = db.collection("notifications").document(notification.id)
        
        docRef.getDocument { [weak self] documentSnapshot, error in
            guard let self = self,
                  let document = documentSnapshot,
                  let data = document.data(),
                  let teamId = data["teamId"] as? String,
                  let senderId = data["senderId"] as? String,
                  let senderName = data["senderName"] as? String,
                  let teamName = data["teamName"] as? String else {
                // Fallback to standard notification if we can't get team data
                self?.showNotificationDetail(notification)
                return
            }
            
            // Show team join request alert
            let alert = UIAlertController(
                title: "Team Join Request",
                message: "\(senderName) has requested to join your team '\(teamName)'. Would you like to accept?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Decline", style: .destructive) { [weak self] _ in
                NotificationHandler.shared.respondToTeamJoinRequest(
                    notificationId: notification.id,
                    teamId: teamId,
                    userId: senderId,
                    accept: false
                ) { success, message in
                    DispatchQueue.main.async {
                        if success {
                            self?.showToast(message: message)
                            self?.fetchNotifications() // Refresh notifications
                        } else {
                            self?.showAlert(title: "Error", message: message)
                        }
                    }
                }
            })
            
            alert.addAction(UIAlertAction(title: "Accept", style: .default) { [weak self] _ in
                NotificationHandler.shared.respondToTeamJoinRequest(
                    notificationId: notification.id,
                    teamId: teamId,
                    userId: senderId,
                    accept: true
                ) { success, message in
                    DispatchQueue.main.async {
                        if success {
                            self?.showToast(message: message)
                            self?.fetchNotifications() // Refresh notifications
                        } else {
                            self?.showAlert(title: "Error", message: message)
                        }
                    }
                }
            })
            
            self.present(alert, animated: true)
        }
    }
    
    private func showTeamResponseNotification(_ notification: NotificationModel) {
        // Simply show an acknowledgment for team responses
        let alert = UIAlertController(
            title: notification.title,
            message: notification.message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showNotificationDetail(_ notification: NotificationModel) {
        // Standard notification detail view
        let alert = UIAlertController(
            title: notification.title,
            message: notification.message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showToast(message: String) {
        let toastLabel = UILabel()
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont.systemFont(ofSize: 14)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        toastLabel.numberOfLines = 0
        
        view.addSubview(toastLabel)
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            toastLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            toastLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            toastLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            toastLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])
        
        UIView.animate(withDuration: 0.5, delay: 2.0, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: { _ in
            toastLabel.removeFromSuperview()
        })
    }
}

// MARK: - NotificationCell
class NotificationCell: UITableViewCell {
    
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()
    private let readIndicator = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        selectionStyle = .none
        
        // Container View
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 10
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowOffset = CGSize(width: 0, height: 1)
        containerView.layer.shadowRadius = 3
        
        // Title Label
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.numberOfLines = 0
        
        // Message Label
        messageLabel.font = UIFont.systemFont(ofSize: 14)
        messageLabel.textColor = .darkGray
        messageLabel.numberOfLines = 2
        
        // Time Label
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textColor = .lightGray
        timeLabel.textAlignment = .right
        
        // Read Indicator
        readIndicator.backgroundColor = .orange
        readIndicator.layer.cornerRadius = 5
        
        // Add subviews
        contentView.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(messageLabel)
        containerView.addSubview(timeLabel)
        containerView.addSubview(readIndicator)
        
        // Set constraints
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        readIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            readIndicator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            readIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            readIndicator.widthAnchor.constraint(equalToConstant: 10),
            readIndicator.heightAnchor.constraint(equalToConstant: 10),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: readIndicator.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            timeLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 8),
            timeLabel.leadingAnchor.constraint(equalTo: messageLabel.leadingAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: messageLabel.trailingAnchor),
            timeLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with notification: NotificationModel) {
        titleLabel.text = notification.title
        messageLabel.text = notification.message
        
        // Format the date
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        timeLabel.text = formatter.string(from: notification.date)
        
        // Update read indicator visibility
        readIndicator.isHidden = notification.isRead
        
        // Apply read/unread styling
        if notification.isRead {
            containerView.backgroundColor = .white
            titleLabel.textColor = .black
        } else {
            containerView.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
            titleLabel.textColor = .black
        }
    }
}
