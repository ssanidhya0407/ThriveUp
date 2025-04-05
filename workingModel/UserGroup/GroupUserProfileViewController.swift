import UIKit
import FirebaseFirestore
import Kingfisher

// Renamed class to avoid conflicts
class GroupUserProfileViewer: UIViewController {
    
    // MARK: - Properties
    private let userId: String
    private let db = Firestore.firestore()
    private var userData: [String: Any]?
    
    // UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let usernameLabel = UILabel()
    private let bioLabel = UILabel()
    private let statsStackView = UIStackView()
    
    // MARK: - Initialization
    init(userId: String) {
        self.userId = userId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUserData()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "Profile"
        view.backgroundColor = .systemBackground
        
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Setup content view
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Setup profile image
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 60
        profileImageView.backgroundColor = .systemGray6
        profileImageView.image = UIImage(systemName: "person.circle")
        profileImageView.tintColor = .systemGray3
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileImageView)
        
        // Setup name label
        nameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 0
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        
        // Setup username label
        usernameLabel.font = UIFont.systemFont(ofSize: 16)
        usernameLabel.textColor = .secondaryLabel
        usernameLabel.textAlignment = .center
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(usernameLabel)
        
        // Setup bio label
        bioLabel.font = UIFont.systemFont(ofSize: 16)
        bioLabel.textAlignment = .center
        bioLabel.numberOfLines = 0
        bioLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bioLabel)
        
        // Setup stats stack view
        statsStackView.axis = .horizontal
        statsStackView.distribution = .fillEqually
        statsStackView.spacing = 20
        statsStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statsStackView)
        
        // Create stats views
        addStatView(title: "Events", value: "0")
        addStatView(title: "Groups", value: "0")
        addStatView(title: "Friends", value: "0")
        
        // Set constraints
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Profile image
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),
            
            // Name label
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Username label
            usernameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            usernameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            usernameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Bio label
            bioLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 20),
            bioLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            bioLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Stats stack view
            statsStackView.topAnchor.constraint(equalTo: bioLabel.bottomAnchor, constant: 30),
            statsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            statsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }
    
    private func addStatView(title: String, value: String) {
        let statView = UIView()
        
        let valueLabel = UILabel()
        valueLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        valueLabel.text = value
        valueLabel.textAlignment = .center
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = .secondaryLabel
        titleLabel.text = title
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        statView.addSubview(valueLabel)
        statView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            valueLabel.topAnchor.constraint(equalTo: statView.topAnchor),
            valueLabel.centerXAnchor.constraint(equalTo: statView.centerXAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 4),
            titleLabel.centerXAnchor.constraint(equalTo: statView.centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: statView.bottomAnchor)
        ])
        
        statsStackView.addArrangedSubview(statView)
    }
    
    // MARK: - Data Loading
    private func loadUserData() {
        db.collection("users").document(userId).getDocument { [weak self] (snapshot, error) in
            guard let self = self, let data = snapshot?.data() else {
                print("Error fetching user data: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            self.userData = data
            
            // Update UI
            DispatchQueue.main.async {
                self.updateUI(with: data)
            }
        }
    }
    
    private func updateUI(with userData: [String: Any]) {
        // Set name
        if let name = userData["name"] as? String {
            nameLabel.text = name
            title = name
        }
        
        // Set username
        if let username = userData["username"] as? String {
            usernameLabel.text = "@\(username)"
        }
        
        // Set bio
        if let bio = userData["bio"] as? String {
            bioLabel.text = bio
        } else {
            bioLabel.text = "No bio available"
        }
        
        // Load profile image
        if let profileImageURL = userData["profileImageURL"] as? String, let url = URL(string: profileImageURL) {
            profileImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "person.circle"),
                options: [.transition(.fade(0.3))]
            )
        }
        
        // Load stats
        loadUserStats()
    }
    
    private func loadUserStats() {
        // This would fetch the actual stats from various collections
        // For now, we'll just use placeholder data
        
        // Example: Count user's events
        db.collection("events").whereField("creatorId", isEqualTo: userId).getDocuments { [weak self] (snapshot, error) in
            let eventCount = snapshot?.documents.count ?? 0
            DispatchQueue.main.async {
                if let statView = self?.statsStackView.arrangedSubviews[0] {
                    if let valueLabel = statView.subviews.first as? UILabel {
                        valueLabel.text = "\(eventCount)"
                    }
                }
            }
        }
        
        // This would be similar for groups and friends
    }
}
