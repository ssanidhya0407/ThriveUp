import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Kingfisher

class EventGroupViewController: UIViewController {
    
    // MARK: - Initialization
    init(eventId: String, eventName: String, members: [EventGroup.Member] = []) {
        self.eventId = eventId
        self.eventName = eventName
        self.members = members
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Properties
    private let eventId: String
    private let eventName: String
    private let db = Firestore.firestore()
    private let messageManager = EventMessageManager()
    private let eventGroupManager = EventGroupManager()
    private var eventImageURL: String?
    
    // Use a computed property to avoid override issues
    private var userCurrentId: String {
        return Auth.auth().currentUser?.uid ?? ""
    }
    
    private var messages: [EventGroup.Message] = []
    private var members: [EventGroup.Member] = []
    private var organizers: [String] = []
    private var chatEnabled = true
    private var userCanChat = true
    private var eventDetails: [String: Any]?
    private var messageListener: ListenerRegistration?
    
    // MARK: - UI Components
    private let tableView = UITableView()
    private let eventMessageInputView = EventMessageInputView()
    private var bottomConstraint: NSLayoutConstraint?
    private let headerView = UIView()
    private let eventImageView = UIImageView()
    private let eventNameLabel = UILabel()
    private let participantsLabel = UILabel()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotifications()
        loadEventDetails()
        loadMembers()
        setupMessageListener()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh members on appearance
        loadMembers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        messageListener?.remove()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Set up navigation title with tap gesture
        let titleTapGesture = UITapGestureRecognizer(target: self, action: #selector(showEventDetails))
        let titleView = UILabel()
        titleView.text = eventName
        titleView.font = UIFont.boldSystemFont(ofSize: 18)
        titleView.isUserInteractionEnabled = true
        titleView.addGestureRecognizer(titleTapGesture)
        navigationItem.titleView = titleView
        
        // Add settings button instead of member management button
        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(showEventDetails)
        )
        navigationItem.rightBarButtonItem = settingsButton
        
        // Setup header view
        setupHeaderView()
        
        // Setup table view for messages
        setupTableView()
        
        // Setup message input view
        setupMessageInputView()
        
        // Setup keyboard handling
        setupKeyboardHandling()
    }
    
