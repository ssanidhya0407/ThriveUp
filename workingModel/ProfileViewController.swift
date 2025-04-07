import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

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
    
//    private let githubLabel: UILabel = {
//        let label = UILabel()
//        label.text = "GitHub: Not available"
//        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
//        label.textColor = .label
//        label.numberOfLines = 0
//        return label
//    }()
    
    private let githubLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black
        label.numberOfLines = 0
        label.lineBreakMode = .byCharWrapping
        label.isUserInteractionEnabled = true
        return label
    }()
    
    private let linkedinLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .systemGray
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
    
//    private let techStackHeader: UILabel = {
//        let label = UILabel()
//        label.text = "TECH STACK"
//        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
//        label.textColor = .tertiaryLabel
//        return label
//    }()
    
    // Make sure you have this in your properties section
    // Update the techStackHeader properties to make it more visible
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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        configureNavigationBar()
        loadUserDetails()
        loadUserInterests()
        loadRegisteredEvents()
        fetchFriendsCount()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateFriendCount), name: NSNotification.Name("FriendCountUpdated"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUserDetails()
    }
    
    // MARK: - UI Setup
//    private func setupUI() {
//        view.backgroundColor = .systemBackground
//
//        // Scroll View
//        view.addSubview(scrollView)
//        scrollView.addSubview(contentView)
//
//        // Profile Header
//        contentView.addSubview(profileImageView)
//        contentView.addSubview(nameLabel)
//        contentView.addSubview(emailLabel)
//
//        // Stats
//        contentView.addSubview(statsContainer)
//        statsContainer.addSubview(statsStack)
//
//        // Segment Control
//        contentView.addSubview(segmentControl)
//        segmentControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
//
//        // Details Container
//        contentView.addSubview(detailsContainer)
//        detailsContainer.addSubview(detailsStackView)
//
//        // Description
//        detailsStackView.addArrangedSubview(descriptionLabel)
//
//        // Contact Info
//        contactStack.addArrangedSubview(contactHeader)
//        contactStack.addArrangedSubview(contactDetailsLabel)
//        detailsStackView.addArrangedSubview(contactStack)
//
//        // Social Links
//        socialStack.addArrangedSubview(socialHeader)
//        socialStack.addArrangedSubview(githubLabel)
//        socialStack.addArrangedSubview(linkedinLabel)
//        detailsStackView.addArrangedSubview(socialStack)
//
//        // Tech Stack
//        contentView.addSubview(techStackContainer)
//        techStackContainer.addSubview(techStackHeader)
//        techStackContainer.addSubview(techStackCollectionView)
//
//        // Events Table
//        contentView.addSubview(eventsTableView)
//        eventsTableView.dataSource = self
//        eventsTableView.delegate = self
//
//        // Add gesture recognizers
////        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapFriendsLabel))
////        statsContainer.addGestureRecognizer(tapGesture)
//
//        let imageTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleImageTap))
//        profileImageView.isUserInteractionEnabled = true
//        profileImageView.addGestureRecognizer(imageTapGesture)
//    }
    // Then modify the setupUI() function to use these new views:
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
        
        // Tech Stack
        contentView.addSubview(techStackContainer)
            techStackContainer.addSubview(techStackHeader)  // Make sure this comes first
            techStackContainer.addSubview(techStackCollectionView)
        
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
        techStackContainer.translatesAutoresizingMaskIntoConstraints = false
           techStackHeader.translatesAutoresizingMaskIntoConstraints = false
           techStackCollectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            techStackContainer.topAnchor.constraint(equalTo: detailsContainer.bottomAnchor, constant: 16),
                 techStackContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                 techStackContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                 
                 techStackHeader.topAnchor.constraint(equalTo: techStackContainer.topAnchor, constant: 16),
                 techStackHeader.leadingAnchor.constraint(equalTo: techStackContainer.leadingAnchor, constant: 16),
                 techStackHeader.trailingAnchor.constraint(equalTo: techStackContainer.trailingAnchor, constant: -16),
                 
                 techStackCollectionView.topAnchor.constraint(equalTo: techStackHeader.bottomAnchor, constant: 8),
                 techStackCollectionView.leadingAnchor.constraint(equalTo: techStackContainer.leadingAnchor, constant: 16),
                 techStackCollectionView.trailingAnchor.constraint(equalTo: techStackContainer.trailingAnchor, constant: -16),
                 techStackCollectionView.bottomAnchor.constraint(equalTo: techStackContainer.bottomAnchor, constant: -16),
            techStackCollectionView.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
    
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Profile Image
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        // Name and Email
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            nameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            emailLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
        
        // Make sure the tech stack container has a bottom constraint
        if techStackContainer.constraints.first(where: {
            $0.firstAttribute == .bottom && $0.firstItem as? UIView == contentView
        }) == nil {
            techStackContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24).isActive = true
        }
        // Stats Container
        statsContainer.translatesAutoresizingMaskIntoConstraints = false
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statsContainer.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 24),
            statsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statsContainer.heightAnchor.constraint(equalToConstant: 100),
            
            statsStack.topAnchor.constraint(equalTo: statsContainer.topAnchor, constant: 16),
            statsStack.leadingAnchor.constraint(equalTo: statsContainer.leadingAnchor, constant: 16),
            statsStack.trailingAnchor.constraint(equalTo: statsContainer.trailingAnchor, constant: -16),
            statsStack.bottomAnchor.constraint(equalTo: statsContainer.bottomAnchor, constant: -16)
        ])
        
        // Segment Control
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            segmentControl.topAnchor.constraint(equalTo: statsContainer.bottomAnchor, constant: 24),
            segmentControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            segmentControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            segmentControl.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Details Container
        detailsContainer.translatesAutoresizingMaskIntoConstraints = false
        detailsStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            detailsContainer.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 16),
            detailsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            detailsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            detailsStackView.topAnchor.constraint(equalTo: detailsContainer.topAnchor, constant: 16),
            detailsStackView.leadingAnchor.constraint(equalTo: detailsContainer.leadingAnchor, constant: 16),
            detailsStackView.trailingAnchor.constraint(equalTo: detailsContainer.trailingAnchor, constant: -16),
            detailsStackView.bottomAnchor.constraint(equalTo: detailsContainer.bottomAnchor, constant: -16)
        ])
        // Set fixed height constraint
        detailsStackView.heightAnchor.constraint(equalToConstant: 205).isActive = true

        // Or set width constraint
        detailsStackView.widthAnchor.constraint(equalToConstant: 150).isActive = true
       
        // Tech Stack Container
        techStackContainer.translatesAutoresizingMaskIntoConstraints = false
        techStackHeader.translatesAutoresizingMaskIntoConstraints = false
        techStackCollectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            techStackContainer.topAnchor.constraint(equalTo: detailsContainer.bottomAnchor, constant: 16),
            techStackContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            techStackContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            techStackContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            
            techStackHeader.topAnchor.constraint(equalTo: techStackContainer.topAnchor, constant: 16),
            techStackHeader.leadingAnchor.constraint(equalTo: techStackContainer.leadingAnchor, constant: 16),
            techStackHeader.trailingAnchor.constraint(equalTo: techStackContainer.trailingAnchor, constant: -16),
            
            techStackCollectionView.topAnchor.constraint(equalTo: techStackHeader.bottomAnchor, constant: 12),
            techStackCollectionView.leadingAnchor.constraint(equalTo: techStackContainer.leadingAnchor, constant: 16),
            techStackCollectionView.trailingAnchor.constraint(equalTo: techStackContainer.trailingAnchor, constant: -16),
            techStackCollectionView.bottomAnchor.constraint(equalTo: techStackContainer.bottomAnchor, constant: -16),
            techStackCollectionView.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        ])
        
        // Events Table
        eventsTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            eventsTableView.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 16),
            eventsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            eventsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            eventsTableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            eventsTableView.heightAnchor.constraint(equalToConstant: 400)
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
        eventsTableView.isHidden = !isShowingEvents
        
        if isShowingEvents {
            loadRegisteredEvents()
        }
    }
    
    @objc private func handleEdit() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not authenticated.")
            return
        }
        
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists,
                  let profileImageUrl = document.data()?["profileImageURL"] as? String else {
                print("No valid profile image URL found.")
                return
            }
            
            let editVC = EditProfileViewController()
            editVC.name = self.nameLabel.text
            editVC.descriptionText = self.descriptionLabel.text?.replacingOccurrences(of: "Description: ", with: "")
            editVC.contact = self.contactDetailsLabel.text?.replacingOccurrences(of: "Contact: ", with: "")
            editVC.githubUrl = document.data()?["githubUrl"] as? String
            editVC.linkedinUrl = document.data()?["linkedinUrl"] as? String
            editVC.techStack = document.data()?["techStack"] as? String
            editVC.imageUrl = profileImageUrl
            
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
        let userTabBarController = GeneralTabbarController()
        
        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate {
            sceneDelegate.window?.rootViewController = userTabBarController
            sceneDelegate.window?.makeKeyAndVisible()
        }
    }
    
    @objc private func didTapFriendsLabel() {
        let friendsVC = FriendsViewController()
        friendsVC.currentUser = User(id: Auth.auth().currentUser?.uid ?? "", name: nameLabel.text ?? "Unknown")
        navigationController?.pushViewController(friendsVC, animated: true)
    }
    
    @objc private func updateFriendCount() {
        fetchFriendsCount()
    }
    
    // MARK: - Data Loading
    private func loadUserDetails() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not authenticated.")
            return
        }
        
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching user details: \(error.localizedDescription)")
                return
            }
            
            guard let data = document?.data() else {
                print("No user data found for userId: \(userId)")
                return
            }
            
            DispatchQueue.main.async {
                self.nameLabel.text = data["name"] as? String ?? "Name"
                self.emailLabel.text = data["email"] as? String ?? "Email"
                
                if let contact = data["ContactDetails"] as? String, !contact.isEmpty {
                    self.contactDetailsLabel.text = contact
                } else {
                    self.contactDetailsLabel.text = "Not available"
                }
                
                if let description = data["Description"] as? String, !description.isEmpty {
                    self.descriptionLabel.text = description
                } else {
                    self.descriptionLabel.text = "No description available"
                }
                
//                if let github = data["githubUrl"] as? String, !github.isEmpty {
//                    self.githubLabel.text = "GitHub: \(github)"
//                } else {
//                    self.githubLabel.text = "GitHub: Not available"
//                }
//
//                if let linkedin = data["linkedinUrl"] as? String, !linkedin.isEmpty {
//                    self.linkedinLabel.text = "LinkedIn: \(linkedin)"
//                } else {
//                    self.linkedinLabel.text = "LinkedIn: Not available"
//                }
                // Then in your loadUserDetails() method, update the GitHub/LinkedIn section:
                // In the loadUserDetails() method, update the GitHub/LinkedIn section:
                if let github = data["githubUrl"] as? String, !github.isEmpty {
                    let attributedString = NSMutableAttributedString(string: "GitHub: \(github)")
                    attributedString.addAttribute(.underlineStyle,
                                                value: NSUnderlineStyle.single.rawValue,
                                                range: NSRange(location: 0, length: attributedString.length))
                    attributedString.addAttribute(.foregroundColor,
                                                value: UIColor.systemBlue,
                                                range: NSRange(location: 0, length: attributedString.length))
                    self.githubLabel.attributedText = attributedString
                    self.githubLabel.isUserInteractionEnabled = true
                    let tap = UITapGestureRecognizer(target: self, action: #selector(self.openGithubLink))
                    self.githubLabel.addGestureRecognizer(tap)
                } else {
                    self.githubLabel.text = "GitHub: Not available"
                    self.githubLabel.textColor = .label
                    self.githubLabel.isUserInteractionEnabled = false
                }

                if let linkedin = data["linkedinUrl"] as? String, !linkedin.isEmpty {
                    let attributedString = NSMutableAttributedString(string: "LinkedIn: \(linkedin)")
                    attributedString.addAttribute(.underlineStyle,
                                                value: NSUnderlineStyle.single.rawValue,
                                                range: NSRange(location: 0, length: attributedString.length))
                    attributedString.addAttribute(.foregroundColor,
                                                value: UIColor.systemBlue,
                                                range: NSRange(location: 0, length: attributedString.length))
                    self.linkedinLabel.attributedText = attributedString
                    self.linkedinLabel.isUserInteractionEnabled = true
                    let tap = UITapGestureRecognizer(target: self, action: #selector(self.openLinkedinLink))
                    self.linkedinLabel.addGestureRecognizer(tap)
                } else {
                    self.linkedinLabel.text = "LinkedIn: Not available"
                    self.linkedinLabel.textColor = .label
                    self.linkedinLabel.isUserInteractionEnabled = false
                }
                
//                if let techStack = data["techStack"] as? String, !techStack.isEmpty {
//                    self.techStackItems = techStack.components(separatedBy: ", ")
//                    self.techStackCollectionView.reloadData()
//
//                    // Update collection view height
//                    self.techStackCollectionView.layoutIfNeeded()
//                    let height = self.techStackCollectionView.collectionViewLayout.collectionViewContentSize.height
//                    self.techStackCollectionView.constraints.first(where: { $0.firstAttribute == .height })?.constant = height
//                }
                if let techStack = data["techStack"] as? String, !techStack.isEmpty {
                    let items = techStack.components(separatedBy: ", ")
                    // Remove duplicates while preserving order
                    var uniqueItems = [String]()
                    for item in items {
                        let trimmedItem = item.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !uniqueItems.contains(trimmedItem) && !trimmedItem.isEmpty {
                            uniqueItems.append(trimmedItem)
                        }
                    }
                    self.techStackItems = uniqueItems
                    self.techStackCollectionView.reloadData()
                    
                    // Calculate required height
                    DispatchQueue.main.async {
                        self.techStackCollectionView.layoutIfNeeded()
                        let height = self.techStackCollectionView.collectionViewLayout.collectionViewContentSize.height
                        self.techStackCollectionView.constraints.first(where: { $0.firstAttribute == .height })?.constant = height
                    }
                }
                
                if let profileImageURLString = data["profileImageURL"] as? String,
                   let profileImageURL = URL(string: profileImageURLString) {
                    self.loadProfileImage(from: profileImageURL)
                } else {
                    self.profileImageView.image = UIImage(named: "default_profile")
                }
            }
        }
    }
    
    @objc private func openGithubLink() {
        if let text = githubLabel.text?.replacingOccurrences(of: "GitHub: ", with: ""),
           let url = URL(string: text.hasPrefix("http") ? text : "https://\(text)") {
            UIApplication.shared.open(url)
        }
    }

    @objc private func openLinkedinLink() {
        if let text = linkedinLabel.text?.replacingOccurrences(of: "LinkedIn: ", with: ""),
           let url = URL(string: text.hasPrefix("http") ? text : "https://\(text)") {
            UIApplication.shared.open(url)
        }
    }

    
    private func loadProfileImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error downloading profile image: \(error.localizedDescription)")
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                print("Invalid image data")
                return
            }
            
            DispatchQueue.main.async {
                self.profileImageView.image = image
            }
        }.resume()
    }
    
