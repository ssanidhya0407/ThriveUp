import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class EventGroupViewController: UIViewController {
    
    // MARK: - Properties
    private let eventId: String
    private let isOrganizer: Bool
    private let eventGroupManager = EventGroupManager()
    private var members: [EventGroupMember] = []
    private var messages: [EventGroupMessage] = []
    private var chatEnabled: Bool = true
    private let db = Firestore.firestore()
    private var eventDetails: [String: Any]? = nil // To store event details
    
    // Add this property to store organizer IDs
    private var organizerIds: [String] = []
    
    // UI Components
    private let tableView = UITableView()
    private let messageField = UITextField()
    private let sendButton = UIButton()
    private let attachImageButton = UIButton()
    private let noPermissionLabel = UILabel()
    private let settingsButton = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: nil, action: nil)
    private let eventTitleLabel = UILabel()  // To display event title
    
    // For image handling
    private var selectedImage: UIImage?
    private let imagePicker = UIImagePickerController()
    
    // MARK: - Initialization
    init(eventId: String, isOrganizer: Bool = false) {
        self.eventId = eventId
        self.isOrganizer = isOrganizer
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupImagePicker()
        loadGroupSettings()
        loadMembers()
        loadMessages()
        loadEventDetails()
        addMessageObserver()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .white
        title = "Event Group"
        
        // Setup event title label
        eventTitleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        eventTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        eventTitleLabel.isUserInteractionEnabled = true
        navigationItem.titleView = eventTitleLabel
        
        // Add tap gesture to event title label to navigate to GroupMemberVC
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(eventTitleTapped))
        eventTitleLabel.addGestureRecognizer(tapGesture)
        
        // Setup table view
        tableView.register(MessageCell.self, forCellReuseIdentifier: "MessageCell")
        tableView.register(MemberCell.self, forCellReuseIdentifier: "MemberCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        // Setup message input area
        let inputContainer = UIView()
        inputContainer.backgroundColor = .systemGray6
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputContainer)
        
        // Add image attachment button
        attachImageButton.setImage(UIImage(systemName: "photo"), for: .normal)
        attachImageButton.addTarget(self, action: #selector(attachImage), for: .touchUpInside)
        attachImageButton.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(attachImageButton)
        
        messageField.placeholder = "Type a message..."
        messageField.borderStyle = .roundedRect
        messageField.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(messageField)
        
        sendButton.setTitle("Send", for: .normal)
        sendButton.setTitleColor(.systemBlue, for: .normal)
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(sendButton)
        
        // Setup no permission label
        noPermissionLabel.text = "Chat is disabled"
        noPermissionLabel.textAlignment = .center
        noPermissionLabel.isHidden = true
        noPermissionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(noPermissionLabel)
        
        // Add settings button for organizers
        if isOrganizer {
            settingsButton.target = self
            settingsButton.action = #selector(showSettings)
            navigationItem.rightBarButtonItem = settingsButton
        }
        
        // Setup constraints
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor, constant: -8),
            
            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainer.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            inputContainer.heightAnchor.constraint(equalToConstant: 60),
            
            attachImageButton.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 8),
            attachImageButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            attachImageButton.widthAnchor.constraint(equalToConstant: 40),
            attachImageButton.heightAnchor.constraint(equalToConstant: 40),
            
            messageField.leadingAnchor.constraint(equalTo: attachImageButton.trailingAnchor, constant: 8),
            messageField.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            messageField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            
            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 60),
            
            noPermissionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noPermissionLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupImagePicker() {
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
    }
    
    private func loadEventDetails() {
        db.collection("events").document(eventId).getDocument { [weak self] (snapshot, error) in
            guard let self = self, let data = snapshot?.data() else {
                return
            }
            self.eventDetails = data
            self.eventTitleLabel.text = data["title"] as? String  // Display event title
        }
    }
    
    // MARK: - Data Loading
    private func loadGroupSettings() {
        db.collection("eventGroups").document(eventId)
            .getDocument { [weak self] (snapshot, error) in
                guard let self = self,
                      let data = snapshot?.data(),
                      let settings = data["settings"] as? [String: Any] else {
                    return
                }
                
                if let chatEnabled = settings["chatEnabled"] as? Bool {
                    self.chatEnabled = chatEnabled
                    self.updateChatUI()
                }
            }
    }
    
    // MARK: - Load Members
    private func loadMembers() {
        eventGroupManager.getGroupMembers(eventId: eventId) { [weak self] members in
            guard let self = self else { return }
            self.members = members
            
            // Extract organizer IDs
            self.organizerIds = members.filter { $0.role == "organizer" }.map { $0.userId }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    private func loadMessages() {
        eventGroupManager.getMessages(eventId: eventId) { [weak self] messages in
            guard let self = self else { return }
            self.messages = messages.sorted(by: { $0.timestamp < $1.timestamp })
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.scrollToLatestMessage()
            }
        }
    }
    
    private func addMessageObserver() {
        // Setup a real-time listener for new messages
        db.collection("eventGroups").document(eventId)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { [weak self] (snapshot, error) in
                guard let self = self, let documents = snapshot?.documentChanges else { return }
                
                var shouldScroll = false
                
                // Only process new messages
                for change in documents where change.type == .added {
                    let data = change.document.data()
                    
                    if let id = data["id"] as? String,
                       let userId = data["userId"] as? String,
                       let userName = data["userName"] as? String,
                       let timestamp = data["timestamp"] as? Timestamp,
                       !self.messages.contains(where: { $0.id == id }) {
                        
                        let newMessage = EventGroupMessage(
                            id: id,
                            userId: userId,
                            userName: userName,
                            text: data["text"] as? String,
                            timestamp: timestamp.dateValue(),
                            profileImageURL: data["profileImageURL"] as? String,
                            imageURL: data["imageURL"] as? String
                        )
                        
                        self.messages.append(newMessage)
                        shouldScroll = true
                    }
                }
                
                if shouldScroll {
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.scrollToLatestMessage()
                    }
                }
            }
    }
    
    private func scrollToLatestMessage() {
        guard !messages.isEmpty else { return }
        
        let lastIndex = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: lastIndex, at: .bottom, animated: true)
    }
    
    private func updateChatUI() {
        if !chatEnabled {
            messageField.isEnabled = false
            sendButton.isEnabled = false
            attachImageButton.isEnabled = false
            noPermissionLabel.isHidden = false
            noPermissionLabel.text = "Chat is disabled for this event"
        } else {
            checkCurrentUserChatPermission()
        }
    }
    
    private func checkCurrentUserChatPermission() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            messageField.isEnabled = false
            sendButton.isEnabled = false
            attachImageButton.isEnabled = false
            noPermissionLabel.isHidden = false
            noPermissionLabel.text = "You must be logged in to chat"
            return
        }
        
        if let currentMember = members.first(where: { $0.userId == currentUserId }) {
            messageField.isEnabled = currentMember.canChat
            sendButton.isEnabled = currentMember.canChat
            attachImageButton.isEnabled = currentMember.canChat
            noPermissionLabel.isHidden = currentMember.canChat
            if !currentMember.canChat {
                noPermissionLabel.text = "You don't have permission to chat"
            }
        }
    }
    
    // MARK: - Image Handling
    @objc private func attachImage() {
        present(imagePicker, animated: true)
    }
    
    private func uploadImage(image: UIImage, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            completion(nil)
            return
        }
        
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child("event_images/\(eventId)/\(UUID().uuidString).jpg")
        
        let uploadTask = imageRef.putData(imageData, metadata: nil) { (metadata, error) in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            imageRef.downloadURL { (url, error) in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let downloadURL = url else {
                    completion(nil)
                    return
                }
                
                completion(downloadURL.absoluteString)
            }
        }
        
        // Handle upload progress if needed
        uploadTask.observe(.progress) { snapshot in
            let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
            print("Upload is \(percentComplete)% complete")
        }
    }
    
    // MARK: - Actions
    @objc private func eventTitleTapped() {
        let groupMemberVC = GroupMemberVC(eventId: eventId)
        navigationController?.pushViewController(groupMemberVC, animated: true)
    }
    
    @objc private func sendMessage() {
        // Check if we have an image to send
        if let selectedImage = selectedImage {
            // Show loading indicator
            let activityIndicator = UIActivityIndicatorView(style: .medium)
            activityIndicator.center = view.center
            activityIndicator.startAnimating()
            view.addSubview(activityIndicator)
            
            // Upload the image first
            uploadImage(image: selectedImage) { [weak self] imageURL in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    activityIndicator.removeFromSuperview()
                }
                
                guard let imageURL = imageURL else {
                    self.showAlert(title: "Error", message: "Failed to upload image. Please try again.")
                    return
                }
                
                // Get text message (if any)
                let messageText = self.messageField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Send message with image URL
                self.eventGroupManager.sendMessage(eventId: self.eventId, text: messageText, imageURL: imageURL) { success in
                    if success {
                        DispatchQueue.main.async {
                            self.messageField.text = ""
                            self.selectedImage = nil
                        }
                    } else {
                        self.showAlert(title: "Error", message: "Failed to send message. Please try again.")
                    }
                }
            }
        } else {
            // Send text-only message
            guard let messageText = messageField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !messageText.isEmpty else { return }
            
            eventGroupManager.sendMessage(eventId: eventId, text: messageText) { [weak self] success in
                if success {
                    DispatchQueue.main.async {
                        self?.messageField.text = ""
                    }
                } else {
                    self?.showAlert(title: "Error", message: "Failed to send message. Please try again.")
                }
            }
        }
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
    
    @objc private func showSettings() {
        let actionSheet = UIAlertController(
            title: "Event Group Settings",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        actionSheet.addAction(UIAlertAction(title: "Manage Members", style: .default) { [weak self] _ in
            self?.showMemberManagement()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Toggle Chat", style: .default) { [weak self] _ in
            self?.toggleGroupChat()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(actionSheet, animated: true)
    }
    
    private func toggleGroupChat() {
        // Toggle the chat setting
        let newChatEnabled = !chatEnabled
        
        eventGroupManager.updateGroupChatSettings(eventId: eventId, chatEnabled: newChatEnabled) { [weak self] success in
            guard let self = self else { return }
            
            if success {
                self.chatEnabled = newChatEnabled
                self.updateChatUI()
                
                let message = newChatEnabled ? "Chat has been enabled" : "Chat has been disabled"
                self.showAlert(title: "Settings Updated", message: message)
            } else {
                self.showAlert(title: "Error", message: "Failed to update chat settings.")
            }
        }
    }
    
    private func showMemberManagement() {
        let groupMemberVC = GroupMemberVC(eventId: eventId)
        navigationController?.pushViewController(groupMemberVC, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension EventGroupViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
        let message = messages[indexPath.row]
        
        // Pass the organizer IDs to the cell configuration
        cell.configure(with: message, organizers: organizerIds)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension EventGroupViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Handle cell selection if needed
    }
}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate
extension EventGroupViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let editedImage = info[.editedImage] as? UIImage {
            selectedImage = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            selectedImage = originalImage
        }
        
        // Update the UI to show selected image (if needed)
        // For example, you could add a preview view or change the attachment button appearance
        if selectedImage != nil {
            attachImageButton.tintColor = .systemBlue
        }
        
        dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}
