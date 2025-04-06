import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Kingfisher

class GroupViewController: UIViewController {
    
    // Keep only one initializer
    init(groupId: String, groupName: String, members: [UserGroup.Member] = []) {
        self.groupId = groupId
        self.groupName = groupName
        self.members = members
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Properties
    private let groupId: String
    private let groupName: String
    private let db = Firestore.firestore()
    private let messageManager = GroupMessageManager()
    private let userGroupManager = UserGroupManager()
    private var groupImageURL: String?
    
    // Use a computed property to avoid override issues
    private var userCurrentId: String {
        return Auth.auth().currentUser?.uid ?? ""
    }
    
    private var messages: [UserGroup.Message] = []
    private var members: [UserGroup.Member] = []
    private var admins: [String] = []
    private var chatEnabled = true
    private var userCanChat = true
    private var groupDetails: [String: Any]?
    private var messageListener: ListenerRegistration?
    
    // MARK: - UI Components
    private let tableView = UITableView()
    private let groupMessageInputView = GroupMessageInputView()
    private var bottomConstraint: NSLayoutConstraint?
    private let headerView = UIView()
    private let groupImageView = UIImageView()
    private let groupNameLabel = UILabel()
    private let participantsLabel = UILabel()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotifications()
        loadGroupDetails()
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
        let titleTapGesture = UITapGestureRecognizer(target: self, action: #selector(showGroupDetails))
        let titleView = UILabel()
        titleView.text = groupName
        titleView.font = UIFont.boldSystemFont(ofSize: 18)
        titleView.isUserInteractionEnabled = true
        titleView.addGestureRecognizer(titleTapGesture)
        navigationItem.titleView = titleView
        
        // Add settings button (replacing the member management button)
        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(showGroupDetails)
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
        
        // Add tap gesture to header for group details
        let headerTapGesture = UITapGestureRecognizer(target: self, action: #selector(showGroupDetails))
        headerView.isUserInteractionEnabled = true
        headerView.addGestureRecognizer(headerTapGesture)
        
        // Group image - now will display actual group image
        groupImageView.contentMode = .scaleAspectFill
        groupImageView.clipsToBounds = true
        groupImageView.layer.cornerRadius = 30
        groupImageView.backgroundColor = .systemGray6
        groupImageView.image = UIImage(systemName: "person.3")
        groupImageView.tintColor = .systemGray3
        groupImageView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(groupImageView)
        
        // Add tap gesture to image for details
        groupImageView.isUserInteractionEnabled = true
        groupImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showGroupDetails)))
        
        // Group name label
        groupNameLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        groupNameLabel.text = groupName
        groupNameLabel.textAlignment = .center
        groupNameLabel.numberOfLines = 2
        groupNameLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(groupNameLabel)
        
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
            
            groupImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 12),
            groupImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            groupImageView.widthAnchor.constraint(equalToConstant: 60),
            groupImageView.heightAnchor.constraint(equalToConstant: 60),
            
            groupNameLabel.topAnchor.constraint(equalTo: groupImageView.bottomAnchor, constant: 8),
            groupNameLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            groupNameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            participantsLabel.topAnchor.constraint(equalTo: groupNameLabel.bottomAnchor, constant: 4),
            participantsLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            participantsLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            separatorLine.topAnchor.constraint(equalTo: participantsLabel.bottomAnchor, constant: 12),
            separatorLine.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5),
            separatorLine.bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
        ])
    }
    
    // Redirect old showMemberManagement to the new GroupDetails page
    @objc private func showMemberManagement() {
        showGroupDetails()
    }
    
    // Add new method to show group details
    @objc private func showGroupDetails() {
        let detailsVC = GroupDetailsViewController(
            groupId: groupId,
            groupName: groupName,
            imageURL: groupImageURL
        )
        navigationController?.pushViewController(detailsVC, animated: true)
    }
    
    
    
    private func setupTableView() {
        tableView.register(GroupMessageCell.self, forCellReuseIdentifier: GroupMessageCell.identifier)
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
        groupMessageInputView.translatesAutoresizingMaskIntoConstraints = false
        groupMessageInputView.delegate = self
        view.addSubview(groupMessageInputView)
        
        // Set initial constraints
        bottomConstraint = groupMessageInputView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        
        NSLayoutConstraint.activate([
            // Table view constraints
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: groupMessageInputView.topAnchor),
            
            // Message input view constraints
            groupMessageInputView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            groupMessageInputView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
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
            name: NSNotification.Name("GroupMessageImageTapped"),
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
    private func loadGroupDetails() {
        db.collection("groups").document(groupId).getDocument { [weak self] snapshot, error in
            guard let self = self, let data = snapshot?.data() else {
                print("Error fetching group details: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            self.groupDetails = data
            
            // Update UI with group details
            DispatchQueue.main.async {
                if let name = data["name"] as? String {
                    self.groupNameLabel.text = name
                    self.title = name
                }
                
                // Load group image if available
                if let imageURL = data["imageURL"] as? String, let url = URL(string: imageURL) {
                    self.groupImageURL = imageURL
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
        // If members were provided in initializer, use them
        if !members.isEmpty {
            self.admins = members.filter { $0.role == "admin" }.map { $0.userId }
            
            // Check if current user can chat
            if let currentMember = members.first(where: { $0.userId == self.userCurrentId }) {
                self.userCanChat = currentMember.canChat
            }
            
            // Update group settings
            self.loadGroupChatSettings()
            
            // Update UI
            DispatchQueue.main.async {
                self.updateParticipantLabel()
                self.updateMessageInputAccessibility()
            }
            return
        }
        userGroupManager.getGroupMembers(groupId: groupId) { [weak self] members in
            guard let self = self else { return }
            
            self.members = members
            self.admins = members.filter { $0.role == "admin" }.map { $0.userId }
            
            // Check if current user can chat
            if let currentMember = members.first(where: { $0.userId == self.userCurrentId }) {
                self.userCanChat = currentMember.canChat
            }
            
            // Update group settings
            self.loadGroupChatSettings()
            
            // Update UI
            DispatchQueue.main.async {
                self.updateParticipantLabel()
                self.updateMessageInputAccessibility()
            }
        }
    }
    
    private func loadGroupChatSettings() {
        db.collection("groups").document(groupId).getDocument { [weak self] snapshot, error in
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
        messageListener = messageManager.addMessageListener(groupId: groupId, limit: 100) { [weak self] messages in
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
        let adminCount = admins.count
        
        if memberCount == 0 {
            participantsLabel.text = "No participants"
        } else if memberCount == 1 {
            participantsLabel.text = "1 participant"
        } else {
            participantsLabel.text = "\(memberCount) participants • \(adminCount) admin\(adminCount != 1 ? "s" : "")"
        }
    }
    
    private func updateMessageInputAccessibility() {
        let canSendMessages = chatEnabled && userCanChat
        groupMessageInputView.isEnabled = canSendMessages
        
        if !canSendMessages {
            let reason: String
            if !chatEnabled {
                reason = "Chat has been disabled for this group"
            } else {
                reason = "You don't have permission to send messages"
            }
            groupMessageInputView.showDisabledState(with: reason)
        } else {
            groupMessageInputView.showEnabledState()
        }
    }
    
    // MARK: - Actions
    @objc private func titleTapped() {
        // Show group details or members list
        showGroupDetails()
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
        loadGroupDetails()
    }
    
    @objc private func handleImageTap(_ notification: Notification) {
        guard let cell = notification.object as? GroupMessageCell,
              let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        
        let message = messages[indexPath.row]
        if let imageURLString = message.imageURL, let imageURL = URL(string: imageURLString) {
            let fullScreenImageVC = GroupFullScreenImageViewController(imageURL: imageURL)
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
        let storageRef = Storage.storage().reference().child("group_messages/\(groupId)/\(filename)")
        
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
            groupId: groupId,
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
extension GroupViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: GroupMessageCell.identifier, for: indexPath) as! GroupMessageCell
        
        // Get the message, taking into account the transform
        let message = messages[indexPath.row]
        
        // Configure the cell
        cell.configure(with: message, admins: admins)
        
        // Transform the cell content to counteract the table view transform
        cell.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension GroupViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - GroupMessageInputViewDelegate
extension GroupViewController: GroupMessageInputViewDelegate {
    func didTapSend(text: String) {
        sendMessage(text: text)
    }
    
    func didTapAttachment() {
        selectImage()
    }
}

// MARK: - UIImagePickerControllerDelegate
extension GroupViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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