//    private func fetchFriendsCount() {
//        guard let userId = Auth.auth().currentUser?.uid else { return }
//
//        db.collection("friends")
//            .whereField("userID", isEqualTo: userId)
//            .getDocuments { [weak self] (snapshot, error) in
//                guard let self = self else { return }
//
//                if let error = error {
//                    print("Error fetching friends count: \(error.localizedDescription)")
//                    return
//                }
//
//                let count = snapshot?.documents.count ?? 0
//                self.updateStatsView(friendsCount: count, eventsCount: self.registeredEvents.count)
//            }
//    }
    private func fetchFriendsCount() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("friends")
            .whereField("userID", isEqualTo: userId)
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching friends count: \(error.localizedDescription)")
                    return
                }
                
                let count = snapshot?.documents.count ?? 0
                // Update with both friends count and current events count
                self.updateStatsView(friendsCount: count, eventsCount: self.registeredEvents.count)
            }
    }
    
//    private func updateStatsView(friendsCount: Int, eventsCount: Int) {
//        // Clear existing views
//        statsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
//
//        // Friends Stat
//        let friendsStat = createStatView(count: friendsCount, title: "Friends", icon: UIImage(systemName: "person.2.fill"))
//        statsStack.addArrangedSubview(friendsStat)
//
//        // Events Stat
//        let eventsStat = createStatView(count: eventsCount, title: "Events", icon: UIImage(systemName: "calendar.badge.checkmark"))
//        statsStack.addArrangedSubview(eventsStat)
//    }
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
        statsStack.addArrangedSubview(eventsStat)
        
        // Remove the old gesture recognizer from statsContainer
        statsContainer.gestureRecognizers?.forEach { statsContainer.removeGestureRecognizer($0) }
    }
    