    private func setupHeaderView() {
        headerView.backgroundColor = .systemBackground
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        
        // Add tap gesture to header for event details
        let headerTapGesture = UITapGestureRecognizer(target: self, action: #selector(showEventDetails))
        headerView.isUserInteractionEnabled = true
        headerView.addGestureRecognizer(headerTapGesture)
        
        // Event image - display actual event image
        eventImageView.contentMode = .scaleAspectFill
        eventImageView.clipsToBounds = true
        eventImageView.layer.cornerRadius = 30
        eventImageView.backgroundColor = .systemGray6
        eventImageView.image = UIImage(systemName: "calendar")
        eventImageView.tintColor = .systemGray3
        eventImageView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(eventImageView)
        
        // Add tap gesture to image for details
        eventImageView.isUserInteractionEnabled = true
        eventImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showEventDetails)))
        
        // Event name label
        eventNameLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        eventNameLabel.text = eventName
        eventNameLabel.textAlignment = .center
        eventNameLabel.numberOfLines = 2
        eventNameLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(eventNameLabel)
        
        // Participants label
        participantsLabel.font = UIFont.systemFont(ofSize: 14)
        participantsLabel.textColor = .secondaryLabel
        participantsLabel.textAlignment = .center
        participantsLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(participantsLabel)
        
        // Add a separator line
        let separatorLine = UIView()
        separatorLine.backgroundColor = .systemGray5
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(separatorLine)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            eventImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 12),
            eventImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            eventImageView.widthAnchor.constraint(equalToConstant: 60),
            eventImageView.heightAnchor.constraint(equalToConstant: 60),
            
            eventNameLabel.topAnchor.constraint(equalTo: eventImageView.bottomAnchor, constant: 8),
            eventNameLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            eventNameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            participantsLabel.topAnchor.constraint(equalTo: eventNameLabel.bottomAnchor, constant: 4),
            participantsLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            participantsLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            separatorLine.topAnchor.constraint(equalTo: participantsLabel.bottomAnchor, constant: 12),
            separatorLine.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5),
            separatorLine.bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.register(EventMessageCell.self, forCellReuseIdentifier: EventMessageCell.identifier)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = true
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.keyboardDismissMode = .interactive
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
        view.addSubview(tableView)
    }
    
    private func setupMessageInputView() {
        eventMessageInputView.translatesAutoresizingMaskIntoConstraints = false
        eventMessageInputView.delegate = self
        view.addSubview(eventMessageInputView)
        
        // Set initial constraints
        bottomConstraint = eventMessageInputView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        
        NSLayoutConstraint.activate([
            // Table view constraints
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: eventMessageInputView.topAnchor),
            
            // Message input view constraints
            eventMessageInputView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            eventMessageInputView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomConstraint!
        ])
    }
    
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        
        // Listen for image tap notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleImageTap(_:)),
            name: NSNotification.Name("EventMessageImageTapped"),
            object: nil
        )
    }
    
    private func setupNotifications() {
        // Set up notification observers for app lifecycle events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    // MARK: - Data Loading
    private func loadEventDetails() {
        db.collection("events").document(eventId).getDocument { [weak self] snapshot, error in
            guard let self = self, let data = snapshot?.data() else {
                print("Error fetching event details: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            self.eventDetails = data
            
            // Update UI with event details
            DispatchQueue.main.async {
                if let name = data["name"] as? String {
                    self.eventNameLabel.text = name
                    self.title = name
                }
                
                // Load event image if available
                if let imageURL = data["imageName"] as? String, let url = URL(string: imageURL) {
                    self.eventImageURL = imageURL
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
            
            self.members = members
            self.organizers = members.filter { $0.role == "organizer" }.map { $0.userId }
            
            // Check if current user can chat
            if let currentMember = members.first(where: { $0.userId == self.userCurrentId }) {
                self.userCanChat = currentMember.canChat
            }
            
            // Update event settings
            self.loadEventChatSettings()
            
            // Update UI
            DispatchQueue.main.async {
                self.updateParticipantLabel()
                self.updateMessageInputAccessibility()
            }
        }
    }
    
    private func loadEventChatSettings() {
        db.collection("eventGroups").document(eventId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let data = snapshot?.data(),
                  let settings = data["settings"] as? [String: Any] else {
                return
            }
            
            self.chatEnabled = settings["chatEnabled"] as? Bool ?? true
            
            // Update UI
            DispatchQueue.main.async {
                self.updateMessageInputAccessibility()
            }
        }
    }
    
    private func setupMessageListener() {
        // Remove any existing listener
        messageListener?.remove()
        
        // Set up a new listener for messages
        messageListener = messageManager.addMessageListener(eventId: eventId, limit: 100) { [weak self] messages in
            guard let self = self else { return }
            
            // Update the UI with the new messages
            DispatchQueue.main.async {
                self.messages = messages
                self.tableView.reloadData()
                
                // Scroll to bottom if user was at the bottom
                if self.tableView.contentOffset.y <= 0 && !self.messages.isEmpty {
                    self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                }
            }
        }
    }
    
    // MARK: - UI Updates
    private func updateParticipantLabel() {
        let memberCount = members.count
        let organizerCount = organizers.count
        
        if memberCount == 0 {
            participantsLabel.text = "No participants"
        } else if memberCount == 1 {
            participantsLabel.text = "1 participant"
        } else {
            participantsLabel.text = "\(memberCount) participants • \(organizerCount) organizer\(organizerCount != 1 ? "s" : "")"
        }
    }
    
    private func updateMessageInputAccessibility() {
        let canSendMessages = chatEnabled && userCanChat
        eventMessageInputView.isEnabled = canSendMessages
        
        if !canSendMessages {
            let reason: String
            if !chatEnabled {
                reason = "Chat has been disabled for this event"
            } else {
                reason = "You don't have permission to send messages"
            }
            eventMessageInputView.showDisabledState(with: reason)
        } else {
            eventMessageInputView.showEnabledState()
        }
    }
    
    // MARK: - Actions
    @objc private func showEventDetails() {
        let detailsVC = EventGroupDetailsViewController(eventId: eventId, eventName: title ?? "Event")
        navigationController?.pushViewController(detailsVC, animated: true)
    }
    
    @objc private func keyboardWillShow(notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let keyboardHeight = keyboardFrame.height
        
        // Update constraint
        bottomConstraint?.constant = -keyboardHeight
        
        // Animate the change
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(notification: Notification) {
        // Reset constraint
        bottomConstraint?.constant = 0
        
        // Animate the change
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func appWillEnterForeground() {
        // Refresh data when app comes back to foreground
        loadMembers()
        loadEventDetails()
    }
    
    @objc private func handleImageTap(_ notification: Notification) {
        guard let cell = notification.object as? EventMessageCell,
              let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        
        let message = messages[indexPath.row]
        if let imageURLString = message.imageURL, let imageURL = URL(string: imageURLString) {
            let fullScreenImageVC = EventFullScreenImageViewController(imageURL: imageURL)
            present(fullScreenImageVC, animated: true)
        }
    }
    
    // MARK: - Image Handling
    private func selectImage() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true)
    }
    
    private func uploadImage(image: UIImage) {
        // Show loading indicator
        let alert = UIAlertController(title: "Uploading...", message: "Please wait", preferredStyle: .alert)
        present(alert, animated: true)
        
        // Create image data
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            alert.dismiss(animated: true)
            showErrorAlert(message: "Failed to process image")
            return
        }
        
        // Create a unique filename
        let filename = UUID().uuidString + ".jpg"
        let storageRef = Storage.storage().reference().child("event_messages/\(eventId)/\(filename)")
        
        // Upload the image
        storageRef.putData(imageData, metadata: nil) { [weak self] metadata, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    alert.dismiss(animated: true)
                    self.showErrorAlert(message: "Upload failed: \(error.localizedDescription)")
                }
                return
            }
            
            // Get the download URL
            storageRef.downloadURL { url, error in
                DispatchQueue.main.async {
                    alert.dismiss(animated: true)
                    
                    if let error = error {
                        self.showErrorAlert(message: "Couldn't get download URL: \(error.localizedDescription)")
                        return
                    }
                    
                    if let downloadURL = url {
                        // Send message with image URL
                        self.sendMessage(text: nil, imageURL: downloadURL.absoluteString)
                    }
                }
            }
        }
    }
    
    private func sendMessage(text: String?, imageURL: String? = nil) {
        messageManager.sendMessage(
            eventId: eventId,
            userId: userCurrentId,
            text: text,
            imageURL: imageURL
        ) { success, errorMessage in
            if !success {
                DispatchQueue.main.async { [weak self] in
                    if let errorMessage = errorMessage {
                        self?.showErrorAlert(message: errorMessage)
                    } else {
                        self?.showErrorAlert(message: "Failed to send message. Please try again.")
                    }
                }
            }
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension EventGroupViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: EventMessageCell.identifier, for: indexPath) as! EventMessageCell
        
        // Get the message, taking into account the transform
        let message = messages[indexPath.row]
        
        // Configure the cell
        cell.configure(with: message, organizers: organizers)
        
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension EventGroupViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // UITableViewDelegate methods
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
}

// MARK: - EventMessageInputViewDelegate
extension EventGroupViewController: EventMessageInputViewDelegate {
    func didTapSend(text: String) {
        sendMessage(text: text)
    }
    
    func didTapAttachment() {
        selectImage()
    }
}

// MARK: - UIImagePickerControllerDelegate
extension EventGroupViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let selectedImage = info[.originalImage] as? UIImage {
            uploadImage(image: selectedImage)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// Required supporting classes for the implementation
class EventMessageManager {
    private let db = Firestore.firestore()
    
    func addMessageListener(eventId: String, limit: Int, completion: @escaping ([EventGroup.Message]) -> Void) -> ListenerRegistration {
        print("Setting up message listener for event: \(eventId) with limit: \(limit)")
        
        // Log the complete path to help with debugging
        let path = "eventGroups/\(eventId)/messages"
        print("Listening to path: \(path)")
        
        // Create a proper listener for event messages
        let messagesRef = db.collection("eventGroups").document(eventId).collection("messages")
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
        
        return messagesRef.addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching messages: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No message documents found")
                completion([])
                return
            }
            
            print("Received \(documents.count) message documents from Firebase")
            
            var messages: [EventGroup.Message] = []
            
            for (index, document) in documents.enumerated() {
                let data = document.data()
                print("Message \(index): \(data)")
                
                // Create message object with more flexible field handling
                let id = document.documentID
                let userId = data["userId"] as? String ?? "unknown"
                let userName = data["userName"] as? String ?? "Unknown User"
                
                // Handle timestamp variation
                let timestamp: Date
                if let ts = data["timestamp"] as? Timestamp {
                    timestamp = ts.dateValue()
                } else {
                    timestamp = Date()
                    print("Warning: No valid timestamp for message \(id)")
                }
                
                let message = EventGroup.Message(
                    id: id,
                    userId: userId,
                    userName: userName,
                    text: data["text"] as? String,
                    timestamp: timestamp,
                    profileImageURL: data["profileImageURL"] as? String,
                    imageURL: data["imageURL"] as? String
                )
                
                messages.append(message)
            }
            
            print("Processed \(messages.count) messages successfully")
            completion(messages)
        }
    }
    func sendMessage(eventId: String, userId: String, text: String?, imageURL: String?, completion: @escaping (Bool, String?) -> Void) {
        // First check if user has permission to send messages
        checkUserChatPermission(eventId: eventId, userId: userId) { [weak self] hasPermission in
            guard let self = self, hasPermission else {
                completion(false, "You don't have permission to send messages")
                return
            }
            
            // Get user information for the message
            self.getUserInfo(userId: userId) { userName, profileImageURL in
                // Create message data
                var messageData: [String: Any] = [
                    "userId": userId,
                    "userName": userName ?? "Unknown User",
                    "timestamp": Timestamp(date: Date())
                ]
                
                // Add profile image URL if available
                if let profileImageURL = profileImageURL {
                    messageData["profileImageURL"] = profileImageURL
                }
                
                // Add text or image URL
                if let text = text, !text.isEmpty {
                    messageData["text"] = text
                }
                
                if let imageURL = imageURL {
                    messageData["imageURL"] = imageURL
                }
                
                // Add to Firestore
                self.db.collection("eventGroups").document(eventId)
                    .collection("messages")
                    .addDocument(data: messageData) { error in
                        if let error = error {
                            print("Error sending message: \(error.localizedDescription)")
                            completion(false, error.localizedDescription)
                        } else {
                            completion(true, nil)
                        }
                    }
            }
        }
    }
    
    private func checkUserChatPermission(eventId: String, userId: String, completion: @escaping (Bool) -> Void) {
        // Check if chat is enabled for the event
        db.collection("eventGroups").document(eventId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let data = snapshot?.data(),
                  let settings = data["settings"] as? [String: Any] else {
                completion(false)
                return
            }
            
            // Check if chat is enabled for the event
            guard let chatEnabled = settings["chatEnabled"] as? Bool, chatEnabled else {
                completion(false)
                return
            }
            
            // Check if user has permission to chat
            self.db.collection("eventGroups").document(eventId)
                .collection("members").document(userId)
                .getDocument { document, error in
                    if let error = error {
                        print("Error checking user chat permission: \(error.localizedDescription)")
                        completion(false)
                        return
                    }
                    
                    guard let data = document?.data(),
                          let canChat = data["canChat"] as? Bool else {
                        completion(false)
                        return
                    }
                    
                    completion(canChat)
                }
        }
    }
    
    private func getUserInfo(userId: String, completion: @escaping (String?, String?) -> Void) {
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error fetching user info: \(error.localizedDescription)")
                completion(nil, nil)
                return
            }
            
            guard let data = document?.data() else {
                print("No user data found for ID: \(userId)")
                completion(nil, nil)
                return
            }
            
            // Try multiple possible field names for user name
            let name = data["displayName"] as? String ??
                       data["name"] as? String ??
                       data["fullName"] as? String ??
                       "Unknown User"
                       
            // Try multiple possible field names for profile image
            let profileImageURL = data["profileImageURL"] as? String ??
                                 data["photoURL"] as? String ??
                                 data["avatarURL"] as? String
            
            print("Found user: \(name) with ID: \(userId)")
            completion(name, profileImageURL)
        }
    }
}




