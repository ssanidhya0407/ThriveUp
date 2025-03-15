import UIKit
import FirebaseStorage
import FirebaseAuth
import FirebaseFirestore
import AVFoundation

protocol ChatDetailViewControllerDelegate: AnyObject {
    func didSendMessage(_ message: ChatMessage, to friend: User)
}
class ChatDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UIDocumentPickerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                // Upload Image to Firebase and Send as Message
                uploadMediaToFirebase(image: image)
            } else if let videoURL = info[.mediaURL] as? URL {
                // Upload Video to Firebase and Send as Message
                uploadMediaToFirebase(videoURL: videoURL)
            }
            picker.dismiss(animated: true)
        }
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
          if let fileURL = urls.first {
              // Upload Document to Firebase and Send as Message
              uploadMediaToFirebase(documentURL: fileURL)
          }
      }
    var chatThread: ChatThread? // Thread containing messages and participants
    var group: Group? // If it's a group chat
    var isGroupChat = false
    private var db = Firestore.firestore()
    private var messagesListener: ListenerRegistration?
    private let currentUserID = Auth.auth().currentUser?.uid ?? ""
    weak var delegate: ChatDetailViewControllerDelegate?
    private let chatManager = FirestoreChatManager()
    
    private let tableView = UITableView()
    private let messageInputBar = UIView()
    private let inputTextField = UITextField()
    private let sendButton = UIButton(type: .system)
    private var audioRecorder: AVAudioRecorder?
    private var audioFileURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        setupCustomTitleView()
        setupMessageInputComponents()
        setupTableView()
        if isGroupChat {
                fetchGroupParticipants() //  Fetch participants before loading messages
            } else {
                fetchMessages()
            }

        if let group = group {
            print(" Group Loaded: \(group.id), Members: \(group.members.count)")
        } else {
            print(" Error: Group is nil")
        }

        fetchMessages() // Make sure this function works for group chats.

        // Custom back button
        let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"),
                                         style: .plain,
                                         target: self,
                                         action: #selector(backButtonTapped))
        navigationItem.leftBarButtonItem = backButton
    }

    @objc private func backButtonTapped() {
        dismiss(animated: true, completion: nil)
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
        // Remove Firestore listener when the view controller is deallocated
        messagesListener?.remove()
    }
    
    private func setupCustomTitleView() {
        // Ensure participant exists
        guard let participant = chatThread?.participants.first(where: { $0.id != currentUserID }) else {
            print("No participant found other than the current user.")
            return
        }
        
        // Custom title view with profile image and name
        let titleView = UIStackView()
        titleView.axis = .horizontal
        titleView.alignment = .center
        titleView.spacing = 8
        
        let profileImageView = UIImageView()
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 20
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.image = participant.profileImage ?? UIImage(named: "placeholder")
        NSLayoutConstraint.activate([
            profileImageView.widthAnchor.constraint(equalToConstant: 40),
            profileImageView.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        let nameLabel = UILabel()
        nameLabel.text = participant.name
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        nameLabel.textColor = .black
        
        titleView.addArrangedSubview(profileImageView)
        titleView.addArrangedSubview(nameLabel)
        navigationItem.titleView = titleView
    }
    private func setupMessageInputComponents() {
        messageInputBar.backgroundColor = .white
        messageInputBar.layer.borderWidth = 0.5
        messageInputBar.layer.borderColor = UIColor.lightGray.cgColor
        view.addSubview(messageInputBar)

        messageInputBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            messageInputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messageInputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messageInputBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            messageInputBar.heightAnchor.constraint(equalToConstant: 50)
        ])

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        messageInputBar.addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: messageInputBar.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: messageInputBar.trailingAnchor, constant: -8),
            stackView.centerYAnchor.constraint(equalTo: messageInputBar.centerYAnchor),
            stackView.heightAnchor.constraint(equalTo: messageInputBar.heightAnchor, multiplier: 0.8)
        ])

        // 📎 Attachment Button
        let attachmentButton = UIButton(type: .system)
        attachmentButton.setImage(UIImage(systemName: "paperclip"), for: .normal)
        attachmentButton.tintColor = .darkGray
        attachmentButton.addTarget(self, action: #selector(handleAttachmentTapped), for: .touchUpInside)
        stackView.addArrangedSubview(attachmentButton)

        // 📷 Camera Button
        let cameraButton = UIButton(type: .system)
        cameraButton.setImage(UIImage(systemName: "camera.fill"), for: .normal)
        cameraButton.tintColor = .darkGray
        cameraButton.addTarget(self, action: #selector(openCamera), for: .touchUpInside)
        stackView.addArrangedSubview(cameraButton)

        // ✏️ Input Text Field
        inputTextField.placeholder = "Type a message"
        inputTextField.borderStyle = .roundedRect
        inputTextField.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(inputTextField)
        
        // 🎙️ Voice Message Button
        let voiceButton = UIButton(type: .system)
        voiceButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        voiceButton.tintColor = .darkGray
        voiceButton.addTarget(self, action: #selector(handleVoiceRecording), for: .touchDown)
        voiceButton.addTarget(self, action: #selector(stopVoiceRecording), for: .touchUpInside)
        stackView.addArrangedSubview(voiceButton)

        // 📩 Send Button
        sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        sendButton.tintColor = .systemBlue
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        stackView.addArrangedSubview(sendButton)
    }

    
    private func setupTableView() {
        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: "ChatMessageCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.backgroundColor = .white
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: messageInputBar.topAnchor)
        ])
    }
    
    @objc private func handleAttachmentTapped() {
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
    
    @objc private func openCamera() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    @objc private func handleVoiceRecording() {
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
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    @objc private func stopVoiceRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        
        if let fileURL = audioFileURL {
            uploadMediaToFirebase(audioURL: fileURL)
        }
    }


    private func uploadMediaToFirebase(image: UIImage? = nil, videoURL: URL? = nil, documentURL: URL? = nil, audioURL: URL? = nil) {
        let storageRef = Storage.storage().reference()
        var uploadRef: StorageReference?

        if let image = image {
            uploadRef = storageRef.child("images/\(UUID().uuidString).jpg")
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                uploadRef?.putData(imageData, metadata: nil) { _, error in
                    if error == nil {
                        uploadRef?.downloadURL { url, _ in
                            if let url = url {
//                                self.sendMessage(content: "[Image]", mediaURL: url.absoluteString)
                                self.sendMessage(content: "📷 Sent a photo", mediaURL: url.absoluteString)

                            }
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
                            self.sendMessage(content: "[Video]", mediaURL: url.absoluteString)
                        }
                    }
                }
            }
        } else if let audioURL = audioURL {
            uploadRef = storageRef.child("audio/\(UUID().uuidString).m4a")
            uploadRef?.putFile(from: audioURL, metadata: nil) { _, error in
                if error == nil {
                    uploadRef?.downloadURL { url, _ in
                        if let url = url {
                            self.sendMessage(content: "[Voice Message]", mediaURL: url.absoluteString)
                        }
                    }
                }
            }
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


    
    @objc private func handleSend() {
        guard let text = inputTextField.text, !text.isEmpty, let chatThread = chatThread else { return }
        
        chatManager.sendMessage(chatThread: chatThread, messageContent: text, senderID: currentUserID) { [weak self] success in
            if success {
                DispatchQueue.main.async {
                    self?.inputTextField.text = nil
                    self?.fetchMessages()
                    if let friend = chatThread.participants.first(where: { $0.id != self?.currentUserID }), let message = chatThread.messages.last {
                        self?.delegate?.didSendMessage(message, to: friend)
                    }
                }
            } else {
                print("Failed to send message")
            }
        }
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
            "mediaURL": mediaURL ?? "" // Store media URL if available
        ]

        if isGroupChat, let group = group {
            print(" Storing Group Message in /groups/\(group.id)/messages")
            
            let groupRef = db.collection("chats").document(group.id)
            let messagesRef = groupRef.collection("messages")

            messagesRef.addDocument(data: messageData) { error in
                if let error = error {
                    print(" Firestore Error Storing Group Message: \(error.localizedDescription)")
                } else {
                    print(" Group message stored successfully in Firestore")

                    //  Update Last Message for Group
                    groupRef.setData(["lastMessage": content, "lastUpdated": FieldValue.serverTimestamp()], merge: true) { err in
                        if let err = err {
                            print(" Error updating last message for group: \(err.localizedDescription)")
                        } else {
                            print("Last message updated for group chat")
                        }
                    }

                    DispatchQueue.main.async {
                        self.fetchMessages() // Refresh UI
                    }
                }
            }
            
        } else if let chatThread = chatThread {
            print("Storing Private Chat Message in /chats/\(chatThread.id)/messages")
            
            let chatRef = db.collection("chats").document(chatThread.id)
            let messagesRef = chatRef.collection("messages")

            messagesRef.addDocument(data: messageData) { error in
                if let error = error {
                    print("Firestore Error Storing Private Message: \(error.localizedDescription)")
                } else {
                    print("Private message stored successfully")

                    // Update Last Message for Private Chat
                    chatRef.setData(["lastMessage": content, "lastUpdated": FieldValue.serverTimestamp()], merge: true) { err in
                        if let err = err {
                            print(" Error updating last message for private chat: \(err.localizedDescription)")
                        } else {
                            print(" Last message updated for private chat")
                        }
                    }

                    DispatchQueue.main.async {
                        self.fetchMessages()
                    }
                }
            }
            
        } else {
            print("ERROR: No valid chat reference (group and chatThread both nil)")
        }
    }

//    private func fetchMessages() {
//        guard let currentUser = Auth.auth().currentUser else { return }
//
//        let messagesRef: CollectionReference
//
//        if isGroupChat, let group = group {
//            print("Fetching Group Messages from: /groups/\(group.id)/messages")
//            messagesRef = db.collection("chats").document(group.id).collection("messages")
//        } else if let chatThread = chatThread {
//            print("Fetching Individual Messages from: /chats/\(chatThread.id)/messages")
//            messagesRef = db.collection("chats").document(chatThread.id).collection("messages")
//        } else {
//            print(" Error: No valid chat reference")
//            return
//        }
//
//        messagesListener?.remove() // Remove previous listener if exists
//
//        messagesListener = messagesRef
//            .order(by: "timestamp", descending: false)
//            .addSnapshotListener { [weak self] snapshot, error in
//                guard let self = self else { return }
//
//                if let error = error {
//                    print(" Error fetching messages: \(error.localizedDescription)")
//                    return
//                }
//
//                guard let documents = snapshot?.documents else {
//                    print(" No messages found")
//                    return
//                }
//
//                print(" \(documents.count) messages found")
//
//                var newMessages: [ChatMessage] = []
//
//                for doc in documents {
//                    let data = doc.data()
//                    let id = doc.documentID
//                    let senderID = data["senderId"] as? String ?? ""
//                    let messageContent = data["messageContent"] as? String ?? ""
//                    let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
//
//                    let sender = self.chatThread?.participants.first(where: { $0.id == senderID }) ?? User(id: senderID, name: "Unknown")
//
//                    let message = ChatMessage(id: id, sender: sender, messageContent: messageContent, timestamp: timestamp, isSender: senderID == self.currentUserID)
//                    newMessages.append(message)
//                }
//
//                self.chatThread?.messages = newMessages
//                DispatchQueue.main.async {
//                    self.tableView.reloadData()
//                    self.scrollToBottom()
//                }
//            }
//    }

    private func fetchMessages() {
        guard let currentUser = Auth.auth().currentUser else { return }

        let messagesRef = db.collection("chats").document(chatThread!.id).collection("messages")

        messagesListener?.remove()
        messagesListener = messagesRef
            .order(by: "timestamp", descending: false)
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
                    let mediaURL = data["mediaURL"] as? String ?? "" // ✅ Fetch mediaURL

                    let sender = self.chatThread?.participants.first(where: { $0.id == senderID }) ?? User(id: senderID, name: "Unknown")
                    let message = ChatMessage(id: id, sender: sender, messageContent: messageContent, timestamp: timestamp, isSender: senderID == self.currentUserID, mediaURL: mediaURL)
                    newMessages.append(message)
                }

                self.chatThread?.messages = newMessages
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.scrollToBottom()
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
            self.fetchMessages() //  Fetch messages after loading participants
        }
    }



    
    private func scrollToBottom() {
        DispatchQueue.main.async {
            let rowCount = self.chatThread?.messages.count ?? 0
            if rowCount > 0 {
                let indexPath = IndexPath(row: rowCount - 1, section: 0)
                self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatThread?.messages.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatMessageCell", for: indexPath) as! ChatMessageCell
        if let message = chatThread?.messages[indexPath.row] {
            print("Displaying Message: \(message.messageContent) from \(message.sender.id)")
            cell.configure(with: message)
        } else {
            print(" No message found for row \(indexPath.row)")
        }
        return cell
    }

    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    private func removeNotificationForChatThread(_ chatThread: ChatThread) {
        db.collection("notifications")
            .whereField("senderId", in: chatThread.participants.map { $0.id })
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching notifications: \(error)")
                    return
                }
                
                snapshot?.documents.forEach { document in
                    document.reference.delete { error in
                        if let error = error {
                            print("Error deleting notification: \(error)")
                        }
                    }
                }
            }
    }
}
#Preview{
    ChatDetailViewController()
}