//    private func createStatView(count: Int, title: String, icon: UIImage?) -> UIView {
//        let container = UIView()
//
//        let stack = UIStackView()
//        stack.axis = .vertical
//        stack.alignment = .center
//        stack.spacing = 8
//
//        if let icon = icon {
//            let iconView = UIImageView(image: icon)
//            iconView.contentMode = .scaleAspectFit
//            iconView.tintColor = .systemOrange
//            iconView.heightAnchor.constraint(equalToConstant: 30).isActive = true
//            stack.addArrangedSubview(iconView)
//        }
//
//        let countLabel = UILabel()
//        countLabel.text = "\(count)"
//        countLabel.font = .systemFont(ofSize: 24, weight: .bold)
//        countLabel.textColor = .label
//        stack.addArrangedSubview(countLabel)
//
//        let titleLabel = UILabel()
//        titleLabel.text = title
//        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
//        titleLabel.textColor = .secondaryLabel
//        stack.addArrangedSubview(titleLabel)
//
//        container.addSubview(stack)
//        stack.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
//            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
//        ])
//
//        return container
//    }
    private func createStatView(count: Int, title: String, icon: UIImage?) -> UIView {
        let container = UIView()
        container.isUserInteractionEnabled = true // Enable interaction
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        
        if let icon = icon {
            let iconView = UIImageView(image: icon)
            iconView.contentMode = .scaleAspectFit
            iconView.tintColor = .systemOrange
            iconView.heightAnchor.constraint(equalToConstant: 30).isActive = true
            stack.addArrangedSubview(iconView)
        }
        
        let countLabel = UILabel()
        countLabel.text = "\(count)"
        countLabel.font = .systemFont(ofSize: 24, weight: .bold)
        countLabel.textColor = .label
        stack.addArrangedSubview(countLabel)
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        stack.addArrangedSubview(titleLabel)
        
        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }
    
    private func loadUserInterests() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not authenticated.")
            return
        }
        
        db.collection("Interest").document(userId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching user interests: \(error.localizedDescription)")
                return
            }
            
            guard let data = document?.data(), let interests = data["interests"] as? [String] else {
                print("No interests data found.")
                return
            }
            
            self.userInterests = interests
        }
    }
    
