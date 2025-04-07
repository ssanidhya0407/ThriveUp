import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Kingfisher

class CreateGroupViewController: UIViewController {
    // MARK: - Properties
    var currentUser: User?
    var friends: [User] = []
    var filteredFriends: [User] = []
    var selectedFriends: [User] = []
    private var db = Firestore.firestore()
    private var storage = Storage.storage()
    private var selectedImage: UIImage?
    private var searchActive = false
    private var isKeyboardVisible = false
    private var keyboardHeight: CGFloat = 0
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let imageContainerView = UIView()
    private let groupImageView = UIImageView()
    private let cameraButton = UIButton()
    private let cameraEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    private let groupInfoContainerView = UIView()
    
    // Improved text field containers
    private let nameContainerView = UIView()
    private let nameTitleLabel = UILabel()
    private let groupNameTextField = UITextField()
    
    private let descriptionContainerView = UIView()
    private let descriptionTitleLabel = UILabel()
    private let descriptionTextView = UITextView()
    
    private let membersLabel = UILabel()
    private let searchContainerView = UIView()
    private let searchBar = UISearchBar()
    private let selectedCountLabel = UILabel()
    private let selectedFriendsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private let separatorView = UIView()
    private let tableView = UITableView()
    private let createButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let headerEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let noFriendsView = NoFriendsView()
    private let noSearchResultsView = NoSearchResultsView()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSearchBar()
        setupNotifications()
        loadFriends()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make status bar background clear/blur
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let statusBarManager = windowScene.statusBarManager {
            let statusBarFrame = statusBarManager.statusBarFrame
            headerEffectView.frame = CGRect(x: 0, y: -statusBarFrame.height, width: view.bounds.width, height: 44 + statusBarFrame.height)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNotifications() {
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
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Setup scroll view for better layout on smaller devices
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delaysContentTouches = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        // Setup header with blur effect
        setupHeader()
        
        // Setup activity indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .systemOrange
        view.addSubview(activityIndicator)
        
        // Setup group image view
        setupImageView()
        
        // Setup group info section with enhanced text fields
        setupGroupInfoSection()
        
        // Setup members section
        setupMembersSection()
        
        // Setup buttons
        setupButtons()
        
        // Setup empty states
        setupEmptyStateViews()
        
        // Set constraints
        setupConstraints()
    }
    
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = .clear
        view.addSubview(headerView)
        
        // Add blur effect to header
        headerEffectView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(headerEffectView)
        
        // Title label
        titleLabel.text = "Create Group"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        
        // Cancel button
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        backButton.tintColor = .label
        backButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(backButton)
        
        // Add bottom separator line
        let separatorLine = UIView()
        separatorLine.backgroundColor = UIColor.systemGray5
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(separatorLine)
        
        NSLayoutConstraint.activate([
            headerEffectView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            headerEffectView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            headerEffectView.topAnchor.constraint(equalTo: headerView.topAnchor),
            headerEffectView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 24),
            backButton.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            separatorLine.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }
    
    private func setupImageView() {
        // Container view for image and camera button
        imageContainerView.translatesAutoresizingMaskIntoConstraints = false
        imageContainerView.backgroundColor = .clear
        contentView.addSubview(imageContainerView)
        
        // Group image view
        groupImageView.translatesAutoresizingMaskIntoConstraints = false
        groupImageView.contentMode = .scaleAspectFill
        groupImageView.backgroundColor = UIColor.systemGray6
        groupImageView.layer.cornerRadius = 60
        groupImageView.clipsToBounds = true
        groupImageView.image = UIImage(systemName: "person.3.fill")
        groupImageView.tintColor = .systemGray3
        
        // Add shadow to image container
        imageContainerView.layer.shadowColor = UIColor.black.cgColor
        imageContainerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        imageContainerView.layer.shadowRadius = 6
        imageContainerView.layer.shadowOpacity = 0.15
        
        // Add tap gesture to image view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectImage))
        groupImageView.isUserInteractionEnabled = true
        groupImageView.addGestureRecognizer(tapGesture)
        imageContainerView.addSubview(groupImageView)
        
        // Camera button with blur effect
        cameraEffectView.layer.cornerRadius = 18
        cameraEffectView.clipsToBounds = true
        cameraEffectView.translatesAutoresizingMaskIntoConstraints = false
        
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        cameraButton.setImage(UIImage(systemName: "camera.fill"), for: .normal)
        cameraButton.tintColor = .systemOrange
        cameraButton.addTarget(self, action: #selector(selectImage), for: .touchUpInside)
        
        imageContainerView.addSubview(cameraEffectView)
        cameraEffectView.contentView.addSubview(cameraButton)
    }
    
    private func setupGroupInfoSection() {
        // Container view for group info
        groupInfoContainerView.translatesAutoresizingMaskIntoConstraints = false
        groupInfoContainerView.backgroundColor = .clear
        contentView.addSubview(groupInfoContainerView)
        
        // ===== Enhanced Name Field =====
        nameContainerView.translatesAutoresizingMaskIntoConstraints = false
        nameContainerView.backgroundColor = UIColor.systemGray6
        nameContainerView.layer.cornerRadius = 12
        groupInfoContainerView.addSubview(nameContainerView)
        
        // Name title
        nameTitleLabel.text = "Group Name"
        nameTitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        nameTitleLabel.textColor = .systemOrange
        nameTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        nameContainerView.addSubview(nameTitleLabel)
        
        // Group name text field - enhanced
        groupNameTextField.placeholder = "Enter a name for your group"
        groupNameTextField.borderStyle = .none
        groupNameTextField.font = UIFont.systemFont(ofSize: 17)
        groupNameTextField.backgroundColor = .clear
        groupNameTextField.clearButtonMode = .whileEditing
        groupNameTextField.returnKeyType = .next
        groupNameTextField.delegate = self
        groupNameTextField.attributedPlaceholder = NSAttributedString(
            string: "Enter a name for your group",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.placeholderText]
        )
        groupNameTextField.translatesAutoresizingMaskIntoConstraints = false
        nameContainerView.addSubview(groupNameTextField)
        
        // Group icon
        let nameIconView = UIImageView(image: UIImage(systemName: "person.3"))
        nameIconView.tintColor = .systemOrange
        nameIconView.contentMode = .scaleAspectFit
        nameIconView.translatesAutoresizingMaskIntoConstraints = false
        nameContainerView.addSubview(nameIconView)
        
        // ===== Enhanced Description Field =====
        descriptionContainerView.translatesAutoresizingMaskIntoConstraints = false
        descriptionContainerView.backgroundColor = UIColor.systemGray6
        descriptionContainerView.layer.cornerRadius = 12
        groupInfoContainerView.addSubview(descriptionContainerView)
        
        // Description title
        descriptionTitleLabel.text = "Description"
        descriptionTitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        descriptionTitleLabel.textColor = .systemOrange
        descriptionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionContainerView.addSubview(descriptionTitleLabel)
        
        // Description text view - replacing text field with text view for multi-line
        descriptionTextView.font = UIFont.systemFont(ofSize: 17)
        descriptionTextView.backgroundColor = .clear
        descriptionTextView.returnKeyType = .done
        descriptionTextView.delegate = self
        descriptionTextView.text = "What's this group about? (Optional)"
        descriptionTextView.textColor = .placeholderText
        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        descriptionContainerView.addSubview(descriptionTextView)
        
        // Description icon
        let descriptionIconView = UIImageView(image: UIImage(systemName: "text.alignleft"))
        descriptionIconView.tintColor = .systemOrange
        descriptionIconView.contentMode = .scaleAspectFit
        descriptionIconView.translatesAutoresizingMaskIntoConstraints = false
        descriptionContainerView.addSubview(descriptionIconView)
        
        // Layout for name field
        NSLayoutConstraint.activate([
            nameContainerView.topAnchor.constraint(equalTo: groupInfoContainerView.topAnchor),
            nameContainerView.leadingAnchor.constraint(equalTo: groupInfoContainerView.leadingAnchor),
            nameContainerView.trailingAnchor.constraint(equalTo: groupInfoContainerView.trailingAnchor),
            nameContainerView.heightAnchor.constraint(equalToConstant: 70),
            
            nameIconView.leadingAnchor.constraint(equalTo: nameContainerView.leadingAnchor, constant: 16),
            nameIconView.topAnchor.constraint(equalTo: nameContainerView.topAnchor, constant: 22),
            nameIconView.widthAnchor.constraint(equalToConstant: 24),
            nameIconView.heightAnchor.constraint(equalToConstant: 24),
            
            nameTitleLabel.leadingAnchor.constraint(equalTo: nameIconView.trailingAnchor, constant: 16),
            nameTitleLabel.topAnchor.constraint(equalTo: nameContainerView.topAnchor, constant: 12),
            
            groupNameTextField.leadingAnchor.constraint(equalTo: nameTitleLabel.leadingAnchor),
            groupNameTextField.topAnchor.constraint(equalTo: nameTitleLabel.bottomAnchor, constant: 6),
            groupNameTextField.trailingAnchor.constraint(equalTo: nameContainerView.trailingAnchor, constant: -16),
            groupNameTextField.bottomAnchor.constraint(equalTo: nameContainerView.bottomAnchor, constant: -12),
        ])
        
        // Layout for description field
        NSLayoutConstraint.activate([
            descriptionContainerView.topAnchor.constraint(equalTo: nameContainerView.bottomAnchor, constant: 16),
            descriptionContainerView.leadingAnchor.constraint(equalTo: groupInfoContainerView.leadingAnchor),
            descriptionContainerView.trailingAnchor.constraint(equalTo: groupInfoContainerView.trailingAnchor),
            descriptionContainerView.heightAnchor.constraint(equalToConstant: 100),
            descriptionContainerView.bottomAnchor.constraint(equalTo: groupInfoContainerView.bottomAnchor),
            
            descriptionIconView.leadingAnchor.constraint(equalTo: descriptionContainerView.leadingAnchor, constant: 16),
            descriptionIconView.topAnchor.constraint(equalTo: descriptionContainerView.topAnchor, constant: 22),
            descriptionIconView.widthAnchor.constraint(equalToConstant: 24),
            descriptionIconView.heightAnchor.constraint(equalToConstant: 24),
            
            descriptionTitleLabel.leadingAnchor.constraint(equalTo: descriptionIconView.trailingAnchor, constant: 16),
            descriptionTitleLabel.topAnchor.constraint(equalTo: descriptionContainerView.topAnchor, constant: 12),
            
            descriptionTextView.leadingAnchor.constraint(equalTo: descriptionTitleLabel.leadingAnchor),
            descriptionTextView.topAnchor.constraint(equalTo: descriptionTitleLabel.bottomAnchor, constant: 2),
            descriptionTextView.trailingAnchor.constraint(equalTo: descriptionContainerView.trailingAnchor, constant: -16),
            descriptionTextView.bottomAnchor.constraint(equalTo: descriptionContainerView.bottomAnchor, constant: -12),
        ])
    }
    
    private func setupMembersSection() {
        // Members header
        membersLabel.text = "Add Members"
        membersLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        membersLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(membersLabel)
        
        // Selected count label
        selectedCountLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        selectedCountLabel.textColor = .secondaryLabel
        selectedCountLabel.text = "0 selected"
        selectedCountLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(selectedCountLabel)
        
        // Search container view
        searchContainerView.backgroundColor = UIColor.systemGray6
        searchContainerView.layer.cornerRadius = 12
        searchContainerView.clipsToBounds = true
        searchContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(searchContainerView)
        
        // Search bar
        searchBar.placeholder = "Search friends"
        searchBar.backgroundImage = UIImage() // Remove background
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchContainerView.addSubview(searchBar)
        
        // Selected Friends Collection View
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 80, height: 100)
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        selectedFriendsCollectionView.collectionViewLayout = layout
        selectedFriendsCollectionView.register(SelectedFriendCell.self, forCellWithReuseIdentifier: "SelectedFriendCell")
        selectedFriendsCollectionView.backgroundColor = .clear
        selectedFriendsCollectionView.showsHorizontalScrollIndicator = false
        selectedFriendsCollectionView.delegate = self
        selectedFriendsCollectionView.dataSource = self
        selectedFriendsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        selectedFriendsCollectionView.isHidden = true // Initially hidden until friends are selected
        contentView.addSubview(selectedFriendsCollectionView)
        
        // Separator
        separatorView.backgroundColor = UIColor.systemGray5
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorView)
        
