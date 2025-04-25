import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SDWebImage // Make sure this import is present if using SDWebImage

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, RegisteredEventCellDelegate {

    // MARK: - Properties
    private var registeredEvents: [EventModel] = []
    private var userInterests: [String] = []
    private let db = Firestore.firestore()

    // Scroll View
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    private let contentView: UIView = {
        let view = UIView()
        return view
    }()

    // Profile Header
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "default_profile")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 50
        imageView.layer.borderWidth = 3
        imageView.layer.borderColor = UIColor.systemOrange.cgColor
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Name"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let emailLabel: UILabel = {
        let label = UILabel()
        label.text = "Email"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    // Stats View
    private let statsContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 16
        return view
    }()

    private let statsStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        return stackView
    }()

    // Segment Control
    private let segmentControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Details", "Events"])
        control.selectedSegmentIndex = 0
        control.selectedSegmentTintColor = .systemOrange
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        control.setTitleTextAttributes([.foregroundColor: UIColor.systemOrange], for: .normal)
        return control
    }()

    // Details View
    private let detailsContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 16
        return view
    }()

    private let detailsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        return stackView
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "No description available"
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Description Section
    private let descriptionStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        return stackView
    }()

    private let descriptionHeader: UILabel = {
        let label = UILabel()
        label.text = "DESCRIPTION"
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .tertiaryLabel
        return label
    }()

    // Contact Info
    private let contactStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        return stackView
    }()

    private let contactHeader: UILabel = {
        let label = UILabel()
        label.text = "CONTACT INFO"
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .tertiaryLabel
        return label
    }()

    private let contactDetailsLabel: UILabel = {
        let label = UILabel()
        label.text = "Not available"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    // Social Links
    private let socialStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        return stackView
    }()

    private let socialHeader: UILabel = {
        let label = UILabel()
        label.text = "SOCIAL LINKS"
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .tertiaryLabel
        return label
    }()

    private let githubLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black // Changed to black for consistency, will be blue if link exists
        label.numberOfLines = 0
        label.lineBreakMode = .byCharWrapping
        label.isUserInteractionEnabled = true
        return label
    }()

    private let linkedinLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black // Changed to black for consistency, will be blue if link exists
        label.numberOfLines = 0
        label.lineBreakMode = .byCharWrapping
        label.isUserInteractionEnabled = true
        return label
    }()

    // Tech Stack
    private let techStackContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 16
        return view
    }()

    private let techStackHeader: UILabel = {
        let label = UILabel()
        label.text = "TECH STACK"
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold) // Make it bold
        label.textColor = .black // Make it black for better visibility
        return label
    }()

    private let techStackFlowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        return layout
    }()

    private lazy var techStackCollectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: techStackFlowLayout)
        collectionView.register(TechStackCell.self, forCellWithReuseIdentifier: TechStackCell.identifier)
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    private var techStackItems: [String] = []

    // Events Table
    private let eventsTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(RegisteredEventCell.self, forCellReuseIdentifier: RegisteredEventCell.identifier)
        tableView.isHidden = true
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        return tableView
    }()

    // Delete Account Button
    private let deleteAccountButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Delete Account", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .tertiarySystemBackground // Subtle background
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        button.addTarget(self, action: #selector(handleDeleteAccountTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        configureNavigationBar()
        loadUserDetails()
        loadUserInterests()
        loadRegisteredEvents()
        fetchFriendsCount() // Initial fetch for friends count

        NotificationCenter.default.addObserver(self, selector: #selector(updateFriendCount), name: NSNotification.Name("FriendCountUpdated"), object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reload details in case they were edited
        loadUserDetails()
        // Ensure correct view visibility based on segment
        segmentChanged()
        // Reload friend count in case of changes on other screens
        fetchFriendsCount()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Layout Debugging <<<<<<< ADD THE METHOD HERE >>>>>>>>
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Only print when the details segment is potentially visible
        if !detailsContainer.isHidden {
            let scrollViewHeight = scrollView.frame.height
            let contentHeight = contentView.frame.height
            let scrollContentSizeHeight = scrollView.contentSize.height
            let deleteButtonMaxY = deleteAccountButton.frame.maxY // Y position + height

            print("--- Layout Debug ---")
            // Use optional binding for date formatting
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            let timestamp = dateFormatter.string(from: Date())
            print("Timestamp: \(timestamp)")
            print("Scroll View Frame Height: \(scrollViewHeight)")
            print("Content View Frame Height: \(contentHeight)")
            print("Scroll View ContentSize Height: \(scrollContentSizeHeight)")
            print("Delete Button Frame: \(deleteAccountButton.frame)") // Print whole frame for more info
            print("Delete Button Max Y (relative to contentView): \(deleteButtonMaxY)")
            print("Bottom Padding added to contentView bottom constraint: 24.0") // From the constraint
            let expectedContentHeight = deleteButtonMaxY + 24.0
            print("Expected Content Height (deleteButtonMaxY + padding): \(expectedContentHeight)")

            if scrollContentSizeHeight < expectedContentHeight - 1.0 { // Use tolerance for floating point
                print(">>> WARNING: ScrollView contentSize.height (\(scrollContentSizeHeight)) is LESS than expected content height (\(expectedContentHeight)). Scrolling likely broken.")
            }
            if contentHeight < expectedContentHeight - 1.0 {
                 print(">>> WARNING: ContentView frame.height (\(contentHeight)) is LESS than expected content height (\(expectedContentHeight)). Constraints likely broken.")
            }
            print("--------------------")
        }
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Scroll View
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Profile Header
        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(emailLabel)

        // Stats
        contentView.addSubview(statsContainer)
        statsContainer.addSubview(statsStack)

        // Segment Control
        contentView.addSubview(segmentControl)
        segmentControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)

        // Details Container
        contentView.addSubview(detailsContainer)
        detailsContainer.addSubview(detailsStackView)

        // Description Section
        descriptionStack.addArrangedSubview(descriptionHeader)
        descriptionStack.addArrangedSubview(descriptionLabel)
        detailsStackView.addArrangedSubview(descriptionStack)

        // Contact Info
        contactStack.addArrangedSubview(contactHeader)
        contactStack.addArrangedSubview(contactDetailsLabel)
        detailsStackView.addArrangedSubview(contactStack)

        // Social Links
        socialStack.addArrangedSubview(socialHeader)
        socialStack.addArrangedSubview(githubLabel)
        socialStack.addArrangedSubview(linkedinLabel)
        detailsStackView.addArrangedSubview(socialStack)

        // Tech Stack (Separate Container)
        contentView.addSubview(techStackContainer)
        techStackContainer.addSubview(techStackHeader)
        techStackContainer.addSubview(techStackCollectionView)

        // Add Delete Account Button directly to contentView
        contentView.addSubview(deleteAccountButton)

        // Events Table
        contentView.addSubview(eventsTableView)
        eventsTableView.dataSource = self
        eventsTableView.delegate = self

        // Add gesture recognizers
        let imageTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleImageTap))
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(imageTapGesture)
    }


    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        statsContainer.translatesAutoresizingMaskIntoConstraints = false
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        detailsContainer.translatesAutoresizingMaskIntoConstraints = false
        detailsStackView.translatesAutoresizingMaskIntoConstraints = false
        techStackContainer.translatesAutoresizingMaskIntoConstraints = false
        techStackHeader.translatesAutoresizingMaskIntoConstraints = false
        techStackCollectionView.translatesAutoresizingMaskIntoConstraints = false

        let techStackHeightConstraint = techStackCollectionView.heightAnchor.constraint(equalToConstant: 50) // Default/minimum height
        techStackHeightConstraint.identifier = "techStackHeightConstraint"
        techStackHeightConstraint.isActive = true

        eventsTableView.translatesAutoresizingMaskIntoConstraints = false
        deleteAccountButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Scroll View (Pins scroll view to fill the view controller's safe area/view bounds)
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor), // Pin to safe area bottom typically

            // Content View (Pins contentView to scroll view edges and defines width)
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor), // Use contentLayoutGuide
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor), // Use contentLayoutGuide
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor), // Use contentLayoutGuide
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor), // <<<<< ADDED: Link contentView bottom to scrollView bottom >>>>>
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor), // Width matches frameLayoutGuide

            // --- Internal ContentView Constraints ---
            // Profile Header
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),

            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            nameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            emailLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            // Stats Container
            statsContainer.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 24),
            statsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statsContainer.heightAnchor.constraint(equalToConstant: 100),

            statsStack.topAnchor.constraint(equalTo: statsContainer.topAnchor, constant: 16),
            statsStack.leadingAnchor.constraint(equalTo: statsContainer.leadingAnchor, constant: 16),
            statsStack.trailingAnchor.constraint(equalTo: statsContainer.trailingAnchor, constant: -16),
            statsStack.bottomAnchor.constraint(equalTo: statsContainer.bottomAnchor, constant: -16),

            // Segment Control
            segmentControl.topAnchor.constraint(equalTo: statsContainer.bottomAnchor, constant: 24),
            segmentControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            segmentControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            segmentControl.heightAnchor.constraint(equalToConstant: 40),

            // Details Container
            detailsContainer.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 16),
            detailsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            detailsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            detailsStackView.topAnchor.constraint(equalTo: detailsContainer.topAnchor, constant: 16),
            detailsStackView.leadingAnchor.constraint(equalTo: detailsContainer.leadingAnchor, constant: 16),
            detailsStackView.trailingAnchor.constraint(equalTo: detailsContainer.trailingAnchor, constant: -16),
            detailsStackView.bottomAnchor.constraint(equalTo: detailsContainer.bottomAnchor, constant: -16),

            // Tech Stack Container
            techStackContainer.topAnchor.constraint(equalTo: detailsContainer.bottomAnchor, constant: 16),
            techStackContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            techStackContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            techStackHeader.topAnchor.constraint(equalTo: techStackContainer.topAnchor, constant: 16),
            techStackHeader.leadingAnchor.constraint(equalTo: techStackContainer.leadingAnchor, constant: 16),
            techStackHeader.trailingAnchor.constraint(equalTo: techStackContainer.trailingAnchor, constant: -16),

            techStackCollectionView.topAnchor.constraint(equalTo: techStackHeader.bottomAnchor, constant: 12),
            techStackCollectionView.leadingAnchor.constraint(equalTo: techStackContainer.leadingAnchor, constant: 16),
            techStackCollectionView.trailingAnchor.constraint(equalTo: techStackContainer.trailingAnchor, constant: -16),
            techStackCollectionView.bottomAnchor.constraint(equalTo: techStackContainer.bottomAnchor, constant: -16), // Tech stack container height defined by collection view

            // Delete Account Button Constraints (Now defines the bottom-most item in the vertical chain)
            deleteAccountButton.topAnchor.constraint(equalTo: techStackContainer.bottomAnchor, constant: 24),
            deleteAccountButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            deleteAccountButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            // *** IMPORTANT: Add a bottom constraint from the delete button to the contentView bottom ***
            deleteAccountButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24), // Pin delete button relative to contentView bottom

            // Content View Bottom Constraint
            // REMOVED: contentView.bottomAnchor.constraint(equalTo: deleteAccountButton.bottomAnchor, constant: 24), // This is now handled implicitly by the chain + the new scrollView bottom constraint

            // Events Table (Overlaying the Details/Tech Stack/Delete area when active)
            eventsTableView.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 16),
            eventsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            eventsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            // Adjust events table bottom to pin to contentView bottom
            eventsTableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16), // <<<<< ADJUSTED >>>>>

        ])
    }


    // MARK: - Navigation Bar
    private func configureNavigationBar() {
        let logoutButton = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        let editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(handleEdit))

        navigationItem.rightBarButtonItem = logoutButton
        navigationItem.leftBarButtonItem = editButton
    }

    // MARK: - Actions
    @objc private func segmentChanged() {
        let isShowingEvents = segmentControl.selectedSegmentIndex == 1
        detailsContainer.isHidden = isShowingEvents
        techStackContainer.isHidden = isShowingEvents
        deleteAccountButton.isHidden = isShowingEvents // Hide/show delete button
        eventsTableView.isHidden = !isShowingEvents

        if isShowingEvents {
            // Reload events data if needed when switching to the Events tab
            loadRegisteredEvents()
        } else {
            // Reload user details if needed when switching back to Details tab
             loadUserDetails() // Ensures tech stack height is recalculated
        }
    }

    @objc private func handleEdit() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not authenticated.")
            showErrorAlert(message: "You need to be logged in to edit your profile.")
            return
        }

        db.collection("users").document(userId).getDocument { [weak self] document, error in
            guard let self = self else { return }

            if let error = error {
                print("Error fetching user document for edit: \(error.localizedDescription)")
                self.showErrorAlert(message: "Could not load profile details for editing.")
                return
            }

            guard let document = document, document.exists, let data = document.data() else {
                print("User document not found for edit.")
                self.showErrorAlert(message: "Could not find your profile details.")
                return
            }

            let editVC = EditProfileViewController()
            editVC.name = data["name"] as? String
            // Use the actual text from the label as fallback if DB fetch had issues initially
            editVC.descriptionText = (data["Description"] as? String)?.isEmpty ?? true ? self.descriptionLabel.text : (data["Description"] as? String)
             if editVC.descriptionText == "No description available" { // Clear placeholder if needed
                 editVC.descriptionText = ""
             }
            editVC.contact = (data["ContactDetails"] as? String)?.isEmpty ?? true ? self.contactDetailsLabel.text : (data["ContactDetails"] as? String)
             if editVC.contact == "Not available" { // Clear placeholder
                 editVC.contact = ""
             }
            editVC.githubUrl = data["githubUrl"] as? String
            editVC.linkedinUrl = data["linkedinUrl"] as? String
            editVC.techStack = data["techStack"] as? String
            editVC.imageUrl = data["profileImageURL"] as? String

            editVC.onSave = { [weak self] updatedDetails in
                self?.updateProfile(with: updatedDetails)
            }

            self.navigationController?.pushViewController(editVC, animated: true)
        }
    }


    @objc private func handleImageTap() {
        presentImagePicker()
    }

    @objc private func handleLogout() {
        do {
            try Auth.auth().signOut()
            // Navigate back to login/initial screen
             navigateToLoginScreen()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
            showErrorAlert(message: "Could not log out. Please try again.")
        }
    }

    @objc private func handleDeleteAccountTapped() {
        let alert = UIAlertController(
            title: "Delete Account",
            message: "Are you absolutely sure you want to delete your account? This action is irreversible and will remove all your data, including friendships, chat history, group memberships, and event registrations.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            self?.proceedWithAccountDeletion()
        }))

        present(alert, animated: true)
    }


    @objc private func didTapFriendsLabel() {
        let friendsVC = FriendsViewController()
        // Ensure we have a valid user ID and name
        guard let userId = Auth.auth().currentUser?.uid, let userName = nameLabel.text, userName != "Name" else {
             print("Cannot navigate to friends: User ID or Name not available.")
             showErrorAlert(message: "Could not load friends list.")
             return
         }
        friendsVC.currentUser = User(id: userId, name: userName)
        navigationController?.pushViewController(friendsVC, animated: true)
    }

    @objc private func updateFriendCount() {
        fetchFriendsCount()
    }

    // Inside ProfileViewController class

    // MARK: - Data Loading
    private func loadUserDetails() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not authenticated for loading details.")
            // Clear fields or show placeholder state
             self.nameLabel.text = "Name"
             self.emailLabel.text = "Email"
             self.descriptionLabel.text = "No description available"
             self.contactDetailsLabel.text = "Not available"
             self.githubLabel.text = "GitHub: Not available"
             self.linkedinLabel.text = "LinkedIn: Not available"
             self.githubLabel.attributedText = nil
             self.linkedinLabel.attributedText = nil
             self.githubLabel.isUserInteractionEnabled = false
             self.linkedinLabel.isUserInteractionEnabled = false
             self.techStackItems = []
             self.techStackCollectionView.reloadData()
             // Reset tech stack height and update layout
             if let heightConstraint = self.techStackCollectionView.constraints.first(where: { $0.firstAttribute == .height }) {
                 heightConstraint.constant = 50
             }
             self.view.layoutIfNeeded() // Update layout after resetting
             self.profileImageView.image = UIImage(named: "default_profile")
            return
        }

        db.collection("users").document(userId).getDocument { [weak self] document, error in
            guard let self = self else { return }

            if let error = error {
                print("Error fetching user details: \(error.localizedDescription)")
                 self.showErrorAlert(message: "Could not load profile details.")
                return
            }

            guard let data = document?.data() else {
                print("No user data found for userId: \(userId)")
                 self.showErrorAlert(message: "Profile data not found.")
                return
            }

            DispatchQueue.main.async {
                self.nameLabel.text = data["name"] as? String ?? "Name"
                self.emailLabel.text = data["email"] as? String ?? "Email"

                let contact = data["ContactDetails"] as? String ?? ""
                self.contactDetailsLabel.text = contact.isEmpty ? "Not available" : contact

                let description = data["Description"] as? String ?? ""
                self.descriptionLabel.text = description.isEmpty ? "No description available" : description

                // GitHub Link (logic unchanged)
                if let github = data["githubUrl"] as? String, !github.isEmpty, let url = URL(string: github.hasPrefix("http") ? github : "https://\(github)") {
                    let displayLink = github.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: "")
                    let attributedString = NSMutableAttributedString(string: "GitHub: \(displayLink)")
                    let linkRange = NSRange(location: 8, length: displayLink.count)
                    attributedString.addAttribute(.link, value: url, range: linkRange)
                    attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: linkRange)
                    attributedString.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: NSRange(location: 0, length: attributedString.length))
                    attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 16, weight: .medium), range: NSRange(location: 0, length: attributedString.length))
                    self.githubLabel.attributedText = attributedString
                    self.githubLabel.isUserInteractionEnabled = true
                    self.githubLabel.gestureRecognizers?.forEach { self.githubLabel.removeGestureRecognizer($0) }
                    let tap = UITapGestureRecognizer(target: self, action: #selector(self.openGithubLink))
                    self.githubLabel.addGestureRecognizer(tap)
                } else {
                    self.githubLabel.text = "GitHub: Not available"
                    self.githubLabel.attributedText = nil
                    self.githubLabel.textColor = .label
                    self.githubLabel.isUserInteractionEnabled = false
                }

                // LinkedIn Link (logic unchanged)
                if let linkedin = data["linkedinUrl"] as? String, !linkedin.isEmpty, let url = URL(string: linkedin.hasPrefix("http") ? linkedin : "https://\(linkedin)") {
                     let displayLink = linkedin.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: "")
                     let attributedString = NSMutableAttributedString(string: "LinkedIn: \(displayLink)")
                     let linkRange = NSRange(location: 10, length: displayLink.count)
                     attributedString.addAttribute(.link, value: url, range: linkRange)
                     attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: linkRange)
                     attributedString.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: NSRange(location: 0, length: attributedString.length))
                     attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 16, weight: .medium), range: NSRange(location: 0, length: attributedString.length))
                    self.linkedinLabel.attributedText = attributedString
                    self.linkedinLabel.isUserInteractionEnabled = true
                    self.linkedinLabel.gestureRecognizers?.forEach { self.linkedinLabel.removeGestureRecognizer($0) }
                    let tap = UITapGestureRecognizer(target: self, action: #selector(self.openLinkedinLink))
                    self.linkedinLabel.addGestureRecognizer(tap)
                } else {
                    self.linkedinLabel.text = "LinkedIn: Not available"
                    self.linkedinLabel.attributedText = nil
                    self.linkedinLabel.textColor = .label
                    self.linkedinLabel.isUserInteractionEnabled = false
                }

                // Tech Stack - Refined Height Update
                var needsLayoutUpdate = false // Flag to trigger layout update once at the end
                if let techStack = data["techStack"] as? String, !techStack.isEmpty {
                    let items = techStack.components(separatedBy: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    var uniqueItems = [String]()
                    for item in items {
                        if !uniqueItems.contains(item) {
                            uniqueItems.append(item)
                        }
                    }

                    // Only reload and update height if items actually changed
                    if self.techStackItems != uniqueItems {
                        self.techStackItems = uniqueItems
                        self.techStackCollectionView.reloadData()

                        // Update height *after* reload completes using performBatchUpdates completion
                        self.techStackCollectionView.performBatchUpdates(nil) { [weak self] _ in
                            guard let self = self else { return }
                            let requiredHeight = self.techStackCollectionView.collectionViewLayout.collectionViewContentSize.height
                            let newHeightConstant = max(requiredHeight, 50) // Ensure minimum height
                            
                            let height = self.techStackCollectionView.collectionViewLayout.collectionViewContentSize.height
                            
                            // Find the specific height constraint
                                  if let heightConstraint = self.techStackCollectionView.constraints.first(where: { $0.identifier == "techStackHeightConstraint" || ($0.firstItem === self.techStackCollectionView && $0.firstAttribute == .height && $0.relation == .equal) }) {
                                      // Only update and trigger layout if the constant actually changes
                                      if heightConstraint.constant != newHeightConstant {
                                          heightConstraint.constant = newHeightConstant
                                          needsLayoutUpdate = true
                                          // print("Tech stack height constraint updated to: \(newHeightConstant)")
                                      }
                                  } else {
                                      print("ERROR: Could not find techStackHeightConstraint to update.")
                                  }
                            
                            
                            // If layout needs updating due to height change, trigger it here
                            if needsLayoutUpdate {
                                DispatchQueue.main.async {
                                    // print("Triggering layoutIfNeeded after tech stack update")
                                    UIView.animate(withDuration: 0.1) { // Small animation can help visualize update
                                         self.view.layoutIfNeeded()
                                    }
                                }
                            }
                        }
                    }
                } else {
                    // If tech stack is empty, ensure items are cleared and height is reset
                    if !self.techStackItems.isEmpty {
                        self.techStackItems = []
                        self.techStackCollectionView.reloadData()
                        if let heightConstraint = self.techStackCollectionView.constraints.first(where: { $0.identifier == "techStackHeightConstraint" || ($0.firstItem === self.techStackCollectionView && $0.firstAttribute == .height && $0.relation == .equal) }) {
                            if heightConstraint.constant != 50 {
                                heightConstraint.constant = 50
                                needsLayoutUpdate = true
                                // print("Tech stack height constraint reset to 50")
                            }
                        } else {
                            print("ERROR: Could not find techStackHeightConstraint to reset.")
                        }
                        
                        if needsLayoutUpdate {
                            DispatchQueue.main.async {
                                // print("Triggering layoutIfNeeded after tech stack reset")
                                UIView.animate(withDuration: 0.1) {
                                    self.view.layoutIfNeeded()
                                }
                            }
                        }
                    }
                }

                // Profile Image
                if let profileImageURLString = data["profileImageURL"] as? String,
                   let profileImageURL = URL(string: profileImageURLString) {
                    // Check if URL changed before reloading (optional optimization)
                    if self.profileImageView.sd_imageURL != profileImageURL {
                         self.loadProfileImage(from: profileImageURL)
                    }
                } else {
                    // Check if image needs resetting
                    if self.profileImageView.image != UIImage(named: "default_profile") {
                         self.profileImageView.image = UIImage(named: "default_profile")
                    }
                }

                // Trigger final layout update if needed (e.g., if tech stack changed)
                // This ensures the contentView height and scrollView contentSize are correct
                if needsLayoutUpdate {
                    // print("Triggering final layoutIfNeeded in loadUserDetails")
                    self.view.layoutIfNeeded()
                }
            }
        }
    }


    @objc private func openGithubLink() {
        guard let attributedText = githubLabel.attributedText else { return }
        let range = NSRange(location: 0, length: attributedText.length)
        attributedText.enumerateAttribute(.link, in: range, options: []) { value, range, stop in
            if let url = value as? URL {
                UIApplication.shared.open(url)
                stop.pointee = true // Stop after finding the first link
            }
        }
    }

    @objc private func openLinkedinLink() {
        guard let attributedText = linkedinLabel.attributedText else { return }
        let range = NSRange(location: 0, length: attributedText.length)
        attributedText.enumerateAttribute(.link, in: range, options: []) { value, range, stop in
            if let url = value as? URL {
                UIApplication.shared.open(url)
                stop.pointee = true
            }
        }
    }


    private func loadProfileImage(from url: URL) {
        // Use SDWebImage for efficient loading and caching
        profileImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default_profile"), options: [], completed: { [weak self] image, error, cacheType, url in
             if error != nil {
                 print("Error loading profile image from URL \(String(describing: url)): \(error!.localizedDescription)")
                 // Ensure placeholder is set on error
                 self?.profileImageView.image = UIImage(named: "default_profile")
             }
         })
    }

    // MARK: - Friend Count Logic (Corrected)
    private func fetchFriendsCount() {
        guard let userId = Auth.auth().currentUser?.uid else {
            // If user is not logged in, update stats with 0 friends
            updateStatsView(friendsCount: 0, eventsCount: self.registeredEvents.count)
            return
        }

        let group = DispatchGroup()
        var friendIDs = Set<String>() // Use a Set to store unique friend IDs

        // Query 1: Find friends where the current user is the 'userID'
        // The friend is the 'friendID' in these documents
        group.enter()
        db.collection("friends")
            .whereField("userID", isEqualTo: userId)
            .getDocuments { snapshot, error in
                defer { group.leave() } // Ensure group.leave() is called
                if let error = error {
                    print("Error fetching friends (userID query): \(error.localizedDescription)")
                } else {
                    // Add the 'friendID' from each document to the Set
                    snapshot?.documents.forEach { doc in
                        if let friendID = doc.data()["friendID"] as? String {
                            friendIDs.insert(friendID)
                        }
                    }
                }
            }

        // Query 2: Find friends where the current user is the 'friendID'
        // The friend is the 'userID' in these documents
        group.enter()
        db.collection("friends")
            .whereField("friendID", isEqualTo: userId)
            .getDocuments { snapshot, error in
                defer { group.leave() } // Ensure group.leave() is called
                if let error = error {
                    print("Error fetching friends (friendID query): \(error.localizedDescription)")
                } else {
                    // Add the 'userID' from each document to the Set
                    snapshot?.documents.forEach { doc in
                        if let otherUserID = doc.data()["userID"] as? String {
                            friendIDs.insert(otherUserID)
                        }
                    }
                }
            }

        // After both queries complete, update the stats view
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            // The count of the Set gives the number of unique friends
            // print("Unique friend IDs found: \(friendIDs.count)") // Debug print
            self.updateStatsView(friendsCount: friendIDs.count, eventsCount: self.registeredEvents.count)
        }
    }


    private func updateStatsView(friendsCount: Int, eventsCount: Int) {
        // Clear existing views
        statsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Friends Stat
        let friendsStat = createStatView(count: friendsCount, title: "Friends", icon: UIImage(systemName: "person.2.fill"))
        let friendsTap = UITapGestureRecognizer(target: self, action: #selector(didTapFriendsLabel))
        friendsStat.addGestureRecognizer(friendsTap)
        statsStack.addArrangedSubview(friendsStat)

        // Events Stat
        let eventsStat = createStatView(count: eventsCount, title: "Events", icon: UIImage(systemName: "calendar.badge.checkmark"))
        // Make events stat non-interactive for now, or add navigation if needed
        eventsStat.isUserInteractionEnabled = false
        statsStack.addArrangedSubview(eventsStat)

        // Remove the old gesture recognizer from statsContainer if it exists
        statsContainer.gestureRecognizers?.forEach { statsContainer.removeGestureRecognizer($0) }
    }


    private func createStatView(count: Int, title: String, icon: UIImage?) -> UIView {
        let container = UIView()
        container.isUserInteractionEnabled = true // Enable interaction for taps

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4 // Reduced spacing

        if let icon = icon {
            let iconView = UIImageView(image: icon)
            iconView.contentMode = .scaleAspectFit
            iconView.tintColor = .systemOrange
            iconView.heightAnchor.constraint(equalToConstant: 28).isActive = true // Slightly smaller icon
            stack.addArrangedSubview(iconView)
        }

        let countLabel = UILabel()
        countLabel.text = "\(count)"
        countLabel.font = .systemFont(ofSize: 22, weight: .bold) // Slightly smaller count
        countLabel.textColor = .label
        stack.addArrangedSubview(countLabel)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13, weight: .medium) // Slightly smaller title
        titleLabel.textColor = .secondaryLabel
        stack.addArrangedSubview(titleLabel)

        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            // Optional: Constrain stack width/height if needed, but usually centerY/X is enough
             stack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor),
             stack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor)
        ])

        return container
    }


    private func loadUserInterests() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not authenticated for loading interests.")
             self.userInterests = []
            return
        }

        db.collection("Interest").document(userId).getDocument { [weak self] document, error in
            guard let self = self else { return }

            if let error = error {
                print("Error fetching user interests: \(error.localizedDescription)")
                // Handle error - maybe show an alert or log
                return
            }

            guard let data = document?.data(), let interests = data["interests"] as? [String] else {
                print("No interests data found or data format incorrect.")
                 self.userInterests = [] // Reset interests if none found
                return
            }

            self.userInterests = interests
            // No UI update needed here unless interests are displayed directly
        }
    }

    private func loadRegisteredEvents() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not authenticated for loading registered events.")
            self.registeredEvents = []
            self.eventsTableView.reloadData()
            // Update stats view even if user is not authenticated (shows 0 events)
            self.fetchFriendsCount() // This will update stats with 0 friends and 0 events
            return
        }

        db.collection("registrations").whereField("uid", isEqualTo: userId).getDocuments { [weak self] querySnapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("Error fetching registrations: \(error.localizedDescription)")
                // Handle error - show alert?
                self.registeredEvents = [] // Clear events on error
                self.eventsTableView.reloadData()
                 self.fetchFriendsCount() // Update stats with current friend count and 0 events
                return
            }

            let eventIds = querySnapshot?.documents.compactMap { $0.data()["eventId"] as? String } ?? []

            if eventIds.isEmpty {
                print("No registered events found for user \(userId).")
                self.registeredEvents = []
                DispatchQueue.main.async {
                    self.eventsTableView.reloadData()
                    // Fetch friends count to update the stats view correctly (0 events)
                     self.fetchFriendsCount()
                }
            } else {
                self.fetchEvents(for: eventIds)
            }
        }
    }


    private func fetchEvents(for eventIds: [String]) {
         guard !eventIds.isEmpty else {
              // If eventIds becomes empty (e.g., after unregistering last event),
              // clear the table and update stats.
              self.registeredEvents = []
              DispatchQueue.main.async {
                  self.eventsTableView.reloadData()
                  self.fetchFriendsCount() // Update stats (will include 0 events)
              }
              return
          }

        let group = DispatchGroup()
        var fetchedEvents: [EventModel] = []

        // Use Firestore's 'in' query for efficiency if eventIds count is <= 30
         let maxInQuerySize = 30
         let chunks = stride(from: 0, to: eventIds.count, by: maxInQuerySize).map {
             Array(eventIds[$0..<min($0 + maxInQuerySize, eventIds.count)])
         }

         for chunk in chunks {
              group.enter()
              db.collection("events").whereField(FieldPath.documentID(), in: chunk).getDocuments { documentSnapshot, error in
                  defer { group.leave() }

                  if let error = error {
                      print("Error fetching event chunk: \(error.localizedDescription)")
                      return // Skip this chunk on error
                  }

                  guard let documents = documentSnapshot?.documents else {
                      print("No documents found for event chunk.")
                      return
                  }

                  for document in documents {
                      let data = document.data() // Non-optional for QueryDocumentSnapshot

                      // More robust decoding, handling potential missing fields gracefully
                      let eventId = document.documentID
                      let title = data["title"] as? String ?? "Untitled Event"
                      let category = data["category"] as? String ?? "Uncategorized"
                      let attendanceCount = data["attendanceCount"] as? Int ?? 0
                      let organizerName = data["organizerName"] as? String ?? "Unknown Organizer"
                      let date = data["date"] as? String ?? "Unknown Date"
                      let time = data["time"] as? String ?? "Unknown Time"
                      let location = data["location"] as? String ?? "Unknown Location"
                      let locationDetails = data["locationDetails"] as? String ?? ""
                      let imageNameOrUrl = data["imageName"] as? String ?? "" // Can be URL or asset name
                      let speakersData = data["speakers"] as? [[String: String]] ?? []
                      let speakers = speakersData.compactMap { Speaker(name: $0["name"] ?? "", imageURL: $0["imageURL"] ?? "") }
                      let userId = data["userId"] as? String ?? ""
                      let description = data["description"] as? String ?? ""
                      let latitude = data["latitude"] as? Double
                      let longitude = data["longitude"] as? Double
                      let tags = data["tags"] as? [String] ?? []


                      let event = EventModel(
                          eventId: eventId,
                          title: title,
                          category: category,
                          attendanceCount: attendanceCount,
                          organizerName: organizerName,
                          date: date,
                          time: time,
                          location: location,
                          locationDetails: locationDetails,
                          imageName: imageNameOrUrl, // Keep original, cell handles URL/asset logic
                          speakers: speakers,
                          userId: userId,
                          description: description,
                          latitude: latitude,
                          longitude: longitude,
                          tags: tags
                      )
                      fetchedEvents.append(event)
                  }
              }
          }


        group.notify(queue: .main) { [weak self] in
             guard let self = self else { return }
             // Sort events, e.g., by date if possible, or keep Firestore's order
             // For simplicity, using Firestore's order here. Add sorting if needed.
            self.registeredEvents = fetchedEvents
            self.eventsTableView.reloadData()
            // Fetch friends count again to update the stats view with the correct event count
            self.fetchFriendsCount()
        }
    }


    private func updateProfile(with details: UserDetails) {
        guard let userId = Auth.auth().currentUser?.uid else {
             showErrorAlert(message: "Authentication error. Cannot save profile.")
             return
         }

        // Prepare data, ensuring nil values aren't sent if fields allow null
        // Firestore's updateData merges, so only changed fields are needed,
        // but sending all ensures consistency with the UserDetails struct.
        let data: [String: Any] = [
            "name": details.name,
            "Description": details.description,
            "ContactDetails": details.contact ?? "", // Use empty string if nil
            "profileImageURL": details.imageUrl,
            "githubUrl": details.githubUrl ?? "",
            "linkedinUrl": details.linkedinUrl ?? "",
            "techStack": details.techStack
        ]

        // Show loading indicator?
        // ...

        db.collection("users").document(userId).updateData(data) { [weak self] error in
            guard let self = self else { return }

            // Hide loading indicator?
            // ...

            DispatchQueue.main.async {
                if let error = error {
                    print("Error updating profile: \(error.localizedDescription)")
                    self.showErrorAlert(message: "Failed to save changes. Please try again.")
                    // Optionally revert UI changes or keep them optimistically?
                    return
                }

                print("Profile updated successfully for user \(userId)")

                // Show success message and pop VC (as implemented in EditProfileVC's save)
                // The EditProfileVC handles the success message and pop.
                // We just need to ensure the ProfileVC reloads its data when it appears again.
                // The viewWillAppear method already calls loadUserDetails().
            }
        }
    }

    // MARK: - Account Deletion Logic
    private func proceedWithAccountDeletion() {
        guard let user = Auth.auth().currentUser else {
            showErrorAlert(message: "Not logged in. Cannot delete account.")
            return
        }
        let userId = user.uid

        // Show loading/activity indicator - Implement this based on your UI framework
        // e.g., let activityIndicator = UIActivityIndicatorView(...)
        // view.addSubview(activityIndicator)
        // activityIndicator.startAnimating()
        print("Starting account deletion process for user: \(userId)")

        let deletionGroup = DispatchGroup() // Main group for the entire deletion process

        // 1. Delete Firestore Data (including related collections)
        deletionGroup.enter()
        print("Entering Firestore data deletion...")
        deleteFirestoreData(userId: userId, group: deletionGroup) { firestoreError in
            if let firestoreError = firestoreError {
                print("Firestore deletion failed with error: \(firestoreError.localizedDescription)")
                // Decide how to proceed. Maybe stop here and show error?
                // For now, we'll log and attempt Auth deletion anyway, but show an error later.
            } else {
                print("Firestore data deletion completed successfully.")
            }
            // Leave the group whether Firestore succeeded or failed, so Auth deletion can be attempted.
            deletionGroup.leave()
        }


        // 2. Delete Storage Data (Optional but recommended)
        deletionGroup.enter()
        print("Entering Storage data deletion...")
        deleteStorageData(userId: userId) { storageError in
            if let storageError = storageError {
                // Log error but don't block deletion if image doesn't exist or other issue
                print("Error deleting profile image from storage (or image doesn't exist): \(storageError.localizedDescription)")
            } else {
                print("Profile image deleted from storage successfully (or didn't exist).")
            }
            deletionGroup.leave() // Leave the group regardless of storage deletion success/failure
        }

        // 3. After Firestore/Storage deletion attempts, delete Auth user
        deletionGroup.notify(queue: .main) { [weak self] in
             guard let self = self else { return }
             print("All deletion pre-tasks finished. Attempting Auth user deletion...")

             user.delete { error in
                 // Hide loading indicator
                 // activityIndicator.stopAnimating()
                 // activityIndicator.removeFromSuperview()

                 if let error = error {
                     print("Error deleting Firebase Auth user: \(error.localizedDescription)")
                     // Handle specific errors like requiresRecentLogin
                     if let authError = error as NSError?, authError.code == AuthErrorCode.requiresRecentLogin.rawValue {
                         self.showErrorAlert(message: "Security check failed. Please log out and log back in again before deleting your account.")
                         // Optionally trigger re-authentication flow here if implemented
                     } else {
                         self.showErrorAlert(message: "Could not complete account deletion. \(error.localizedDescription)")
                     }
                 } else {
                     print("Firebase Auth user deleted successfully.")
                     // 4. Navigate User Out
                     self.showSuccessMessage("Account deleted successfully.") {
                        self.navigateToLoginScreen()
                     }
                 }
             }
         }
    }

    // MARK: - Firestore Deletion (Updated)
    private func deleteFirestoreData(userId: String, group outerGroup: DispatchGroup, completion: @escaping (Error?) -> Void) {
        let db = Firestore.firestore()
        let mainBatch = db.batch() // Use a single batch for most top-level deletes

        // --- Add top-level documents directly related to the user to the batch ---
        let userRef = db.collection("users").document(userId)
        mainBatch.deleteDocument(userRef) // Delete user document
        print("Marked user document for deletion in batch.")

        let interestRef = db.collection("Interest").document(userId)
        mainBatch.deleteDocument(interestRef) // Delete interests document
        print("Marked interests document for deletion in batch.")

        // Use an inner group to wait for all fetches needed *before* committing the main batch
        let fetchGroup = DispatchGroup()
        var encounteredError: Error? = nil // Track if any fetch fails

        // --- Fetch and add related documents/updates to the batch ---

        // 1. Delete registrations
        fetchGroup.enter()
        db.collection("registrations").whereField("uid", isEqualTo: userId).getDocuments { snapshot, error in
            defer { fetchGroup.leave() }
            if let error = error {
                print("Error fetching registrations for deletion: \(error.localizedDescription)")
                encounteredError = encounteredError ?? error // Keep first error
            } else if let documents = snapshot?.documents, !documents.isEmpty {
                documents.forEach { mainBatch.deleteDocument($0.reference) }
                print("Marked \(documents.count) registrations for deletion in batch.")
            } else {
                print("No registrations found for user.")
            }
        }

        // 2. Delete friends relationships (where user is userID)
        fetchGroup.enter()
        db.collection("friends").whereField("userID", isEqualTo: userId).getDocuments { snapshot, error in
            defer { fetchGroup.leave() }
            if let error = error {
                print("Error fetching friends (userID) for deletion: \(error.localizedDescription)")
                encounteredError = encounteredError ?? error
            } else if let documents = snapshot?.documents, !documents.isEmpty {
                documents.forEach { mainBatch.deleteDocument($0.reference) }
                print("Marked \(documents.count) 'userID' friends relations for deletion in batch.")
            } else {
                print("No 'userID' friend relations found.")
            }
        }

        // 3. Delete friends relationships (where user is friendID)
        fetchGroup.enter()
        db.collection("friends").whereField("friendID", isEqualTo: userId).getDocuments { snapshot, error in
            defer { fetchGroup.leave() }
            if let error = error {
                print("Error fetching friends (friendID) for deletion: \(error.localizedDescription)")
                encounteredError = encounteredError ?? error
            } else if let documents = snapshot?.documents, !documents.isEmpty {
                documents.forEach { mainBatch.deleteDocument($0.reference) }
                print("Marked \(documents.count) 'friendID' friends relations for deletion in batch.")
            } else {
                print("No 'friendID' friend relations found.")
            }
        }

        // 4. Delete chats where user is a participant (CAUTION: Deletes chat for all users)
        // Assumes a 'participantIds' array field exists in the 'chats' collection.
        fetchGroup.enter()
        db.collection("chats").whereField("participants", arrayContains: userId).getDocuments { snapshot, error in
            defer { fetchGroup.leave() }
            if let error = error {
                print("Error fetching chats for deletion: \(error.localizedDescription)")
                encounteredError = encounteredError ?? error
            } else if let documents = snapshot?.documents, !documents.isEmpty {
                documents.forEach { mainBatch.deleteDocument($0.reference) }
                print("Marked \(documents.count) chats (where user is participant) for deletion in batch.")
            } else {
                print("No chats found involving the user.")
            }
        }

        // 5. Handle 'groups' collection
        // 5a. Delete groups where user is the team lead
        fetchGroup.enter()
        db.collection("groups").whereField("createdBy", isEqualTo: userId).getDocuments { snapshot, error in
            defer { fetchGroup.leave() }
            if let error = error {
                print("Error fetching groups (as lead) for deletion: \(error.localizedDescription)")
                encounteredError = encounteredError ?? error
            } else if let documents = snapshot?.documents, !documents.isEmpty {
                // Also need to delete members subcollection for these groups
                documents.forEach { groupDoc in
                    mainBatch.deleteDocument(groupDoc.reference)
                    // Add subcollection deletion task
                    fetchGroup.enter()
                    self.deleteSubcollection(parentRef: groupDoc.reference, collectionName: "members") { subError in
                         if let subError = subError {
                             print("Error deleting 'members' subcollection for group \(groupDoc.documentID): \(subError.localizedDescription)")
                             encounteredError = encounteredError ?? subError
                         } else {
                             print("Deleted 'members' subcollection for group \(groupDoc.documentID).")
                         }
                         fetchGroup.leave()
                    }
                }
                print("Marked \(documents.count) groups (where user is lead) for deletion in batch.")
            } else {
                print("No groups found where user is the lead.")
            }
        }
        
        // 5b. Attempt to delete user's doc from 'members' subcollection in all groups where they are NOT the leader
        // (Since there's no memberIds array, we fetch all groups and attempt deletion)
        fetchGroup.enter()
        db.collection("groups").getDocuments { snapshot, error in
            defer { fetchGroup.leave() }
            if let error = error {
                print("Error fetching all groups for member deletion check: \(error.localizedDescription)")
                encounteredError = encounteredError ?? error
            } else if let documents = snapshot?.documents, !documents.isEmpty {
                var deleteAttemptCount = 0
                documents.forEach { doc in
                    // Check if the user being deleted is NOT the team lead of this group
                    if doc.data()["createdBy"] as? String != userId {
                        // Construct the reference to the potential member document
                        let memberDocRef = doc.reference.collection("members").document(userId)
                        // Add deletion to the batch. It will do nothing if the doc doesn't exist.
                        mainBatch.deleteDocument(memberDocRef)
                        deleteAttemptCount += 1
                    }
                }
                if deleteAttemptCount > 0 {
                    // Note: This count includes groups the user might not have been in, but where deletion was attempted.
                    print("Marked potential member doc deletion in \(deleteAttemptCount) groups (where user wasn't lead) in batch.")
                }
            } else {
                print("No groups found to check for member deletion.")
            }
        }


        // 6. Handle 'eventGroups' collection (assuming same structure as groups)
        // 6a. Delete eventGroups where user is the team lead
        fetchGroup.enter()
        db.collection("eventGroups").whereField("organizer", isEqualTo: userId).getDocuments { snapshot, error in
            defer { fetchGroup.leave() }
            if let error = error {
                print("Error fetching eventGroups (as lead) for deletion: \(error.localizedDescription)")
                encounteredError = encounteredError ?? error
            } else if let documents = snapshot?.documents, !documents.isEmpty {
                 // Also need to delete members subcollection for these eventGroups
                 documents.forEach { groupDoc in
                     mainBatch.deleteDocument(groupDoc.reference)
                     // Add subcollection deletion task
                     fetchGroup.enter()
                     self.deleteSubcollection(parentRef: groupDoc.reference, collectionName: "members") { subError in
                         if let subError = subError {
                             print("Error deleting 'members' subcollection for eventGroup \(groupDoc.documentID): \(subError.localizedDescription)")
                             encounteredError = encounteredError ?? subError
                         } else {
                             print("Deleted 'members' subcollection for eventGroup \(groupDoc.documentID).")
                         }
                         fetchGroup.leave()
                     }
                 }
                print("Marked \(documents.count) eventGroups (where user is lead) for deletion in batch.")
            } else {
                print("No eventGroups found where user is the lead.")
            }
        }
        
        // 6b. Attempt to delete user's doc from 'members' subcollection in all eventGroups where they are NOT the leader
        // (Since there's no memberIds array, we fetch all groups and attempt deletion)
        fetchGroup.enter()
        db.collection("eventGroups").getDocuments { snapshot, error in
            defer { fetchGroup.leave() }
            if let error = error {
                print("Error fetching all eventGroups for member deletion check: \(error.localizedDescription)")
                encounteredError = encounteredError ?? error
            } else if let documents = snapshot?.documents, !documents.isEmpty {
                var deleteAttemptCount = 0
                documents.forEach { doc in
                    // Check if the user being deleted is NOT the team lead of this group
                    if doc.data()["organizer"] as? String != userId {
                        // Construct the reference to the potential member document
                        let memberDocRef = doc.reference.collection("members").document(userId)
                        // Add deletion to the batch. It will do nothing if the doc doesn't exist.
                        mainBatch.deleteDocument(memberDocRef)
                        deleteAttemptCount += 1
                    }
                }
                if deleteAttemptCount > 0 {
                    // Note: This count includes groups the user might not have been in, but where deletion was attempted.
                    print("Marked potential member doc deletion in \(deleteAttemptCount) eventGroups (where user wasn't lead) in batch.")
                }
            } else {
                print("No eventGroups found to check for member deletion.")
            }
        }

        // --- Handle Subcollection Deletion under the USER document ---
        // Example: If user doc had subcollections like 'notifications', 'settings'
        fetchGroup.enter()
        deleteSubcollection(parentRef: userRef, collectionName: "chats") { error in // Assuming chats was under user before
             if let error = error { print("Error deleting 'chats' subcollection under user: \(error.localizedDescription)"); encounteredError = encounteredError ?? error }
             else { print("Deleted 'chats' subcollection under user (or was empty).") }
             fetchGroup.leave()
         }
         fetchGroup.enter()
         deleteSubcollection(parentRef: userRef, collectionName: "groups") { error in // Assuming groups was under user before
             if let error = error { print("Error deleting 'groups' subcollection under user: \(error.localizedDescription)"); encounteredError = encounteredError ?? error }
             else { print("Deleted 'groups' subcollection under user (or was empty).") }
             fetchGroup.leave()
         }
        // Add more calls to deleteSubcollection here if the user document has other subcollections


        // --- Commit the main batch after all fetches are done ---
        fetchGroup.notify(queue: .global()) { // Use a global queue for commit task
            // Check if any fetch operation failed before committing
            if let fetchError = encounteredError {
                 print("Skipping main batch commit due to fetch error: \(fetchError.localizedDescription)")
                 completion(fetchError) // Report the fetch error
                 return // Don't commit if fetches failed
             }

            print("All fetches complete. Attempting to commit Firestore main batch delete...")
            mainBatch.commit { commitError in
                // This completion block runs on the main thread by default
                if let commitError = commitError {
                    print("Error committing main Firestore batch delete: \(commitError.localizedDescription)")
                    completion(commitError) // Report the commit error
                } else {
                    print("Main Firestore batch delete committed successfully.")
                    completion(nil) // Signal success
                }
            }
        }
    }

    // Helper function to delete all documents in a subcollection recursively
    // Use with caution on very large subcollections. Consider Cloud Functions for > few thousand docs.
    private func deleteSubcollection(parentRef: DocumentReference, collectionName: String, completion: @escaping (Error?) -> Void) {
        let subcollectionRef = parentRef.collection(collectionName)
        // Process in chunks (Firestore batch limit is 500)
        subcollectionRef.limit(to: 300).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching batch for subcollection '\(collectionName)' under \(parentRef.path): \(error.localizedDescription)")
                completion(error)
                return
            }
            guard let snapshot = snapshot, !snapshot.isEmpty else {
                // Subcollection is empty or this chunk is empty, we're done with this path.
                // print("Subcollection '\(collectionName)' under \(parentRef.path) is empty or finished.")
                completion(nil)
                return
            }

            // Create a new batch for this chunk deletion
            let batch = parentRef.firestore.batch()
            snapshot.documents.forEach { batch.deleteDocument($0.reference) }

            // Commit the batch for this chunk
            batch.commit { commitError in
                if let commitError = commitError {
                    print("Error committing delete batch for subcollection '\(collectionName)' under \(parentRef.path): \(commitError.localizedDescription)")
                    completion(commitError)
                } else {
                    // Deletion of this batch successful, check if there might be more documents
                    if snapshot.count < 300 {
                        // If we deleted less than the limit, we're likely done.
                        // print("Finished deleting subcollection '\(collectionName)' under \(parentRef.path).")
                        completion(nil)
                    } else {
                        // There might be more documents, recurse to delete the next batch
                        // print("Deleting next batch for subcollection '\(collectionName)' under \(parentRef.path)...")
                        // Use DispatchQueue.main.async to avoid potential stack overflow on deep recursion
                        DispatchQueue.main.async {
                             self.deleteSubcollection(parentRef: parentRef, collectionName: collectionName, completion: completion)
                        }
                    }
                }
            }
        }
    }


    // MARK: - Storage Deletion
    private func deleteStorageData(userId: String, completion: @escaping (Error?) -> Void) {
        let storageRef = Storage.storage().reference().child("profile_images/\(userId).jpg")

        storageRef.delete { error in
            if let error = error {
                 // Check if the error is 'object not found' - this is not a failure in deletion context
                 if (error as NSError).code == StorageErrorCode.objectNotFound.rawValue {
                     print("Profile image not found in storage for user \(userId) - considered success for deletion.")
                     completion(nil) // Object not found is okay here
                 } else {
                     print("Error deleting profile image from storage for user \(userId): \(error.localizedDescription)")
                     completion(error) // Report other errors
                 }
            } else {
                print("Profile image deleted from storage successfully for user \(userId).")
                completion(nil) // Signal success
            }
        }
    }


    // MARK: - Navigation
    private func navigateToLoginScreen() {
        // Assuming GeneralTabbarController is the entry point after login/signup
        // Or replace with your specific LoginViewController if that's the root
        let initialViewController = GeneralTabbarController() // Or LoginViewController()

        // Use SceneDelegate (iOS 13+) or AppDelegate (older) to change root view controller
        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate,
           let window = sceneDelegate.window {

            // Optional: Add a transition animation
            UIView.transition(with: window, duration: 0.4, options: .transitionCrossDissolve, animations: {
                 window.rootViewController = initialViewController // Wrap in UINavigationController if login screen needs it
            }, completion: nil)
            window.makeKeyAndVisible()

        } else if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                  let window = appDelegate.window {
             // Fallback for older iOS versions or if SceneDelegate setup differs
             UIView.transition(with: window, duration: 0.4, options: .transitionCrossDissolve, animations: {
                  window.rootViewController = initialViewController
             }, completion: nil)
             window.makeKeyAndVisible()
        }
         else {
            print("Could not get SceneDelegate/AppDelegate or window to navigate after logout/delete.")
            // Fallback: Dismiss if presented modally, or pop to root if in navigation stack
             if let nav = self.navigationController {
                 // Pop to root might leave user on an unexpected screen if root isn't login
                 // Consider presenting login modally from the root if appropriate
                 nav.popToRootViewController(animated: false)
                 // Or force presentation if root isn't login:
                 // let loginVC = LoginViewController() // Instantiate your login VC
                 // loginVC.modalPresentationStyle = .fullScreen
                 // nav.present(loginVC, animated: true, completion: nil)

             } else if self.presentingViewController != nil {
                 self.dismiss(animated: true, completion: nil)
             }
        }
    }


    // MARK: - Helper Alerts
    private func showSuccessMessage(_ message: String, completion: (() -> Void)? = nil) {
        // Ensure presentation on main thread
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
            self.present(alert, animated: true)

            // Auto-dismiss after 1.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                alert.dismiss(animated: true) {
                    completion?() // Execute completion handler
                }
            }
        }
    }

    private func showErrorAlert(message: String) {
        // Ensure presentation on main thread
         DispatchQueue.main.async {
              let alert = UIAlertController(
                  title: "Error",
                  message: message,
                  preferredStyle: .alert
              )
              alert.addAction(UIAlertAction(title: "OK", style: .default))
              // Avoid presenting if already presenting something else
              if self.presentedViewController == nil {
                   self.present(alert, animated: true)
              } else {
                   print("Attempted to present error alert while another view controller is already presented. Message: \(message)")
              }
         }
    }

    private func presentImagePicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true

        present(imagePicker, animated: true)
    }

    // MARK: - Image Picker Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)

        guard let editedImage = info[.editedImage] as? UIImage,
              let userId = Auth.auth().currentUser?.uid else {
             print("Could not get edited image or user ID.")
             return
         }

        // Show loading indicator?
        // ...

        uploadProfileImage(editedImage, for: userId) { [weak self] imageURLString in
             guard let self = self, let imageURL = imageURLString else {
                 // Hide loading indicator
                 // ...
                 self?.showErrorAlert(message: "Failed to upload image.")
                 return
             }

             // Update Firestore with the new URL
             self.db.collection("users").document(userId).updateData(["profileImageURL": imageURL]) { error in
                 // Hide loading indicator
                 // ...
                 if let error = error {
                     print("Error updating profile image URL in Firestore: \(error.localizedDescription)")
                     self.showErrorAlert(message: "Failed to save image reference.")
                 } else {
                     print("Profile image URL updated successfully.")
                     // Update the UI immediately
                     DispatchQueue.main.async {
                         self.profileImageView.image = editedImage
                     }
                 }
             }
         }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    private func uploadProfileImage(_ image: UIImage, for userId: String, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else { // Adjust compression as needed
             print("Could not get JPEG data from image.")
             completion(nil)
             return
         }

        let storageRef = Storage.storage().reference().child("profile_images/\(userId).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        storageRef.putData(imageData, metadata: metadata) { _, error in
            if let error = error {
                print("Error uploading image to Firebase Storage: \(error.localizedDescription)")
                completion(nil)
                return
            }

            // Get download URL after successful upload
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    completion(nil)
                } else if let url = url {
                    completion(url.absoluteString)
                } else {
                    print("Download URL was nil despite successful upload.")
                    completion(nil)
                }
            }
        }
    }

    // MARK: - RegisteredEventCellDelegate
    func didTapUnregister(event: EventModel) {
        let alert = UIAlertController(
            title: "Unregister",
            message: "Are you sure you want to unregister from \"\(event.title)\"?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { [weak self] _ in
            self?.unregisterEvent(event)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alert, animated: true)
    }

    private func unregisterEvent(_ event: EventModel) {
        guard let userId = Auth.auth().currentUser?.uid else {
             showErrorAlert(message: "Authentication error. Cannot unregister.")
             return
         }

        // Find the registration document
        db.collection("registrations")
            .whereField("uid", isEqualTo: userId)
            .whereField("eventId", isEqualTo: event.eventId)
            .limit(to: 1) // Expect only one registration per user per event
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Error fetching registration for unregistration: \(error.localizedDescription)")
                    self.showErrorAlert(message: "Could not find registration to remove.")
                    return
                }

                guard let document = snapshot?.documents.first else {
                    print("No registration found for event \(event.eventId) and user \(userId). Already unregistered?")
                    // Optionally show a message, but often failing silently is fine here.
                    // Refresh the list just in case.
                     self.loadRegisteredEvents()
                    return
                }

                // Delete the found registration document
                document.reference.delete { error in
                    if let error = error {
                        print("Error deleting registration: \(error.localizedDescription)")
                        self.showErrorAlert(message: "Failed to unregister. Please try again.")
                    } else {
                        print("Successfully unregistered from event \(event.eventId)")
                        // Remove locally and update UI immediately for responsiveness
                        // Use optional binding for safe removal
                        if let index = self.registeredEvents.firstIndex(where: { $0.eventId == event.eventId }) {
                             self.registeredEvents.remove(at: index)
                             DispatchQueue.main.async {
                                 // Animate deletion if possible
                                 if self.eventsTableView.numberOfRows(inSection: 0) > index {
                                     self.eventsTableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                                 } else {
                                     self.eventsTableView.reloadData() // Fallback reload
                                 }
                                 // Update the stats view
                                 self.fetchFriendsCount() // Recalculates stats with updated event count
                             }
                        } else {
                             // If not found locally (shouldn't happen often), just reload
                             DispatchQueue.main.async {
                                 self.eventsTableView.reloadData()
                                 self.fetchFriendsCount()
                             }
                        }
                        self.showSuccessMessage("Unregistered from \"\(event.title)\"")
                    }
                }
            }
    }

    // MARK: - UITableView DataSource & Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Optional: Show a placeholder view when count is 0
        // tableView.backgroundView = registeredEvents.isEmpty ? placeholderView : nil
        return registeredEvents.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RegisteredEventCell.identifier, for: indexPath) as? RegisteredEventCell else {
             fatalError("Could not dequeue RegisteredEventCell") // Should not happen if registered
         }
        // Safely access event using optional binding or safe subscript
        guard registeredEvents.indices.contains(indexPath.row) else {
              print("Index out of bounds for registeredEvents: \(indexPath.row)")
              // Return an empty configured cell or handle error
              // cell.configure(with: /* default/empty event */)
              return cell
          }
        let event = registeredEvents[indexPath.row] // Now safe to access
        cell.configure(with: event)
        cell.delegate = self
        cell.selectionStyle = .default // Allow selection to show feedback before navigating
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true) // Deselect immediately
        // Safely access event
        guard registeredEvents.indices.contains(indexPath.row) else {
              print("Index out of bounds for registeredEvents on selection")
              return
          }
        let selectedEvent = registeredEvents[indexPath.row]
        let ticketVC = TicketViewController()
        ticketVC.eventId = selectedEvent.eventId
        // Pass event details if already fetched and needed by TicketVC
         // ticketVC.eventDetails = [:] // Populate if needed
        navigationController?.pushViewController(ticketVC, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80 // Keep fixed height for simplicity
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension ProfileViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return techStackItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TechStackCell.identifier, for: indexPath) as? TechStackCell else {
             fatalError("Could not dequeue TechStackCell")
         }
         // Safely access tech stack item
         guard indexPath.item < techStackItems.count else {
              print("Index out of bounds for techStackItems")
              return cell // Return empty configured cell
          }
        cell.configure(with: techStackItems[indexPath.item])
        return cell
    }

    // Use estimatedItemSize in the layout instead of this delegate method for self-sizing cells
    // func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize

    // Optional: Provide estimated size for better performance with self-sizing
    // func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, estimatedSizeForItemAt indexPath: IndexPath) -> CGSize {
    //     return CGSize(width: 100, height: 32) // Provide a reasonable estimate
    // }
}