//    private func loadRegisteredEvents() {
//        guard let userId = Auth.auth().currentUser?.uid else {
//            print("User not authenticated.")
//            return
//        }
//
//        db.collection("registrations").whereField("uid", isEqualTo: userId).getDocuments { [weak self] querySnapshot, error in
//            guard let self = self else { return }
//
//            if let error = error {
//                print("Error fetching registrations: \(error.localizedDescription)")
//                return
//            }
//
//            let eventIds = querySnapshot?.documents.compactMap { $0.data()["eventId"] as? String } ?? []
//            if eventIds.isEmpty {
//                print("No registered events found.")
//                DispatchQueue.main.async {
//                    self.updateStatsView(friendsCount: 0, eventsCount: 0)
//                }
//            } else {
//                self.fetchEvents(for: eventIds)
//            }
//        }
//    }
    
    private func loadRegisteredEvents() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not authenticated.")
            return
        }
        
        db.collection("registrations").whereField("uid", isEqualTo: userId).getDocuments { [weak self] querySnapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching registrations: \(error.localizedDescription)")
                return
            }
            
            let eventIds = querySnapshot?.documents.compactMap { $0.data()["eventId"] as? String } ?? []
            if eventIds.isEmpty {
                print("No registered events found.")
                // Don't update stats here - let fetchFriendsCount handle it
            } else {
                self.fetchEvents(for: eventIds)
            }
        }
    }
    