        // Table view for friends
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(FriendSelectionCell.self, forCellReuseIdentifier: "FriendSelectionCell")
        tableView.rowHeight = 70
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(refreshFriends), for: .valueChanged)
        contentView.addSubview(tableView)
    }
    
    private func setupSearchBar() {
        // Customize search bar appearance
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = .clear
            textField.layer.cornerRadius = 12
            textField.layer.masksToBounds = true
            
            textField.attributedPlaceholder = NSAttributedString(
                string: "Search friends",
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.placeholderText]
            )
        }
    }
    
    private func setupButtons() {
        // Create button
        createButton.setTitle("Create Group", for: .normal)
        createButton.setTitleColor(.white, for: .normal)
        createButton.backgroundColor = .systemOrange
        createButton.layer.cornerRadius = 16
        createButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        createButton.addTarget(self, action: #selector(createGroup), for: .touchUpInside)
        createButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(createButton) // Add to main view so it stays fixed at bottom
        
        // Add shadow to create button
        createButton.layer.shadowColor = UIColor.black.cgColor
        createButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        createButton.layer.shadowRadius = 6
        createButton.layer.shadowOpacity = 0.15
    }
    
    private func setupEmptyStateViews() {
        // Add custom empty state views
        noFriendsView.translatesAutoresizingMaskIntoConstraints = false
        noFriendsView.isHidden = true
        view.addSubview(noFriendsView)
        
        noSearchResultsView.translatesAutoresizingMaskIntoConstraints = false
        noSearchResultsView.isHidden = true
        view.addSubview(noSearchResultsView)
        
        NSLayoutConstraint.activate([
            noFriendsView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            noFriendsView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            noFriendsView.widthAnchor.constraint(equalToConstant: 240),
            noFriendsView.heightAnchor.constraint(equalToConstant: 200),
            
            noSearchResultsView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            noSearchResultsView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            noSearchResultsView.widthAnchor.constraint(equalToConstant: 240),
            noSearchResultsView.heightAnchor.constraint(equalToConstant: 180),
        ])
    }
    
    private func setupConstraints() {
        let headerHeight: CGFloat = 58
        let selectedCollectionHeight: CGFloat = 112
        let buttonHeight: CGFloat = 54
        
        NSLayoutConstraint.activate([
            // Header view constraints
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: headerHeight + view.safeAreaInsets.top),
            
            // Scroll view constraints
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: createButton.topAnchor, constant: -20),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Activity indicator constraints
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Image container constraints
            imageContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            imageContainerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageContainerView.widthAnchor.constraint(equalToConstant: 120),
            imageContainerView.heightAnchor.constraint(equalToConstant: 120),
            
            // Group image view constraints
            groupImageView.centerXAnchor.constraint(equalTo: imageContainerView.centerXAnchor),
            groupImageView.centerYAnchor.constraint(equalTo: imageContainerView.centerYAnchor),
            groupImageView.widthAnchor.constraint(equalToConstant: 120),
            groupImageView.heightAnchor.constraint(equalToConstant: 120),
            
            // Camera button constraints
            cameraEffectView.trailingAnchor.constraint(equalTo: groupImageView.trailingAnchor, constant: 4),
            cameraEffectView.bottomAnchor.constraint(equalTo: groupImageView.bottomAnchor, constant: 4),
            cameraEffectView.widthAnchor.constraint(equalToConstant: 36),
            cameraEffectView.heightAnchor.constraint(equalToConstant: 36),
            
            cameraButton.centerXAnchor.constraint(equalTo: cameraEffectView.contentView.centerXAnchor),
            cameraButton.centerYAnchor.constraint(equalTo: cameraEffectView.contentView.centerYAnchor),
            cameraButton.widthAnchor.constraint(equalToConstant: 24),
            cameraButton.heightAnchor.constraint(equalToConstant: 24),
            
            // Group info container constraints
            groupInfoContainerView.topAnchor.constraint(equalTo: imageContainerView.bottomAnchor, constant: 24),
            groupInfoContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            groupInfoContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Members label constraints
            membersLabel.topAnchor.constraint(equalTo: groupInfoContainerView.bottomAnchor, constant: 32),
            membersLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            
            // Selected count label
            selectedCountLabel.centerYAnchor.constraint(equalTo: membersLabel.centerYAnchor),
            selectedCountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // Search container view
            searchContainerView.topAnchor.constraint(equalTo: membersLabel.bottomAnchor, constant: 16),
            searchContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            searchContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            searchContainerView.heightAnchor.constraint(equalToConstant: 50),
            
            // Search bar constraints
            searchBar.topAnchor.constraint(equalTo: searchContainerView.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: searchContainerView.leadingAnchor, constant: 4),
            searchBar.trailingAnchor.constraint(equalTo: searchContainerView.trailingAnchor, constant: -4),
            searchBar.bottomAnchor.constraint(equalTo: searchContainerView.bottomAnchor),
            
            // Selected friends collection view constraints
            selectedFriendsCollectionView.topAnchor.constraint(equalTo: searchContainerView.bottomAnchor, constant: 16),
            selectedFriendsCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            selectedFriendsCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            selectedFriendsCollectionView.heightAnchor.constraint(equalToConstant: selectedCollectionHeight),
            
            // Separator view
            separatorView.topAnchor.constraint(equalTo: selectedFriendsCollectionView.bottomAnchor, constant: 8),
            separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5),
            
            // Table view constraints - Dynamic height based on content
            tableView.topAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            tableView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300), // Minimum height
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            // Create button constraints (fixed to bottom of screen)
            createButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            createButton.heightAnchor.constraint(equalToConstant: buttonHeight)
        ])
    }
    
    // MARK: - Data Loading
    private func loadFriends() {
        tableView.refreshControl?.beginRefreshing()
        
        // This would be replaced with your actual friends fetching logic
        // Simulate network request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.tableView.refreshControl?.endRefreshing()
            
            // Update UI based on friends count
            if self.friends.isEmpty {
                self.noFriendsView.isHidden = false
                self.tableView.isHidden = true
                self.searchContainerView.isHidden = true
            } else {
                self.noFriendsView.isHidden = true
                self.tableView.isHidden = false
                self.searchContainerView.isHidden = false
                self.filteredFriends = self.friends
                self.tableView.reloadData()
                
                // Animate the table view appearance
                self.tableView.alpha = 0
                UIView.animate(withDuration: 0.3) {
                    self.tableView.alpha = 1
                }
            }
        }
    }
    
    @objc private func refreshFriends() {
        loadFriends()
    }
    
    private func filterFriends(with searchText: String) {
        if searchText.isEmpty {
            filteredFriends = friends
            searchActive = false
            noSearchResultsView.isHidden = true
        } else {
            filteredFriends = friends.filter { friend in
                return friend.name.lowercased().contains(searchText.lowercased())
            }
            searchActive = true
            noSearchResultsView.isHidden = !filteredFriends.isEmpty
        }
        
        tableView.reloadData()
        
        // Subtle animation for search results
        tableView.alpha = 0.7
        UIView.animate(withDuration: 0.2) {
            self.tableView.alpha = 1.0
        }
    }
    
    private func updateSelectedFriendsCollectionView() {
        selectedFriendsCollectionView.isHidden = selectedFriends.isEmpty
        selectedCountLabel.text = "\(selectedFriends.count) selected"
        
        // Animate collection view updates
        UIView.transition(with: selectedFriendsCollectionView, duration: 0.3, options: .transitionCrossDissolve) {
            self.selectedFriendsCollectionView.reloadData()
        }
        
        // Scroll to the end if a new item was added
        if !selectedFriends.isEmpty {
            selectedFriendsCollectionView.scrollToItem(
                at: IndexPath(item: selectedFriends.count - 1, section: 0),
                at: .right,
                animated: true
            )
        }
        
        // Toggle visibility with animation
        if selectedFriends.isEmpty && !selectedFriendsCollectionView.isHidden {
            UIView.animate(withDuration: 0.3) {
                self.selectedFriendsCollectionView.alpha = 0
            } completion: { _ in
                self.selectedFriendsCollectionView.isHidden = true
            }
        } else if !selectedFriends.isEmpty && selectedFriendsCollectionView.isHidden {
            selectedFriendsCollectionView.alpha = 0
            selectedFriendsCollectionView.isHidden = false
            UIView.animate(withDuration: 0.3) {
                self.selectedFriendsCollectionView.alpha = 1
            }
        }
        
        // Update the create button appearance based on selection
        updateCreateButtonAppearance()
    }
    
    private func updateCreateButtonAppearance() {
        let hasName = !(groupNameTextField.text?.isEmpty ?? true)
        let canCreate = hasName
        
        UIView.animate(withDuration: 0.2) {
            self.createButton.alpha = canCreate ? 1.0 : 0.6
        }
    }
    
    // MARK: - Actions
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        
        let keyboardHeight = keyboardFrame.height
        self.keyboardHeight = keyboardHeight
        isKeyboardVisible = true
        
        // Adjust scroll view insets
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
        
        // Adjust create button position
        UIView.animate(withDuration: 0.3) {
            self.createButton.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight)
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        isKeyboardVisible = false
        
        // Reset scroll view insets
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
        
        // Reset create button position
        UIView.animate(withDuration: 0.3) {
            self.createButton.transform = .identity
        }
    }
    
    @objc private func selectImage() {
        // Provide a haptic feedback
        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.impactOccurred()
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }
    
    @objc private func createGroup() {
        guard let groupName = groupNameTextField.text, !groupName.isEmpty else {
            // Visual shake animation for empty field
            shakeTextField(groupNameTextField)
            groupNameTextField.becomeFirstResponder()
            return
        }
        
        guard let currentUser = currentUser else {
            showAlert(title: "Authentication Error", message: "You need to be signed in to create a group")
            return
        }
        
        // Provide haptic feedback
        let feedback = UINotificationFeedbackGenerator()
        feedback.prepare()
        
        if selectedFriends.isEmpty {
            let alert = UIAlertController(
                title: "No Members Selected",
                message: "Are you sure you want to create a group with no additional members?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Create Anyway", style: .default) { [weak self] _ in
                feedback.notificationOccurred(.success)
                self?.startGroupCreation(groupName: groupName, currentUserID: currentUser.id)
            })
            present(alert, animated: true)
            return
        }
        
        feedback.notificationOccurred(.success)
        startGroupCreation(groupName: groupName, currentUserID: currentUser.id)
    }
    
    private func shakeTextField(_ textField: UITextField) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.6
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0]
        textField.layer.add(animation, forKey: "shake")
        
        // Highlight the text field
        UIView.animate(withDuration: 0.1, animations: {
            textField.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        }) { _ in
            UIView.animate(withDuration: 0.3) {
                textField.backgroundColor = .clear
            }
        }
        
        // Provide haptic feedback
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.error)
    }
    
    private func startGroupCreation(groupName: String, currentUserID: String) {
        activityIndicator.startAnimating()
        createButton.isEnabled = false
        
        // Disable interaction during creation
        view.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.3) {
            self.view.alpha = 0.7
        }
        
        let groupID = UUID().uuidString
        
        // Get description from text view
        let description: String?
        if descriptionTextView.textColor == .placeholderText {
            description = nil // Using placeholder text, so no description
        } else {
            description = descriptionTextView.text
        }
        
        // First upload image if selected
        if let image = selectedImage {
            uploadImage(image, groupID: groupID) { [weak self] imageURL in
                self?.createGroupDocument(
                    groupID: groupID,
                    groupName: groupName,
                    description: description,
                    currentUserID: currentUserID,
                    imageURL: imageURL
                )
            }
        } else {
            createGroupDocument(
                groupID: groupID,
                groupName: groupName,
                description: description,
                currentUserID: currentUserID,
                imageURL: nil
            )
        }
    }
    
    @objc private func cancelTapped() {
        // Provide haptic feedback
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()
        
        // Check if we have unsaved changes
        let hasName = !(groupNameTextField.text?.isEmpty ?? true)
        let hasDescription = descriptionTextView.textColor != .placeholderText && !descriptionTextView.text.isEmpty
        let hasImage = selectedImage != nil
        let hasSelectedFriends = !selectedFriends.isEmpty
        
        if hasName || hasDescription || hasImage || hasSelectedFriends {
            let alert = UIAlertController(
                title: "Discard Group?",
                message: "You have unsaved changes. Are you sure you want to discard this group?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Keep Editing", style: .cancel))
            alert.addAction(UIAlertAction(title: "Discard", style: .destructive) { [weak self] _ in
                self?.dismiss(animated: true)
            })
            present(alert, animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    // MARK: - Image Upload
    private func uploadImage(_ image: UIImage, groupID: String, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(nil)
            return
        }
        
        let storageRef = storage.reference().child("groupImages/\(groupID).jpg")
        
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Error uploading image: \(error)")
                completion(nil)
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error)")
                    completion(nil)
                } else {
                    completion(url?.absoluteString)
                }
            }
        }
    }
    
    // MARK: - Group Creation
    private func createGroupDocument(
        groupID: String,
        groupName: String,
        description: String?,
        currentUserID: String,
        imageURL: String?
    ) {
        // Create new group data
        var groupData: [String: Any] = [
            "id": groupID,
            "name": groupName,
            "createdBy": currentUserID,
            "createdAt": Timestamp(date: Date()),
            "settings": [
                "chatEnabled": true,
                "membersCanInvite": false
            ]
        ]
        
        // Add optional fields
        if let description = description, !description.isEmpty {
            groupData["description"] = description
        }
        
        if let imageURL = imageURL {
            groupData["imageURL"] = imageURL
        }
        
        // Add the creator as the first member
        self.fetchUserDetails(userId: currentUserID) { [weak self] userData in
            guard let self = self else { return }
            
            var memberData: [String: Any] = [
                "role": "admin",
                "joinedAt": Timestamp(date: Date()),
                "canChat": true
            ]
            
            // Fixed: Ensure creator's name and profile image are included
            if let name = userData?["name"] as? String {
                memberData["name"] = name
            }
            
            if let profileImage = userData?["profileImageURL"] as? String {
                memberData["profileImageURL"] = profileImage
            }
            
            // Create group with the first member
            let batch = self.db.batch()
            
            // Fixed: Use "userGroups" collection instead of "groups"
            let groupRef = self.db.collection("groups").document(groupID)
            batch.setData(groupData, forDocument: groupRef)
            batch.setData(memberData, forDocument: groupRef.collection("members").document(currentUserID))
            
            // Add selected friends as members
            for friend in self.selectedFriends {
                var friendData: [String: Any] = [
                    "role": "member",
                    "joinedAt": Timestamp(date: Date()),
                    "canChat": true
                ]
                
                if !friend.name.isEmpty {
                    friendData["name"] = friend.name
                }
                
                if let profileImageURL = friend.profileImageURL, !profileImageURL.isEmpty {
                    friendData["profileImageURL"] = profileImageURL
                }
                
                batch.setData(friendData, forDocument: groupRef.collection("members").document(friend.id))
            }
            
            // Also add the group to the user's groups collection
            batch.setData([
                "groupId": groupID,
                "name": groupName,
                "joinedAt": Timestamp(date: Date()),
                "role": "admin"
            ], forDocument: self.db.collection("users").document(currentUserID).collection("groups").document(groupID))
            
            batch.commit { error in
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.createButton.isEnabled = true
                    
                    // Re-enable interaction
                    self.view.isUserInteractionEnabled = true
                    UIView.animate(withDuration: 0.3) {
                        self.view.alpha = 1.0
                    }
                    
                    if let error = error {
                        print("Error creating group: \(error.localizedDescription)")
                        self.showAlert(title: "Error", message: "Failed to create group. Please try again.")
                        return
                    }
                    
                    // Show success message
                    self.showSuccessAndDismiss()
                }
            }
        }
    }
    
    private func fetchUserDetails(userId: String, completion: @escaping ([String: Any]?) -> Void) {
        db.collection("users").document(userId).getDocument { (snapshot, error) in
            if let error = error {
                print("Error fetching user details: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = snapshot?.data() else {
                completion(nil)
                return
            }
            
            completion(data)
        }
    }
    
    private func showSuccessAndDismiss() {
        // Success animation
        let successView = GroupCreatedSuccessView()
        successView.alpha = 0
        successView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        successView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(successView)
        
        NSLayoutConstraint.activate([
            successView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            successView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            successView.widthAnchor.constraint(equalToConstant: 280),
            successView.heightAnchor.constraint(equalToConstant: 280)
        ])
        
        // Animate success view
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: []) {
            successView.alpha = 1
            successView.transform = .identity
        } completion: { _ in
            // Dismiss after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.dismiss(animated: true)
            }
        }
        
        // Provide success haptic feedback
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.notificationOccurred(.success)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func removeFriend(_ friend: User) {
        if let index = selectedFriends.firstIndex(where: { $0.id == friend.id }) {
            selectedFriends.remove(at: index)
            updateSelectedFriendsCollectionView()
            tableView.reloadData()
            
            // Provide haptic feedback
            let feedback = UIImpactFeedbackGenerator(style: .light)
            feedback.impactOccurred()
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension CreateGroupViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredFriends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FriendSelectionCell", for: indexPath) as! FriendSelectionCell
        
        if indexPath.row < filteredFriends.count {
            let friend = filteredFriends[indexPath.row]
            cell.configure(with: friend)
            cell.setSelected(selectedFriends.contains(where: { $0.id == friend.id }))
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row < filteredFriends.count {
            let friend = filteredFriends[indexPath.row]
            
            // Provide haptic feedback
            let feedback = UIImpactFeedbackGenerator(style: .light)
            feedback.impactOccurred()
            
            if let index = selectedFriends.firstIndex(where: { $0.id == friend.id }) {
                selectedFriends.remove(at: index) // Deselect if already selected
            } else {
                selectedFriends.append(friend) // Select if not already in the list
            }
            
            if let cell = tableView.cellForRow(at: indexPath) as? FriendSelectionCell {
                cell.setSelected(selectedFriends.contains(where: { $0.id == friend.id }))
            }
            
            updateSelectedFriendsCollectionView()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if filteredFriends.isEmpty {
            return nil
        }
        
        let headerView = UIView()
        headerView.backgroundColor = .clear
        
        let titleLabel = UILabel()
        titleLabel.text = searchActive ? "Search Results" : "All Friends"
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        
        let countLabel = UILabel()
        countLabel.text = "\(filteredFriends.count)"
        countLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        countLabel.textColor = .secondaryLabel
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(countLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            countLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            countLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if filteredFriends.isEmpty {
            return 0
        }
        return 40
    }
    
    // Add animation for cell appearance
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: 0, y: 10)
        
        UIView.animate(withDuration: 0.3, delay: 0.05 * Double(indexPath.row), options: [.curveEaseInOut], animations: {
            cell.alpha = 1
            cell.transform = .identity
        })
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension CreateGroupViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedFriends.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SelectedFriendCell", for: indexPath) as! SelectedFriendCell
        
        if indexPath.item < selectedFriends.count {
            let friend = selectedFriends[indexPath.item]
            cell.configure(with: friend)
            cell.delegate = self
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        cell.alpha = 0
        cell.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.3, delay: 0.05 * Double(indexPath.row), options: [.curveEaseInOut], animations: {
            cell.alpha = 1
            cell.transform = .identity
        })
    }
}

// MARK: - UITextFieldDelegate
extension CreateGroupViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Highlight active text field
        if textField == groupNameTextField {
            UIView.animate(withDuration: 0.2) {
                self.nameContainerView.backgroundColor = UIColor.systemGray5
            }
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Reset text field appearance
        if textField == groupNameTextField {
            UIView.animate(withDuration: 0.2) {
                self.nameContainerView.backgroundColor = UIColor.systemGray6
            }
        }
        
        // Update create button state
        updateCreateButtonAppearance()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == groupNameTextField {
            descriptionTextView.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Schedule a check for button enabling after the text changes
        DispatchQueue.main.async {
            self.updateCreateButtonAppearance()
        }
        return true
    }
}

// MARK: - UITextViewDelegate
extension CreateGroupViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = ""
            textView.textColor = .label
        }
        
        UIView.animate(withDuration: 0.2) {
            self.descriptionContainerView.backgroundColor = UIColor.systemGray5
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "What's this group about? (Optional)"
            textView.textColor = .placeholderText
        }
        
        UIView.animate(withDuration: 0.2) {
            self.descriptionContainerView.backgroundColor = UIColor.systemGray6
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}

