import UIKit
import FirebaseStorage
import FirebaseAuth
import FirebaseFirestore
import AVFoundation
import Kingfisher

protocol ChatDetailViewControllerDelegate: AnyObject {
    func didSendMessage(_ message: ChatMessage, to friend: User)
}

class ChatDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UIDocumentPickerDelegate, UINavigationControllerDelegate {
    // MARK: - Properties
    var chatThread: ChatThread?
    var group: Group?
    var isGroupChat = false
    private var db = Firestore.firestore()
    private var messagesListener: ListenerRegistration?
    private let currentUserID = Auth.auth().currentUser?.uid ?? ""
    weak var delegate: ChatDetailViewControllerDelegate?
    private let chatManager = FirestoreChatManager()
    
    // MARK: - UI Components
    private let tableView = UITableView()
    private let messageInputView = MessageInputView()
    private var bottomConstraint: NSLayoutConstraint?
    private let headerView = UIView()
    private let chatImageView = UIImageView()
    private let chatTitleLabel = UILabel()
    private let participantsLabel = UILabel()
    
    // MARK: - Audio Recording
    private var audioRecorder: AVAudioRecorder?
    private var audioFileURL: URL?
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupUI()
        setupKeyboardHandling()
        setupNotifications()
        
        if isGroupChat {
            fetchGroupParticipants()
        } else {
            fetchMessages()
        }
        