// MARK: - TechStackCell
class TechStackCell: UICollectionViewCell {
    static let identifier = "TechStackCell"
    
    private let label: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(label)
        contentView.backgroundColor = .systemOrange
        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true
        
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)
        ])
    }
    
    func configure(with text: String) {
        label.text = text
    }
}

import UIKit
import FirebaseAuth
import FirebaseStorage

class EditProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var name: String?
    var descriptionText: String?
    var contact: String?
    var githubUrl: String?
    var linkedinUrl: String?
    var techStack: String?
    var imageUrl: String?
    var onSave: ((UserDetails) -> Void)?
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 50
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        return imageView
    }()
    
    private let selectImageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Select Image", for: .normal)
        button.addTarget(self, action: #selector(handleSelectImage), for: .touchUpInside)
        return button
    }()
    
    private let nameTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.placeholder = "Enter name"
        return textField
    }()
    
    private let descriptionTextView: UITextView = {
        let textView = UITextView()
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.cornerRadius = 8
        textView.font = UIFont.systemFont(ofSize: 16)
        return textView
    }()
    
    private let contactTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.placeholder = "Enter contact"
        return textField
    }()
    
    private let githubTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.placeholder = "Enter GitHub URL"
        return textField
    }()
    
    private let linkedinTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.placeholder = "Enter LinkedIn URL"
        return textField
    }()
    
    private let techStackTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.placeholder = "Enter Tech Stack"
        return textField
    }()
    
    private let addTechStackButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add", for: .normal)
        button.backgroundColor = .systemOrange
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(handleAddTechStack), for: .touchUpInside)
        return button
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.backgroundColor = .systemOrange
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        populateFields()
    }


    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(profileImageView)
        view.addSubview(selectImageButton)
        view.addSubview(nameTextField)
        view.addSubview(descriptionTextView)
        view.addSubview(contactTextField)
        view.addSubview(githubTextField)
        view.addSubview(linkedinTextField)
        view.addSubview(techStackTextField)
        view.addSubview(addTechStackButton)
        view.addSubview(saveButton)
    }
    
    private func setupConstraints() {
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        selectImageButton.translatesAutoresizingMaskIntoConstraints = false
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        contactTextField.translatesAutoresizingMaskIntoConstraints = false
        githubTextField.translatesAutoresizingMaskIntoConstraints = false
        linkedinTextField.translatesAutoresizingMaskIntoConstraints = false
        techStackTextField.translatesAutoresizingMaskIntoConstraints = false
        addTechStackButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),
            
            selectImageButton.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 10),
            selectImageButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            nameTextField.topAnchor.constraint(equalTo: selectImageButton.bottomAnchor, constant: 20),
            nameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            descriptionTextView.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 20),
            descriptionTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            descriptionTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            descriptionTextView.heightAnchor.constraint(equalToConstant: 100),
            
            contactTextField.topAnchor.constraint(equalTo: descriptionTextView.bottomAnchor, constant: 20),
            contactTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            contactTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            githubTextField.topAnchor.constraint(equalTo: contactTextField.bottomAnchor, constant: 20),
            githubTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            githubTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            linkedinTextField.topAnchor.constraint(equalTo: githubTextField.bottomAnchor, constant: 20),
            linkedinTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            linkedinTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            techStackTextField.topAnchor.constraint(equalTo: linkedinTextField.bottomAnchor, constant: 20),
            techStackTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            techStackTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            addTechStackButton.topAnchor.constraint(equalTo: techStackTextField.bottomAnchor, constant: 10),
            addTechStackButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addTechStackButton.widthAnchor.constraint(equalToConstant: 50),
            addTechStackButton.heightAnchor.constraint(equalToConstant: 30),
            
            saveButton.topAnchor.constraint(equalTo: addTechStackButton.bottomAnchor, constant: 20),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 100),
            saveButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func populateFields() {
        nameTextField.text = name
        descriptionTextView.text = descriptionText
        contactTextField.text = contact
        githubTextField.text = githubUrl
        linkedinTextField.text = linkedinUrl
        techStackTextField.text = techStack
        if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
            loadProfileImage(from: url)
        } else {
            profileImageView.image = UIImage(named: "default_profile")
        }
    }
    
    private func loadProfileImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.profileImageView.image = image
                }
            }
        }.resume()
    }
    
    @objc private func handleSelectImage() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        if let editedImage = info[.editedImage] as? UIImage {
            profileImageView.image = editedImage
        }
    }
    
    //    @objc private func handleSave() {
    //        guard
    //            let updatedName = nameTextField.text,
    //            let updatedDescription = descriptionTextView.text,
    //            let updatedContact = contactTextField.text,
    //            let updatedGithubUrl = githubTextField.text,
    //            let updatedLinkedinUrl = linkedinTextField.text,
    //            let updatedTechStack = techStackTextField.text,
    //            let profileImage = profileImageView.image,
    //            let imageData = profileImage.jpegData(compressionQuality: 0.8),
    //            let userId = Auth.auth().currentUser?.uid
    //        else { return }
    //
    //        let storageRef = Storage.storage().reference().child("profile_images/\(userId).jpg")
    //        storageRef.putData(imageData, metadata: nil) { _, error in
    //            guard error == nil else { return }
    //
    //            storageRef.downloadURL { [weak self] url, error in
    //                guard let url = url else { return }
    //
    //                let details = UserDetails(
    //                    id: userId,
    //                    name: updatedName,
    //                    description: updatedDescription,
    //                    imageUrl: url.absoluteString, contact: updatedContact,
    //                    githubUrl: updatedGithubUrl,
    //                    linkedinUrl: updatedLinkedinUrl,
    //                    techStack: updatedTechStack
    //                )
    //
    //                self?.onSave?(details)
    //                self?.navigationController?.popViewController(animated: true)
    //            }
    //        }
    //    }
    @objc private func handleSave() {
        guard
            let updatedName = nameTextField.text,
            let updatedDescription = descriptionTextView.text,
            let updatedContact = contactTextField.text,
            let updatedGithubUrl = githubTextField.text,
            let updatedLinkedinUrl = linkedinTextField.text,
            let updatedTechStack = techStackTextField.text
        else { return }
        
        // If no new image was selected, use the existing image URL
        if profileImageView.image == UIImage(named: "default_profile") {
            let details = UserDetails(
                id: Auth.auth().currentUser?.uid ?? "",
                name: updatedName,
                description: updatedDescription,
                imageUrl: self.imageUrl ?? "",
                contact: updatedContact,
                githubUrl: updatedGithubUrl,
                linkedinUrl: updatedLinkedinUrl,
                techStack: updatedTechStack
            )
            
            self.onSave?(details)
            self.showSuccessAlert()
            self.navigationController?.popViewController(animated: true)
        } else {
            // Only upload new image if it was changed
            guard let profileImage = profileImageView.image,
                  let imageData = profileImage.jpegData(compressionQuality: 0.8),
                  let userId = Auth.auth().currentUser?.uid else { return }
            
            let storageRef = Storage.storage().reference().child("profile_images/\(userId).jpg")
            storageRef.putData(imageData, metadata: nil) { _, error in
                guard error == nil else {
                    print("Error uploading image: \(error!.localizedDescription)")
                    return
                }
                
                storageRef.downloadURL { [weak self] url, error in
                    guard let url = url else {
                        print("Error getting download URL: \(error?.localizedDescription ?? "")")
                        return
                    }
                    
                    let details = UserDetails(
                        id: userId,
                        name: updatedName,
                        description: updatedDescription,
                        imageUrl: url.absoluteString,
                        contact: updatedContact,
                        githubUrl: updatedGithubUrl,
                        linkedinUrl: updatedLinkedinUrl,
                        techStack: updatedTechStack
                    )
                    
                    self?.onSave?(details)
                    self?.showSuccessAlert()
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    private func showSuccessAlert() {
        let alert = UIAlertController(
            title: "Success",
            message: "Your changes have been saved",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func handleAddTechStack() {
        let techStackVC = TechStackViewController()
        techStackVC.userID = Auth.auth().currentUser?.uid
        
        // Convert the current tech stack text into an array
        let currentTechStack = self.techStackTextField.text?.components(separatedBy: ", ") ?? []
        techStackVC.selectedTechStack = currentTechStack
        
        // Handle the save callback
        techStackVC.onSave = { [weak self] selectedTechStack in
            // Update the text field with the selected items
            self?.techStackTextField.text = selectedTechStack.joined(separator: ", ")
            
            // Show just one success message here
            let alert = UIAlertController(title: "Updated",
                                        message: "Your tech stack has been updated",
                                        preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
        
        navigationController?.pushViewController(techStackVC, animated: true)
    }
}

#Preview{
    ProfileViewController()
}