// MARK: - UISearchBarDelegate
extension CreateGroupViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterFriends(with: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        filterFriends(with: "")
        searchBar.resignFirstResponder()
    }
}

// MARK: - UIImagePickerControllerDelegate
extension CreateGroupViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                             didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            selectedImage = image
            
            // Fade transition for image change
            UIView.transition(with: groupImageView, duration: 0.3, options: .transitionCrossDissolve) {
                self.groupImageView.image = image
                self.groupImageView.contentMode = .scaleAspectFill
                self.groupImageView.tintColor = .clear
            }
        }
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - SelectedFriendCellDelegate
protocol SelectedFriendCellDelegate: AnyObject {
    func removeFriend(_ friend: User)
}

extension CreateGroupViewController: SelectedFriendCellDelegate {
    // Implementation already provided in main class
}

// MARK: - UIImageView Extension for Padding
extension UIImageView {
    func leftPadding(_ padding: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: padding, height: self.frame.height))
        self.frame.origin.x = padding
        self.frame = CGRect(x: padding, y: 0, width: self.frame.width, height: self.frame.height)
    }
}

// MARK: - SelectedFriendCell
class SelectedFriendCell: UICollectionViewCell {
    weak var delegate: SelectedFriendCellDelegate?
    private var friend: User?
    