class EventMessageCell: UITableViewCell {
    static let identifier = "EventMessageCell"
    
    // UI components
    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    private let nameLabel = UILabel()
    private let timeLabel = UILabel()
    private let messageImageView = UIImageView()
    private let profileImageView = UIImageView()
    
    // Constraints for dynamic adjustment
    private var bubbleTrailingConstraint: NSLayoutConstraint!
    private var bubbleLeadingConstraint: NSLayoutConstraint!
    private var bubbleWidthConstraint: NSLayoutConstraint!
    private var imageHeightConstraint: NSLayoutConstraint!
    
    // Initialization and setup
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.text = nil
        nameLabel.text = nil
        timeLabel.text = nil
        profileImageView.image = UIImage(systemName: "person.circle")
        messageImageView.image = nil
        messageImageView.isHidden = true
        messageLabel.isHidden = false
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        // Setup profile image
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 16
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileImageView)
        
        // Setup bubble view
        bubbleView.layer.cornerRadius = 12
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubbleView)
        
        // Setup name label
        nameLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        nameLabel.textColor = .secondaryLabel
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(nameLabel)
        
        // Setup message label
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(messageLabel)
        
        // Setup message image view - IMPROVED IMAGE SETUP
        messageImageView.contentMode = .scaleAspectFill
        messageImageView.clipsToBounds = true
        messageImageView.layer.cornerRadius = 8
        messageImageView.isHidden = true
        messageImageView.backgroundColor = .systemGray5 // Visual placeholder
        messageImageView.translatesAutoresizingMaskIntoConstraints = false
        messageImageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        messageImageView.addGestureRecognizer(tapGesture)
        bubbleView.addSubview(messageImageView)
        
        // Setup time label
        timeLabel.font = UIFont.systemFont(ofSize: 10)
        timeLabel.textColor = .tertiaryLabel
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(timeLabel)
        
        // Set up standard constraints
        NSLayoutConstraint.activate([
            // Profile image constraints
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            profileImageView.widthAnchor.constraint(equalToConstant: 32),
            profileImageView.heightAnchor.constraint(equalToConstant: 32),
            
            // Bubble view top/bottom constraints
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            // Name label constraints
            nameLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -8),
            
            // Message label constraints
            messageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 8),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -8),
            
            // Time label constraints
            timeLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 8),
            timeLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -8),
            timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -6),
            
            // Message image view constraints - IMPROVED
            messageImageView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            messageImageView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 8),
            messageImageView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -8),
        ])
        
        // Image height constraint - will be adjusted based on content
        imageHeightConstraint = messageImageView.heightAnchor.constraint(equalToConstant: 180)
        imageHeightConstraint.isActive = true
        
        // Connect image to time label
        NSLayoutConstraint.activate([
            timeLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 4)
        ])
        
        // Create dynamic constraints that will be modified during configuration
        bubbleLeadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 8)
        bubbleTrailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
        
        // Fixed width for the bubble
        let screenWidth = UIScreen.main.bounds.width
        let maxBubbleWidth = screenWidth * 0.65
        bubbleWidthConstraint = bubbleView.widthAnchor.constraint(equalToConstant: maxBubbleWidth)
    }
    
    @objc private func imageTapped() {
        NotificationCenter.default.post(
            name: NSNotification.Name("EventMessageImageTapped"),
            object: self
        )
    }
    
    func configure(with message: EventGroup.Message, organizers: [String]) {
        // Remember to counteract the table view's transformation
        contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
        
        // Configure labels with message data
        nameLabel.text = message.userName
        messageLabel.text = message.text
        
        // Format the timestamp
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        timeLabel.text = formatter.string(from: message.timestamp)
        
        // Set user image
        if let imageURL = message.profileImageURL, let url = URL(string: imageURL) {
            profileImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "person.circle")
            )
        } else {
            profileImageView.image = UIImage(systemName: "person.circle")
        }
        
        // Reset image and message visibility
        messageLabel.isHidden = false
        messageImageView.isHidden = true
        
        // IMPROVED IMAGE HANDLING
        if let imageURL = message.imageURL, let url = URL(string: imageURL) {
            // Show image, hide message text if there is no text
            messageImageView.isHidden = false
            
            if message.text == nil || message.text?.isEmpty == true {
                messageLabel.isHidden = true
                // Connect time label directly to image if no text
                timeLabel.topAnchor.constraint(equalTo: messageImageView.bottomAnchor, constant: 4).isActive = true
                // Make image larger when it's the only content
                imageHeightConstraint.constant = 200
            } else {
                messageLabel.isHidden = false
                // Make image smaller when there's also text
                imageHeightConstraint.constant = 150
            }
            
            // Load image with options
            messageImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "photo"),
                options: [
                    .transition(.fade(0.2)),
                    .processor(DownsamplingImageProcessor(size: CGSize(width: 300, height: 300))),
                    .scaleFactor(UIScreen.main.scale),
                    .cacheOriginalImage
                ],
                completionHandler: { result in
                    switch result {
                    case .success(let value):
                        print("Image loaded successfully: \(value.source.url?.absoluteString ?? "")")
                    case .failure(let error):
                        print("Image loading failed: \(error.localizedDescription)")
                        // Show error placeholder
                        self.messageImageView.image = UIImage(systemName: "exclamationmark.triangle")
                    }
                }
            )
        }
        
        // Remove all previous bubble constraints
        NSLayoutConstraint.deactivate([bubbleLeadingConstraint, bubbleTrailingConstraint, bubbleWidthConstraint])
        
        if message.userId == Auth.auth().currentUser?.uid {
            bubbleView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.9)
            messageLabel.textColor = .white
            nameLabel.textColor = UIColor.white.withAlphaComponent(0.8)
            timeLabel.textColor = UIColor.white.withAlphaComponent(0.6)
            profileImageView.isHidden = true
            
            // Right-align the bubble
            bubbleTrailingConstraint.isActive = true
            bubbleWidthConstraint.isActive = true
            timeLabel.textAlignment = .right
            
        } else {
            bubbleView.backgroundColor = UIColor.systemGray6
            messageLabel.textColor = .label
            nameLabel.textColor = .secondaryLabel
            timeLabel.textColor = .tertiaryLabel
            profileImageView.isHidden = false
            
            // Left-align the bubble
            bubbleLeadingConstraint.isActive = true
            bubbleWidthConstraint.isActive = true
            timeLabel.textAlignment = .left
        }
        
        // Highlight if sender is an organizer
        if organizers.contains(message.userId) {
            nameLabel.text = "\(message.userName) (Organizer)"
            nameLabel.textColor = message.userId == Auth.auth().currentUser?.uid ? .white : .systemOrange
        }
        
        // Force layout update
        setNeedsLayout()
    }
}

class EventFullScreenImageViewController: UIViewController {
    init(imageURL: URL) {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
