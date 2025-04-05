import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Kingfisher

class EventGroupViewController: UIViewController {
    
    // Update the initializer to accept EventGroup.Member array
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
    private let messageManager = EventGroupMessageManager() // Assume this exists
    private let eventGroupManager = EventGroupManager() // Assume this exists
    
    // Change to use computed property to avoid override issues
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
    
    // MARK: - Initialization
    init(eventId: String, eventName: String) {
        self.eventId = eventId
        self.eventName = eventName
        super.init(nibName: nil, bundle: nil)
    }

    
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
        let titleTapGesture = UITapGestureRecognizer(target: self, action: #selector(titleTapped))
        let titleView = UILabel()
        titleView.text = eventName
        titleView.font = UIFont.boldSystemFont(ofSize: 18)
        titleView.isUserInteractionEnabled = true
        titleView.addGestureRecognizer(titleTapGesture)
        navigationItem.titleView = titleView
        
        // Add member management button
        let memberButton = UIBarButtonItem(image: UIImage(systemName: "person.3"), style: .plain, target: self, action: #selector(showMemberManagement))
        navigationItem.rightBarButtonItem = memberButton
        
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
        // Similar to GroupViewController implementation
        // ...
    }
    
    private func setupTableView() {
        // Similar to GroupViewController implementation
        // ...
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
        // Similar to GroupViewController implementation
        // ...
    }
    
    private func setupNotifications() {
        // Similar to GroupViewController implementation
        // ...
    }
    
    // MARK: - Data Loading
    private func loadEventDetails() {
        // Similar to GroupViewController but for events
        // ...
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
        // Similar to GroupViewController but for events
        // ...
    }
    
    private func setupMessageListener() {
        // Similar to GroupViewController but for events
        // ...
    }
    
    // MARK: - UI Updates
    private func updateParticipantLabel() {
        // Similar to GroupViewController but for events
        // ...
    }
    
    private func updateMessageInputAccessibility() {
        // Similar to GroupViewController but for events
        // ...
    }
    
    // MARK: - Actions
    @objc private func titleTapped() {
        // Show event details or members list
        showMemberManagement()
    }
    
    @objc private func showMemberManagement() {
        // Navigate to event member management
        // ...
    }
    
    @objc private func keyboardWillShow(notification: Notification) {
        // Similar to GroupViewController
        // ...
    }
    
    @objc private func keyboardWillHide(notification: Notification) {
        // Similar to GroupViewController
        // ...
    }
    
    @objc private func appWillEnterForeground() {
        // Similar to GroupViewController
        // ...
    }
    
    @objc private func handleImageTap(_ notification: Notification) {
        // Similar to GroupViewController but using EventGroup types
        // ...
    }
    
    // MARK: - Image Handling and Message Sending
    private func selectImage() {
        // Similar to GroupViewController
        // ...
    }
    
    private func uploadImage(image: UIImage) {
        // Similar to GroupViewController but for events
        // ...
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
        // Similar to GroupViewController
        // ...
    }
}

// MARK: - UITableViewDataSource
extension EventGroupViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Similar to GroupViewController but using EventGroup types and cells
        // ...
        return UITableViewCell() // Placeholder
    }
}

// MARK: - UITableViewDelegate
extension EventGroupViewController: UITableViewDelegate {
    // Similar to GroupViewController
    // ...
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
    // Similar to GroupViewController
    // ...
}