    private let containerView = UIView()
    private let imageView = UIImageView()
    private let nameLabel = UILabel()
    private let removeButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        // Container view with shadow
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 4
        containerView.layer.shadowOpacity = 0.1
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // Image view
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 30
        imageView.backgroundColor = .systemGray6
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.tintColor = .systemGray3
        imageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(imageView)
        
        // Name label
        nameLabel.font = UIFont.systemFont(ofSize: 13)
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 1
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(nameLabel)
        
        // Remove button
        removeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        removeButton.tintColor = .systemRed
        removeButton.backgroundColor = .white
        removeButton.layer.cornerRadius = 10
        removeButton.layer.shadowColor = UIColor.black.cgColor
        removeButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        removeButton.layer.shadowRadius = 2
        removeButton.layer.shadowOpacity = 0.2
        removeButton.addTarget(self, action: #selector(removeButtonTapped), for: .touchUpInside)
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(removeButton)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60),
            
            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 2),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -2),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -2),
            
            removeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: -5),
            removeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 5),
            removeButton.widthAnchor.constraint(equalToConstant: 22),
            removeButton.heightAnchor.constraint(equalToConstant: 22)
        ])
    }
    
    func configure(with friend: User) {
        self.friend = friend
        nameLabel.text = friend.name
        
        if let imageURL = friend.profileImageURL, let url = URL(string: imageURL) {
            imageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "person.circle.fill"),
                options: [.transition(.fade(0.2))]
            )
        } else {
            imageView.image = UIImage(systemName: "person.circle.fill")
        }
    }
    
    @objc private func removeButtonTapped() {
        // Animate remove button tap
        UIView.animate(withDuration: 0.1, animations: {
            self.removeButton.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.removeButton.transform = .identity
            }
        }
        
        if let friend = friend {
            delegate?.removeFriend(friend)
        }
    }
}

