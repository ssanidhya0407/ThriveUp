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
        let detailsVC = EventDetailsViewController(
            eventId: eventId,
            eventName: eventName,
            imageURL: eventImageURL
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
        
        // Transform the cell content to counteract the table view transform
        cell.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension EventGroupViewController: UITableViewDelegate {
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

// Event Details View Controller
class EventDetailsViewController: UIViewController {
    
    // MARK: - Properties
    private let eventId: String
    private let eventName: String
    private var eventImageURL: String?
    private var members: [EventGroup.Member] = []
    private let db = Firestore.firestore()
    private let eventGroupManager = EventGroupManager()
    private let currentUserID = Auth.auth().currentUser?.uid ?? ""
    private var isCurrentUserOrganizer = false
    
    // UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let eventImageView = UIImageView()
    private let eventNameLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let dateLabel = UILabel()
    private let locationLabel = UILabel()
    private let membersHeaderLabel = UILabel()
    private let membersStackView = UIStackView()
    private let settingsHeaderLabel = UILabel()
    
    // MARK: - Initialization
    init(eventId: String, eventName: String, imageURL: String? = nil) {
        self.eventId = eventId
        self.eventName = eventName
        self.eventImageURL = imageURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadEventDetails()
        loadMembers()
    }
    
    // Setup methods and other implementations would go here, similar to GroupDetailsViewController
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Event Details"
        
        // Add Edit button if user is organizer (to be implemented later)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .edit,
            target: self,
            action: #selector(editEventTapped)
        )
        
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ])
        
        setupEventHeader()
        setupMembersSection()
        setupSettingsSection()
    }
    
    private func setupEventHeader() {
        // Event image
        eventImageView.contentMode = .scaleAspectFill
        eventImageView.clipsToBounds = true
        eventImageView.layer.cornerRadius = 50
        eventImageView.backgroundColor = .systemGray6
        eventImageView.image = UIImage(systemName: "calendar")
        eventImageView.tintColor = .systemGray3
        eventImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(eventImageView)
        
        // Event name label
        eventNameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        eventNameLabel.text = eventName
        eventNameLabel.textAlignment = .center
        eventNameLabel.numberOfLines = 0
        eventNameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(eventNameLabel)
        
        // Date label
        dateLabel.font = UIFont.systemFont(ofSize: 16)
        dateLabel.textColor = .secondaryLabel
        dateLabel.text = "Event date will appear here"
        dateLabel.textAlignment = .center
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateLabel)
        
        // Location label
        locationLabel.font = UIFont.systemFont(ofSize: 16)
        locationLabel.textColor = .secondaryLabel
        locationLabel.text = "Event location will appear here"
        locationLabel.textAlignment = .center
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(locationLabel)
        
        // Description label
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textColor = .label
        descriptionLabel.text = "Event description will appear here"
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .left
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(descriptionLabel)
        
        // Separator line
        let separatorLine = UIView()
        separatorLine.backgroundColor = .systemGray5
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        
        NSLayoutConstraint.activate([
            eventImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            eventImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            eventImageView.widthAnchor.constraint(equalToConstant: 100),
            eventImageView.heightAnchor.constraint(equalToConstant: 100),
            
            eventNameLabel.topAnchor.constraint(equalTo: eventImageView.bottomAnchor, constant: 16),
            eventNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            eventNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            dateLabel.topAnchor.constraint(equalTo: eventNameLabel.bottomAnchor, constant: 8),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            locationLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4),
            locationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            locationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            descriptionLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            separatorLine.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    private func setupMembersSection() {
        // Members header
        membersHeaderLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        membersHeaderLabel.text = "Participants"
        membersHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(membersHeaderLabel)
        
        // Add button
        let addButton = UIButton(type: .system)
        addButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(addMemberTapped), for: .touchUpInside)
        contentView.addSubview(addButton)
        
        // Members stack view - will add member views here dynamically
        membersStackView.axis = .vertical
        membersStackView.spacing = 8
        membersStackView.distribution = .fillProportionally
        membersStackView.alignment = .fill
        membersStackView.translatesAutoresizingMaskIntoConstraints = false
        membersStackView.backgroundColor = .clear
        contentView.addSubview(membersStackView)
        
        // Separator line
        let separatorLine = UIView()
        separatorLine.backgroundColor = .systemGray5
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        
        NSLayoutConstraint.activate([
            membersHeaderLabel.topAnchor.constraint(equalTo: contentView.subviews.first { $0.backgroundColor == .systemGray5 }!.bottomAnchor, constant: 20),
            membersHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            addButton.centerYAnchor.constraint(equalTo: membersHeaderLabel.centerYAnchor),
            addButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            membersStackView.topAnchor.constraint(equalTo: membersHeaderLabel.bottomAnchor, constant: 12),
            membersStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            membersStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            separatorLine.topAnchor.constraint(equalTo: membersStackView.bottomAnchor, constant: 20),
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    private func setupSettingsSection() {
        // Settings header
        settingsHeaderLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        settingsHeaderLabel.text = "Settings"
        settingsHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(settingsHeaderLabel)
        
        // For now, just show a leave event button
        let leaveEventButton = UIButton(type: .system)
        leaveEventButton.setTitle("Leave Event", for: .normal)
        leaveEventButton.setTitleColor(.systemRed, for: .normal)
        leaveEventButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        leaveEventButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        leaveEventButton.layer.cornerRadius = 8
        leaveEventButton.addTarget(self, action: #selector(leaveEventTapped), for: .touchUpInside)
        leaveEventButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(leaveEventButton)
        
        NSLayoutConstraint.activate([
            settingsHeaderLabel.topAnchor.constraint(equalTo: contentView.subviews.last { $0.backgroundColor == .systemGray5 }!.bottomAnchor, constant: 20),
            settingsHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            leaveEventButton.topAnchor.constraint(equalTo: settingsHeaderLabel.bottomAnchor, constant: 16),
            leaveEventButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            leaveEventButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            leaveEventButton.heightAnchor.constraint(equalToConstant: 50),
            leaveEventButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    // MARK: - Data Loading
    private func loadEventDetails() {
        db.collection("events").document(eventId).getDocument { [weak self] snapshot, error in
            guard let self = self, let data = snapshot?.data() else {
                print("Error fetching event details: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                // Update event name
                if let name = data["name"] as? String {
                    self.eventNameLabel.text = name
                }
                
                // Update date if available
                if let startDate = (data["startDate"] as? Timestamp)?.dateValue(),
                   let endDate = (data["endDate"] as? Timestamp)?.dateValue() {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    dateFormatter.timeStyle = .short
                    
                    let startDateString = dateFormatter.string(from: startDate)
                    let endDateString = dateFormatter.string(from: endDate)
                    self.dateLabel.text = "\(startDateString) - \(endDateString)"
                }
                
                // Update location if available
                if let location = data["location"] as? String {
                    self.locationLabel.text = location
                }
                
                // Update description if available
                if let description = data["description"] as? String {
                    self.descriptionLabel.text = description
                } else {
                    self.descriptionLabel.text = "No description available"
                }
                
                // Load event image
                if let imageURL = data["imageName"] as? String, let url = URL(string: imageURL) {
                    self.eventImageView.kf.setImage(
                        with: url,
                        placeholder: UIImage(systemName: "calendar"),
                        options: [.transition(.fade(0.3))]
                    )
                    self.eventImageURL = imageURL
                } else if let imageURL = self.eventImageURL, let url = URL(string: imageURL) {
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
            
            // Check if current user is organizer
            if let currentMember = members.first(where: { $0.userId == self.currentUserID }),
               currentMember.role == "organizer" {
                self.isCurrentUserOrganizer = true
                DispatchQueue.main.async {
                    // Enable add button for organizers
                    let addButton = self.contentView.subviews.first { $0 is UIButton && ($0 as! UIButton).currentImage?.accessibilityIdentifier == "plus.circle.fill" }
                    addButton?.isHidden = false
                }
            } else {
                DispatchQueue.main.async {
                    // Hide add button for non-organizers
                    let addButton = self.contentView.subviews.first { $0 is UIButton && ($0 as! UIButton).currentImage?.accessibilityIdentifier == "plus.circle.fill" }
                    addButton?.isHidden = true
                }
            }
            
            // Sort members: organizers first, then alphabetically by name
            self.members = members.sorted { (member1, member2) in
                if member1.role == "organizer" && member2.role != "organizer" {
                    return true
                } else if member1.role != "organizer" && member2.role == "organizer" {
                    return false
                } else {
                    return member1.name < member2.name
                }
            }
            
            DispatchQueue.main.async {
                self.updateMembersStackView()
                self.view.layoutIfNeeded()
            }
        }
    }
    
    // Other methods would be implemented similar to GroupDetailsViewController
    
    private func updateMembersStackView() {
        // Implementation would be similar to GroupDetailsViewController
    }
    
    @objc private func editEventTapped() {
        // Implementation for editing event details
    }
    
    @objc private func addMemberTapped() {
        // Implementation for adding members
    }
    
    @objc private func leaveEventTapped() {
        // Implementation for leaving the event
    }
}

// Required supporting classes for the implementation
class EventMessageManager {
    func addMessageListener(eventId: String, limit: Int, completion: @escaping ([EventGroup.Message]) -> Void) -> ListenerRegistration {
        // Implementation would be similar to GroupMessageManager
        return Firestore.firestore().collection("temp").addSnapshotListener { _, _ in }
    }
    
    func sendMessage(eventId: String, userId: String, text: String?, imageURL: String?, completion: @escaping (Bool, String?) -> Void) {
        // Implementation would be similar to GroupMessageManager
    }
}




class EventMessageCell: UITableViewCell {
    static let identifier = "EventMessageCell"
    
    func configure(with message: EventGroup.Message, organizers: [String]) {
        // Implementation
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

    