        // Custom back button
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.leftBarButtonItem = backButton
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let chatThread = chatThread,
           let lastMessage = chatThread.messages.last,
           let participant = chatThread.participants.first(where: { $0.id != currentUserID }) {
            delegate?.didSendMessage(lastMessage, to: participant)
        }
    }
    
    deinit {
        messagesListener?.remove()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // Set up navigation title with tap gesture
        let titleTapGesture = UITapGestureRecognizer(target: self, action: #selector(showChatDetails))
        let titleView = UILabel()
        
        if isGroupChat, let group = group {
            titleView.text = group.name
        } else if let participant = chatThread?.participants.first(where: { $0.id != currentUserID }) {
            titleView.text = participant.name
        } else {
            titleView.text = "Chat"
        }
        
        titleView.font = UIFont.boldSystemFont(ofSize: 18)
        titleView.isUserInteractionEnabled = true
        titleView.addGestureRecognizer(titleTapGesture)
        navigationItem.titleView = titleView
        
        // Add settings button for chat options
        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(showChatDetails)
        )
        navigationItem.rightBarButtonItem = settingsButton
        
        // Setup header view (similar to EventGroupViewController)
        setupHeaderView()
        
        // Setup table view for messages
        setupTableView()
        
        // Setup message input view
        setupMessageInputView()
    }
    
    private func setupHeaderView() {
        headerView.backgroundColor = .systemBackground
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        
        // Add tap gesture to header for chat details
        let headerTapGesture = UITapGestureRecognizer(target: self, action: #selector(showChatDetails))
        headerView.isUserInteractionEnabled = true
        headerView.addGestureRecognizer(headerTapGesture)
        
        // Chat image - display profile or group image
        chatImageView.contentMode = .scaleAspectFill
        chatImageView.clipsToBounds = true
        chatImageView.layer.cornerRadius = 30
        chatImageView.backgroundColor = .systemGray6
        
        if isGroupChat {
            chatImageView.image = UIImage(systemName: "person.3")
        } else {
            chatImageView.image = UIImage(systemName: "person")
        }
        
        chatImageView.tintColor = .systemGray3
        chatImageView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(chatImageView)
        
        // Add tap gesture to image for details
        chatImageView.isUserInteractionEnabled = true
        chatImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showChatDetails)))
        
        // Chat title label
        chatTitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        
        if isGroupChat, let group = group {
            chatTitleLabel.text = group.name
        } else if let participant = chatThread?.participants.first(where: { $0.id != currentUserID }) {
            chatTitleLabel.text = participant.name
        }
        
        chatTitleLabel.textAlignment = .center
        chatTitleLabel.numberOfLines = 2
        chatTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(chatTitleLabel)
        
        // Participants label
        participantsLabel.font = UIFont.systemFont(ofSize: 14)
        participantsLabel.textColor = .secondaryLabel
        participantsLabel.textAlignment = .center
        participantsLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(participantsLabel)
        
        // Update participants label text
        if isGroupChat, let group = group {
            participantsLabel.text = "\(group.members.count) participants"
        } else {
            participantsLabel.text = "Direct message"
        }
        
        // Add a separator line
        let separatorLine = UIView()
        separatorLine.backgroundColor = .systemGray5
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(separatorLine)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            chatImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 12),
            chatImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            chatImageView.widthAnchor.constraint(equalToConstant: 60),
            chatImageView.heightAnchor.constraint(equalToConstant: 60),
            
            chatTitleLabel.topAnchor.constraint(equalTo: chatImageView.bottomAnchor, constant: 8),
            chatTitleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            chatTitleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            participantsLabel.topAnchor.constraint(equalTo: chatTitleLabel.bottomAnchor, constant: 4),
            participantsLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            participantsLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            separatorLine.topAnchor.constraint(equalTo: participantsLabel.bottomAnchor, constant: 12),
            separatorLine.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5),
            separatorLine.bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
        ])
        
        // Load profile image for direct message
        if !isGroupChat, let participant = chatThread?.participants.first(where: { $0.id != currentUserID }),
           let imageURL = participant.profileImageURL, let url = URL(string: imageURL) {
            chatImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "person"),
                options: [.transition(.fade(0.3))]
            )
        }
        
        // Load group image for group chat
        if isGroupChat, let group = self.group, let imageURL = group.imageURL, let url = URL(string: imageURL) {
            chatImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "person.3"),
                options: [.transition(.fade(0.3))]
            )
        }
    }
    
    private func setupTableView() {
        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: "ChatMessageCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.keyboardDismissMode = .interactive
        
        // Use inverted table like EventGroupViewController for better UX
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
        
        view.addSubview(tableView)
    }
    
    private func setupMessageInputView() {
        messageInputView.translatesAutoresizingMaskIntoConstraints = false
        messageInputView.delegate = self
        view.addSubview(messageInputView)
        
        // Set initial constraint
        bottomConstraint = messageInputView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        
        NSLayoutConstraint.activate([
            // Table view constraints
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: messageInputView.topAnchor),
            
            // Message input view constraints
            messageInputView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messageInputView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
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
            name: NSNotification.Name("ChatMessageImageTapped"),
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
    private func fetchMessages() {
        guard let chatThread = chatThread else {
            print("Error: chatThread is nil")
            return
        }

        let messagesRef = db.collection("chats").document(chatThread.id).collection("messages")

        messagesListener?.remove()
        messagesListener = messagesRef
            .order(by: "timestamp", descending: true)  // Changed to descending for inverted table
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error fetching messages: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("No messages found")
                    return
                }

                var newMessages: [ChatMessage] = []
                for doc in documents {
                    let data = doc.data()
                    let id = doc.documentID
                    let senderID = data["senderId"] as? String ?? ""
                    let messageContent = data["messageContent"] as? String ?? ""
                    let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    let mediaURL = data["mediaURL"] as? String ?? ""

                    let sender = self.chatThread?.participants.first(where: { $0.id == senderID }) ?? User(id: senderID, name: "Unknown")
                    let message = ChatMessage(id: id, sender: sender, messageContent: messageContent, timestamp: timestamp, isSender: senderID == self.currentUserID, mediaURL: mediaURL)
                    newMessages.append(message)
                }

                self.chatThread?.messages = newMessages
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    
                    // No need to manually scroll as the inverted table handles this naturally
                    if self.tableView.contentOffset.y <= 0 && !newMessages.isEmpty {
                        self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
                    }
                }
            }
    }
    
    private func fetchGroupParticipants() {
        guard let group = group else { return }
        
        let dispatchGroup = DispatchGroup()
        var fetchedParticipants: [User] = []

        for memberID in group.members {
            dispatchGroup.enter()
            db.collection("users").document(memberID).getDocument { snapshot, error in
                if let error = error {
                    print("Error fetching participant \(memberID): \(error.localizedDescription)")
                } else if let data = snapshot?.data(),
                          let name = data["name"] as? String,
                          let profileImageURL = data["profileImageURL"] as? String {

                    let user = User(id: memberID, name: name, profileImageURL: profileImageURL)
                    fetchedParticipants.append(user)
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            self.chatThread = ChatThread(id: group.id, participants: fetchedParticipants, messages: [])
            print("Group Participants Loaded: \(fetchedParticipants.map { $0.name })")
            
            // Update participants label
            self.participantsLabel.text = "\(fetchedParticipants.count) participants"
            
            self.fetchMessages()
        }
    }
    
    // MARK: - Actions and Event Handlers
    @objc private func backButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func showChatDetails() {
        let title: String
        let id: String
        let participants: [User]
        
        if isGroupChat, let group = group {
            title = group.name
            id = group.id
            participants = chatThread?.participants ?? []
        } else if let chatThread = chatThread {
            title = chatThread.participants.first(where: { $0.id != currentUserID })?.name ?? "Chat"
            id = chatThread.id
            participants = chatThread.participants
        } else {
            return
        }
        
        // Print debug info
        print("Show details for chat: \(id) - \(title)")
        
        // Create and navigate to chat details view controller
        let detailsVC = ChatDetailsViewController(
            chatId: id,
            chatTitle: title,
            isGroup: isGroupChat,
            participants: participants
        )
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
        if isGroupChat {
            fetchGroupParticipants()
        } else {
            fetchMessages()
        }
    }
    
    @objc private func handleImageTap(_ notification: Notification) {
        guard let cell = notification.object as? ChatMessageCell,
              let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        
        let message = chatThread?.messages[indexPath.row]
        if let imageURLString = message?.mediaURL, let imageURL = URL(string: imageURLString) {
            // Present full screen image viewer
            let fullScreenImageVC = FullScreenImageViewController(imageURL: imageURL)
            present(fullScreenImageVC, animated: true)
        }
    }
    
    // MARK: - Media Handling
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage {
            uploadMediaToFirebase(image: image)
        } else if let videoURL = info[.mediaURL] as? URL {
            uploadMediaToFirebase(videoURL: videoURL)
        }
        picker.dismiss(animated: true)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let fileURL = urls.first {
            uploadMediaToFirebase(documentURL: fileURL)
        }
    }
    
    private func uploadMediaToFirebase(image: UIImage? = nil, videoURL: URL? = nil, documentURL: URL? = nil, audioURL: URL? = nil) {
        // Show loading indicator
        let alert = UIAlertController(title: "Uploading...", message: "Please wait", preferredStyle: .alert)
        present(alert, animated: true)
        
        let storageRef = Storage.storage().reference()
        var uploadRef: StorageReference?

        if let image = image {
            uploadRef = storageRef.child("images/\(UUID().uuidString).jpg")
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                uploadRef?.putData(imageData, metadata: nil) { _, error in
                    if error == nil {
                        uploadRef?.downloadURL { url, _ in
                            if let url = url {
                                self.sendMessage(content: "📷 Sent a photo", mediaURL: url.absoluteString)
                                DispatchQueue.main.async {
                                    alert.dismiss(animated: true)
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            alert.dismiss(animated: true)
                            self.showErrorAlert(message: "Upload failed: \(error?.localizedDescription ?? "Unknown error")")
                        }
                    }
                }
            }
        } else if let videoURL = videoURL {
            uploadRef = storageRef.child("videos/\(UUID().uuidString).mov")
            uploadRef?.putFile(from: videoURL, metadata: nil) { _, error in
                if error == nil {
                    uploadRef?.downloadURL { url, _ in
                        if let url = url {
                            self.sendMessage(content: "🎬 Sent a video", mediaURL: url.absoluteString)
                            DispatchQueue.main.async {
                                alert.dismiss(animated: true)
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        alert.dismiss(animated: true)
                        self.showErrorAlert(message: "Upload failed: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        } else if let audioURL = audioURL {
            uploadRef = storageRef.child("audio/\(UUID().uuidString).m4a")
            uploadRef?.putFile(from: audioURL, metadata: nil) { _, error in
                if error == nil {
                    uploadRef?.downloadURL { url, _ in
                        if let url = url {
                            self.sendMessage(content: "🎤 Voice message", mediaURL: url.absoluteString)
                            DispatchQueue.main.async {
                                alert.dismiss(animated: true)
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        alert.dismiss(animated: true)
                        self.showErrorAlert(message: "Upload failed: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        } else if let documentURL = documentURL {
            uploadRef = storageRef.child("documents/\(UUID().uuidString).\(documentURL.pathExtension)")
            uploadRef?.putFile(from: documentURL, metadata: nil) { _, error in
                if error == nil {
                    uploadRef?.downloadURL { url, _ in
                        if let url = url {
                            let docType = documentURL.pathExtension.uppercased()
                            self.sendMessage(content: "📄 Sent a \(docType) document", mediaURL: url.absoluteString)
                            DispatchQueue.main.async {
                                alert.dismiss(animated: true)
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        alert.dismiss(animated: true)
                        self.showErrorAlert(message: "Upload failed: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        }
    }
    
    private func handleVoiceRecording() {
        let filename = UUID().uuidString + ".m4a"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        audioFileURL = path
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: path, settings: settings)
            audioRecorder?.record()
            
            // Show recording indicator
            messageInputView.showRecordingState()
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
            showErrorAlert(message: "Failed to start recording")
        }
    }
    
    internal func stopVoiceRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        
        // Reset input view
        messageInputView.showNormalState()
        
        if let fileURL = audioFileURL {
            uploadMediaToFirebase(audioURL: fileURL)
        }
    }
    
    private func presentMediaPicker() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.mediaTypes = ["public.image", "public.movie"]
        present(picker, animated: true)
    }
    
    private func presentDocumentPicker() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .text, .plainText])
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func presentCamera() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
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
    
    private func sendMessage(content: String, mediaURL: String? = nil) {
        guard let currentUser = Auth.auth().currentUser else {
            print("ERROR: No authenticated user found.")
            return
        }

        let messageData: [String: Any] = [
            "id": UUID().uuidString,
            "senderId": currentUser.uid,
            "messageContent": content,
            "timestamp": FieldValue.serverTimestamp(),
            "mediaURL": mediaURL ?? ""
        ]

        if isGroupChat, let group = group {
            print("Storing Group Message in /chats/\(group.id)/messages")
            
            let groupRef = db.collection("chats").document(group.id)
            let messagesRef = groupRef.collection("messages")

            messagesRef.addDocument(data: messageData) { error in
                if let error = error {
                    print("Firestore Error Storing Group Message: \(error.localizedDescription)")
                    self.showErrorAlert(message: "Failed to send message")
                } else {
                    // Update Last Message for Group
                    groupRef.setData(["lastMessage": content, "lastUpdated": FieldValue.serverTimestamp()], merge: true)
                    
                    // Clear input field
                    self.messageInputView.clearInput()
                }
            }
            
        } else if let chatThread = chatThread {
            print("Storing Private Chat Message in /chats/\(chatThread.id)/messages")
            
            let chatRef = db.collection("chats").document(chatThread.id)
            let messagesRef = chatRef.collection("messages")

            messagesRef.addDocument(data: messageData) { error in
                if let error = error {
                    print("Firestore Error Storing Private Message: \(error.localizedDescription)")
                    self.showErrorAlert(message: "Failed to send message")
                } else {
                    // Update Last Message for Private Chat
                    chatRef.setData(["lastMessage": content, "lastUpdated": FieldValue.serverTimestamp()], merge: true)
                    
                    // Clear input field
                    self.messageInputView.clearInput()
                    
                    // Update delegate
                    if let friend = chatThread.participants.first(where: { $0.id != self.currentUserID }),
                       let lastMessage = chatThread.messages.first {
                        self.delegate?.didSendMessage(lastMessage, to: friend)
                    }
                }
            }
        } else {
            print("ERROR: No valid chat reference (group and chatThread both nil)")
        }
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatThread?.messages.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatMessageCell", for: indexPath) as! ChatMessageCell
        
        if let message = chatThread?.messages[indexPath.row] {
            // Configure the cell
            cell.configure(with: message)
            
            // Transform the cell content to counteract the table view transform
            cell.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
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

// MARK: - MessageInputViewDelegate Protocol
protocol MessageInputViewDelegate: AnyObject {
    func didTapSend(text: String)
    func didTapAttachment()
    func didTapCamera()
    func startVoiceRecording()
    func stopVoiceRecording()
}

// MARK: - MessageInputView Implementation
class MessageInputView: UIView {
    // UI Components
    private let inputTextField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let attachmentButton = UIButton(type: .system)
    private let cameraButton = UIButton(type: .system)
    private let voiceButton = UIButton(type: .system)
    private let recordingIndicator = UIView()
    private let recordingLabel = UILabel()
    
    // Delegate
    weak var delegate: MessageInputViewDelegate?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .systemBackground
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.systemGray5.cgColor
        
        // Setup input text field
        inputTextField.placeholder = "Type a message"
        inputTextField.font = UIFont.systemFont(ofSize: 16)
        inputTextField.borderStyle = .roundedRect
        inputTextField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(inputTextField)
        
        // Setup send button
        sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        sendButton.tintColor = .systemBlue
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        addSubview(sendButton)
        
        // Setup attachment button
        attachmentButton.setImage(UIImage(systemName: "paperclip"), for: .normal)
        attachmentButton.tintColor = .darkGray
        attachmentButton.translatesAutoresizingMaskIntoConstraints = false
        attachmentButton.addTarget(self, action: #selector(attachmentTapped), for: .touchUpInside)
        addSubview(attachmentButton)
        
        // Setup camera button
        cameraButton.setImage(UIImage(systemName: "camera.fill"), for: .normal)
        cameraButton.tintColor = .darkGray
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        cameraButton.addTarget(self, action: #selector(cameraTapped), for: .touchUpInside)
        addSubview(cameraButton)
        
        // Setup voice button
        voiceButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        voiceButton.tintColor = .darkGray
        voiceButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add gesture recognizers for voice recording
        let touchDown = UILongPressGestureRecognizer(target: self, action: #selector(voiceButtonTouchDown(_:)))
        touchDown.minimumPressDuration = 0.3
        voiceButton.addGestureRecognizer(touchDown)
        
        addSubview(voiceButton)
        
        // Setup recording indicator (hidden by default)
        recordingIndicator.backgroundColor = UIColor.systemRed.withAlphaComponent(0.2)
        recordingIndicator.layer.cornerRadius = 8
        recordingIndicator.isHidden = true
        recordingIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(recordingIndicator)
        
        recordingLabel.text = "Recording... (release to send)"
        recordingLabel.font = UIFont.systemFont(ofSize: 14)
        recordingLabel.textColor = .systemRed
        recordingLabel.translatesAutoresizingMaskIntoConstraints = false
        recordingIndicator.addSubview(recordingLabel)
        
        // Set constraints
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 60),
            
            attachmentButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            attachmentButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            attachmentButton.widthAnchor.constraint(equalToConstant: 30),
            attachmentButton.heightAnchor.constraint(equalToConstant: 30),
            
            cameraButton.leadingAnchor.constraint(equalTo: attachmentButton.trailingAnchor, constant: 8),
            cameraButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            cameraButton.widthAnchor.constraint(equalToConstant: 30),
            cameraButton.heightAnchor.constraint(equalToConstant: 30),
            
            inputTextField.leadingAnchor.constraint(equalTo: cameraButton.trailingAnchor, constant: 8),
            inputTextField.centerYAnchor.constraint(equalTo: centerYAnchor),
            inputTextField.heightAnchor.constraint(equalToConstant: 40),
            
            voiceButton.leadingAnchor.constraint(equalTo: inputTextField.trailingAnchor, constant: 8),
            voiceButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            voiceButton.widthAnchor.constraint(equalToConstant: 30),
            voiceButton.heightAnchor.constraint(equalToConstant: 30),
            
            sendButton.leadingAnchor.constraint(equalTo: voiceButton.trailingAnchor, constant: 8),
            sendButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            sendButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 30),
            sendButton.heightAnchor.constraint(equalToConstant: 30),
            
            recordingIndicator.leadingAnchor.constraint(equalTo: cameraButton.trailingAnchor, constant: 8),
            recordingIndicator.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            recordingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            recordingIndicator.heightAnchor.constraint(equalToConstant: 40),
            
            recordingLabel.centerYAnchor.constraint(equalTo: recordingIndicator.centerYAnchor),
            recordingLabel.centerXAnchor.constraint(equalTo: recordingIndicator.centerXAnchor)
        ])
    }
    
    // MARK: - Button Actions
    @objc private func sendTapped() {
        guard let text = inputTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return
        }
        delegate?.didTapSend(text: text)
        clearInput()
    }
    
    @objc private func attachmentTapped() {
        delegate?.didTapAttachment()
    }
    
    @objc private func cameraTapped() {
        delegate?.didTapCamera()
    }
    
    @objc private func voiceButtonTouchDown(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            delegate?.startVoiceRecording()
        } else if gesture.state == .ended || gesture.state == .cancelled {
            delegate?.stopVoiceRecording()
        }
    }
    
    // MARK: - Public Methods
    func clearInput() {
        inputTextField.text = ""
    }
    
    func showRecordingState() {
        inputTextField.isHidden = true
        recordingIndicator.isHidden = false
    }
    
    func showNormalState() {
        inputTextField.isHidden = false
        recordingIndicator.isHidden = true
    }
}

// MARK: - MessageInputViewDelegate Extension
extension ChatDetailViewController: MessageInputViewDelegate {
    func didTapSend(text: String) {
        sendMessage(content: text)
    }
    
    func didTapAttachment() {
        let actionSheet = UIAlertController(title: "Attach", message: "Choose an attachment type", preferredStyle: .actionSheet)

        actionSheet.addAction(UIAlertAction(title: "Photo & Video", style: .default, handler: { _ in
            self.presentMediaPicker()
        }))

        actionSheet.addAction(UIAlertAction(title: "Document", style: .default, handler: { _ in
            self.presentDocumentPicker()
        }))

        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(actionSheet, animated: true, completion: nil)
    }
    
    func didTapCamera() {
        presentCamera()
    }
    
    func startVoiceRecording() {
        handleVoiceRecording()
    }
}