// MARK: - FriendSelectionCell
class FriendSelectionCell: UITableViewCell {
    private let containerView = UIView()
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let selectionIndicator = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        selectionStyle = .none
        backgroundColor = .clear
        
        // Container view for rounded corners and shadow
        containerView.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.7)
        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // Add subtle shadow to container
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 4
        contentView.layer.shadowOpacity = 0.07
        contentView.layer.masksToBounds = false
        
        // Profile image
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 22
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .systemGray3
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(profileImageView)
        
        // Name label
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(nameLabel)
        
        // Selection indicator
        selectionIndicator.image = UIImage(systemName: "checkmark.circle.fill")
        selectionIndicator.tintColor = .systemOrange
        selectionIndicator.isHidden = true
        selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(selectionIndicator)
        
        // Constraints
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            profileImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 14),
            profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 44),
            profileImageView.heightAnchor.constraint(equalToConstant: 44),
            
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 14),
            nameLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: selectionIndicator.leadingAnchor, constant: -14),
            
            selectionIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            selectionIndicator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),
            selectionIndicator.widthAnchor.constraint(equalToConstant: 26),
            selectionIndicator.heightAnchor.constraint(equalToConstant: 26)
        ])
    }
    
    func configure(with friend: User) {
        nameLabel.text = friend.name
        
        if let imageURL = friend.profileImageURL, let url = URL(string: imageURL) {
            // Use Kingfisher to load image with smooth transition
            profileImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "person.circle.fill"),
                options: [.transition(.fade(0.2))]
            )
        } else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
        }
    }
    
    func setSelected(_ isSelected: Bool) {
        selectionIndicator.isHidden = !isSelected
        
        if isSelected {
            // Subtle animation for selection state change
            UIView.animate(withDuration: 0.2) {
                self.containerView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.12)
            }
        } else {
            UIView.animate(withDuration: 0.2) {
                self.containerView.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.7)
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        nameLabel.text = nil
        selectionIndicator.isHidden = true
        containerView.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.7)
    }
    
    // Add press animation
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        animateTouchDown()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        animateTouchUp()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        animateTouchUp()
    }
    
    private func animateTouchDown() {
        UIView.animate(withDuration: 0.1) {
            self.containerView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
            self.containerView.alpha = 0.9
        }
    }
    
    private func animateTouchUp() {
        UIView.animate(withDuration: 0.2) {
            self.containerView.transform = .identity
            self.containerView.alpha = 1.0
        }
    }
}