//    private func fetchEvents(for eventIds: [String]) {
//        let group = DispatchGroup()
//        var fetchedEvents: [EventModel] = []
//
//        for eventId in eventIds {
//            group.enter()
//            db.collection("events").document(eventId).getDocument { document, error in
//                defer { group.leave() }
//
//                if let error = error {
//                    print("Error fetching event details for \(eventId): \(error.localizedDescription)")
//                    return
//                }
//
//                guard let data = document?.data() else {
//                    print("No data found for eventId: \(eventId)")
//                    return
//                }
//
//                let imageNameOrUrl = data["imageName"] as? String ?? ""
//                let isImageUrl = URL(string: imageNameOrUrl)?.scheme != nil
//
//                let event = EventModel(
//                    eventId: eventId,
//                    title: data["title"] as? String ?? "Untitled",
//                    category: data["category"] as? String ?? "Uncategorized",
//                    attendanceCount: data["attendanceCount"] as? Int ?? 0,
//                    organizerName: data["organizerName"] as? String ?? "Unknown",
//                    date: data["date"] as? String ?? "Unknown Date",
//                    time: data["time"] as? String ?? "Unknown Time",
//                    location: data["location"] as? String ?? "Unknown Location",
//                    locationDetails: data["locationDetails"] as? String ?? "",
//                    imageName: isImageUrl ? imageNameOrUrl : "",
//                    speakers: [],
//                    userId: data["userId"] as? String ?? "",
//                    description: data["description"] as? String ?? "",
//                    latitude: data["latitude"] as? Double,
//                    longitude: data["longitude"] as? Double,
//                    tags: []
//                )
//                fetchedEvents.append(event)
//            }
//        }
//
//        group.notify(queue: .main) {
//            self.registeredEvents = fetchedEvents
//            self.eventsTableView.reloadData()
//            self.updateStatsView(friendsCount: 0, eventsCount: fetchedEvents.count)
//        }
//    }
    private func fetchEvents(for eventIds: [String]) {
        let group = DispatchGroup()
        var fetchedEvents: [EventModel] = []
        
        for eventId in eventIds {
            group.enter()
            db.collection("events").document(eventId).getDocument { document, error in
                defer { group.leave() }
                
                if let error = error {
                    print("Error fetching event details for \(eventId): \(error.localizedDescription)")
                    return
                }
                
                guard let data = document?.data() else {
                    print("No data found for eventId: \(eventId)")
                    return
                }
                
                let imageNameOrUrl = data["imageName"] as? String ?? ""
                let isImageUrl = URL(string: imageNameOrUrl)?.scheme != nil
                
                let event = EventModel(
                    eventId: eventId,
                    title: data["title"] as? String ?? "Untitled",
                    category: data["category"] as? String ?? "Uncategorized",
                    attendanceCount: data["attendanceCount"] as? Int ?? 0,
                    organizerName: data["organizerName"] as? String ?? "Unknown",
                    date: data["date"] as? String ?? "Unknown Date",
                    time: data["time"] as? String ?? "Unknown Time",
                    location: data["location"] as? String ?? "Unknown Location",
                    locationDetails: data["locationDetails"] as? String ?? "",
                    imageName: isImageUrl ? imageNameOrUrl : "",
                    speakers: [],
                    userId: data["userId"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    latitude: data["latitude"] as? Double,
                    longitude: data["longitude"] as? Double,
                    tags: []
                )
                fetchedEvents.append(event)
            }
        }
        
        group.notify(queue: .main) {
            self.registeredEvents = fetchedEvents
            self.eventsTableView.reloadData()
            // Fetch friends count again to ensure both counts are accurate
            self.fetchFriendsCount()
        }
    }
    
//    private func updateProfile(with details: UserDetails) {
//        guard let userId = Auth.auth().currentUser?.uid else { return }
//
//        let data: [String: Any] = [
//            "name": details.name,
//            "Description": details.description,
//            "ContactDetails": details.contact ?? "",
//            "profileImageURL": details.imageUrl,
//            "githubUrl": details.githubUrl ?? "",
//            "linkedinUrl": details.linkedinUrl ?? "",
//            "techStack": details.techStack
//        ]
//
//        db.collection("users").document(userId).updateData(data) { error in
//            if let error = error {
//                print("Error updating profile: \(error.localizedDescription)")
//            } else {
//                self.loadUserDetails()
//            }
//        }
//    }
    private func updateProfile(with details: UserDetails) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let data: [String: Any] = [
            "name": details.name,
            "Description": details.description,
            "ContactDetails": details.contact ?? "",
            "profileImageURL": details.imageUrl,
            "githubUrl": details.githubUrl ?? "",
            "linkedinUrl": details.linkedinUrl ?? "",
            "techStack": details.techStack
        ]
        
        db.collection("users").document(userId).updateData(data) { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("Error updating profile: \(error.localizedDescription)")
                    self.showErrorAlert(message: "Failed to save changes. Please try again.")
                    return
                }
                
                // Show a quick success message (toast-style)
                self.showSuccessMessage("Your changes have been saved") {
                    // After message disappears, pop the view controller
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }

    // Helper to show a temporary success message (toast-like)
    private func showSuccessMessage(_ message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        
        // Auto-dismiss after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true) {
                completion?() // Execute completion handler (e.g., pop VC)
            }
        }
    }

    // Helper to show an error alert (stays until dismissed manually)
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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
        
        guard
            let editedImage = info[.editedImage] as? UIImage,
            let userId = Auth.auth().currentUser?.uid
        else { return }
        
        uploadProfileImage(editedImage, for: userId) { imageURL in
            self.db.collection("users").document(userId).updateData(["profileImageURL": imageURL]) { error in
                if let error = error {
                    print("Error updating image URL: \(error.localizedDescription)")
                } else {
                    self.profileImageView.image = editedImage
                }
            }
        }
    }
    
    private func uploadProfileImage(_ image: UIImage, for userId: String, completion: @escaping (String) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        let storageRef = Storage.storage().reference().child("profile_images/\(userId).jpg")
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                } else if let url = url {
                    completion(url.absoluteString)
                }
            }
        }
    }
    
    // MARK: - RegisteredEventCellDelegate
    func didTapUnregister(event: EventModel) {
        let alert = UIAlertController(
            title: "Unregister",
            message: "Are you sure you want to unregister from \(event.title)?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
            self.unregisterEvent(event)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }
    
    private func unregisterEvent(_ event: EventModel) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("registrations")
            .whereField("uid", isEqualTo: userId)
            .whereField("eventId", isEqualTo: event.eventId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching registration for unregistration: \(error.localizedDescription)")
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    print("No registration found for event \(event.eventId)")
                    return
                }
                
                document.reference.delete { error in
                    if let error = error {
                        print("Error deleting registration: \(error.localizedDescription)")
                    } else {
                        print("Successfully unregistered from event \(event.eventId)")
                        self.registeredEvents.removeAll { $0.eventId == event.eventId }
                        DispatchQueue.main.async {
                            self.eventsTableView.reloadData()
                            self.updateStatsView(friendsCount: 0, eventsCount: self.registeredEvents.count)
                        }
                    }
                }
            }
    }
    
    // MARK: - UITableView DataSource & Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return registeredEvents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RegisteredEventCell.identifier, for: indexPath) as! RegisteredEventCell
        cell.configure(with: registeredEvents[indexPath.row])
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let ticketVC = TicketViewController()
        ticketVC.eventId = registeredEvents[indexPath.row].eventId
        navigationController?.pushViewController(ticketVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension ProfileViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return techStackItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TechStackCell.identifier, for: indexPath) as! TechStackCell
        cell.configure(with: techStackItems[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let label = UILabel()
        label.text = techStackItems[indexPath.item]
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.sizeToFit()
        
        return CGSize(width: label.frame.width + 24, height: 32)
    }
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