// MARK: - Custom Empty State Views
class NoFriendsView: UIView {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        // Image view setup
        imageView.image = UIImage(systemName: "person.3.sequence.fill")
        imageView.tintColor = .systemGray3
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        
        // Title label setup
        titleLabel.text = "No Friends Yet"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        // Message label setup
        messageLabel.text = "Add friends to create group chats with them"
        messageLabel.font = UIFont.systemFont(ofSize: 14)
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 100),
            imageView.heightAnchor.constraint(equalToConstant: 100),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            messageLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -20)
        ])
    }
}

class NoSearchResultsView: UIView {
    private let imageView = UIImageView()
    private let messageLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        // Image view setup
        imageView.image = UIImage(systemName: "magnifyingglass")
        imageView.tintColor = .systemGray3
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        
        // Message label setup
        messageLabel.text = "No search results found"
        messageLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60),
            
            messageLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            messageLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -20)
        ])
    }
}

// MARK: - Success Animation View
class GroupCreatedSuccessView: UIView {
    private let containerView = UIView()
    private let checkmarkImageView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        // Container view setup
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 20
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 12
        containerView.layer.shadowOpacity = 0.2
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        // Checkmark image view setup
        let checkmarkConfig = UIImage.SymbolConfiguration(pointSize: 80, weight: .semibold)
        checkmarkImageView.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: checkmarkConfig)
        checkmarkImageView.tintColor = .systemGreen
        checkmarkImageView.contentMode = .scaleAspectFit
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(checkmarkImageView)
        
        // Title label setup
        titleLabel.text = "Group Created!"
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Message label setup
        messageLabel.text = "Your new group chat has been created successfully"
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            checkmarkImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 40),
            checkmarkImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 90),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 90),
            
            titleLabel.topAnchor.constraint(equalTo: checkmarkImageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            messageLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -40)
        ])
        
        // Start animation
        DispatchQueue.main.async {
            self.animateCheckmark()
        }
    }
    
    private func animateCheckmark() {
        checkmarkImageView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        checkmarkImageView.alpha = 0
        
        UIView.animate(withDuration: 0.5, delay: 0.2, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: []) {
            self.checkmarkImageView.transform = .identity
            self.checkmarkImageView.alpha = 1
        }
    }
}
