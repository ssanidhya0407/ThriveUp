import FirebaseFirestore
import UIKit
import FirebaseAuth
import SDWebImage

class EventListViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UISearchBarDelegate {

    // MARK: - Properties
    private var eventsByCategory: [String: [EventModel]] = [:]
    private var filteredEventsByCategory: [String: [EventModel]] = [:]
    private let predefinedCategories = [
        "Trending", "Fun and Entertainment", "Tech and Innovation",
        "Club and Societies", "Cultural", "Networking", "Sports","Hackathons", "Career Connect", "Wellness", "Other"
    ]
    private var categories: [String] = []
    private var filteredCategories: [String] = []
    private var collectionView: UICollectionView!
    private let searchBar = UISearchBar()
    private let feedLabel = UILabel()
    private let filterButton = UIButton(type: .system)
    // Define bookmarkButton as a class property
    private let bookmarkButton = UIButton(type: .system)
    private let notificationButton = UIButton(type: .system)
    private var bookmarkedViewController: BookmarkViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        setupGradientBackground() // Add gradient background first
                
        setupFeedLabel()
        setupSearchBar()
        setupFilterButton()
        setupCollectionView()
        fetchEventsFromFirestore()

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.bookmarkButton.addTarget(self, action: #selector(self.bookmarkButtonTapped), for: .touchUpInside)
            self.notificationButton.addTarget(self, action: #selector(self.notificationButtonTapped), for: .touchUpInside)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Clear previous targets to avoid duplicates
        bookmarkButton.removeTarget(nil, action: nil, for: .touchUpInside)
        notificationButton.removeTarget(nil, action: nil, for: .touchUpInside)
        
        // Reconnect the actions
        bookmarkButton.addTarget(self, action: #selector(bookmarkButtonTapped), for: .touchUpInside)
        notificationButton.addTarget(self, action: #selector(notificationButtonTapped), for: .touchUpInside)
        
        print("ViewWillAppear - Reconnecting button actions")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Print button references and properties
        print("Class bookmarkButton: \(bookmarkButton)")
        print("Class notificationButton: \(notificationButton)")
        
        // Iterate through view hierarchy to find the buttons
        func findButtons(in view: UIView, level: Int = 0) {
            let indent = String(repeating: "  ", count: level)
            for subview in view.subviews {
                if let button = subview as? UIButton {
                    print("\(indent)Found button: \(button), image: \(button.image(for: .normal)?.description ?? "none"), actions: \(button.actions(forTarget: self, forControlEvent: .touchUpInside) ?? [])")
                } else {
                    print("\(indent)\(type(of: subview)): \(subview.frame)")
                }
                findButtons(in: subview, level: level + 1)
            }
        }
        
        print("Searching view hierarchy:")
        findButtons(in: self.view)
    }
    
    // Add this method
    private func setupSimpleButtons() {
        // Create a simple toolbar at the bottom
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbar)
        
        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        // Create bar button items
        let bookmarkItem = UIBarButtonItem(image: UIImage(systemName: "bookmark"),
                                           style: .plain,
                                           target: self,
                                           action: #selector(testBookmarkTapped))
        
        let notificationItem = UIBarButtonItem(image: UIImage(systemName: "bell"),
                                              style: .plain,
                                              target: self,
                                              action: #selector(testNotificationTapped))
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        toolbar.items = [flexSpace, bookmarkItem, notificationItem, flexSpace]
    }

    @objc private func testBookmarkTapped() {
        print("TEST BOOKMARK TAPPED!")
        let bookmarkedVC = BookmarkViewController()
        navigationController?.pushViewController(bookmarkedVC, animated: true)
    }

    @objc private func testNotificationTapped() {
        print("TEST NOTIFICATION TAPPED!")
        let notificationVC = NotificationViewController()
        navigationController?.pushViewController(notificationVC, animated: true)
    }
    
    
    private func setupGradientBackground() {
        // Primary Gradient for Top Section
        let topGradientLayer = CAGradientLayer()
        let topGradientHeight = view.bounds.height * 1 // Covers 30% of the screen for top navigation
        topGradientLayer.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: topGradientHeight)

        topGradientLayer.colors = [
            UIColor(red: 1.0, green: 0.7, blue: 0.4, alpha: 1.0).cgColor, // Lighter Orange
            UIColor.white.cgColor // Smooth transition to white
        ]

        topGradientLayer.locations = [0.0, 0.4]
        topGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        topGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)

        let topGradientView = UIView(frame: topGradientLayer.frame)
        topGradientView.layer.addSublayer(topGradientLayer)
        view.addSubview(topGradientView)

        // Secondary Gradient for Collection View Area
        let bottomGradientLayer = CAGradientLayer()
        let bottomGradientHeight = view.bounds.height * 0.4 // Covers 40% of collection view
        bottomGradientLayer.frame = CGRect(x: 0, y: topGradientHeight, width: view.bounds.width, height: bottomGradientHeight)

        bottomGradientLayer.colors = [
            UIColor(red: 1.0, green: 0.85, blue: 0.7, alpha: 0.7).cgColor, // Lightest Orange
            UIColor.white.cgColor  // Smooth White Transition
        ]
        bottomGradientLayer.locations = [0.0, 1.0]
        bottomGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        bottomGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)

        let bottomGradientView = UIView(frame: bottomGradientLayer.frame)
        bottomGradientView.layer.addSublayer(bottomGradientLayer)
        view.addSubview(bottomGradientView)

        // Ensure both gradients are in the background
        view.sendSubviewToBack(bottomGradientView)
        view.sendSubviewToBack(topGradientView)
    }


    private func setupNavigationBar() {
        guard let user = Auth.auth().currentUser else {
            print("No user signed in")
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(user.uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                return
            }

            guard let data = snapshot?.data(),
                  let profileImageURL = data["profileImageURL"] as? String,
                  let userName = data["name"] as? String else {
                print("User data missing or improperly formatted")
                return
            }

            // Profile Image
            let profileImageView = UIImageView()
            profileImageView.contentMode = .scaleAspectFill
            profileImageView.clipsToBounds = true
            profileImageView.layer.cornerRadius = 25  // Circular Image
            profileImageView.translatesAutoresizingMaskIntoConstraints = false
            profileImageView.sd_setImage(with: URL(string: profileImageURL), placeholderImage: UIImage(named: "defaultProfile"))
            
            let nameLabel = UILabel()
            nameLabel.text = userName
            nameLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
            nameLabel.textColor = .black
            nameLabel.translatesAutoresizingMaskIntoConstraints = false

            // Container View for profile image and name label
            let profileContainerView = UIView()
            profileContainerView.addSubview(profileImageView)
            profileContainerView.addSubview(nameLabel)
            profileContainerView.translatesAutoresizingMaskIntoConstraints = false

            // Configure Bookmark & Notification Buttons
            self.bookmarkButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
            self.bookmarkButton.tintColor = .black
            self.bookmarkButton.translatesAutoresizingMaskIntoConstraints = false
            
            self.notificationButton.setImage(UIImage(systemName: "bell"), for: .normal)
            self.notificationButton.tintColor = .black
            self.notificationButton.translatesAutoresizingMaskIntoConstraints = false

            // Container View for the profile container and buttons
            let topBarView = UIView()
            topBarView.addSubview(profileContainerView)
            topBarView.addSubview(self.bookmarkButton)
            topBarView.addSubview(self.notificationButton)
            topBarView.translatesAutoresizingMaskIntoConstraints = false

            // Add custom topBarView as a subview to the main view
            self.view.addSubview(topBarView)
            
            // MARK: - Layout Constraints
            NSLayoutConstraint.activate([
                // Custom NavBar View Constraints (topBarView) relative to safeArea
                topBarView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor,constant: -16),
                topBarView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                topBarView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                topBarView.heightAnchor.constraint(equalToConstant: 70), // Adjust height if needed
            ])

            // Constraints for profile image and name label
            NSLayoutConstraint.activate([
                profileImageView.widthAnchor.constraint(equalToConstant: 50),
                profileImageView.heightAnchor.constraint(equalToConstant: 50),
                profileImageView.leadingAnchor.constraint(equalTo: profileContainerView.leadingAnchor,constant: 16),
                profileImageView.centerYAnchor.constraint(equalTo: profileContainerView.centerYAnchor),

                nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
                nameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
                nameLabel.trailingAnchor.constraint(equalTo: profileContainerView.trailingAnchor)
            ])

            // Constraints for the bookmark and notification buttons
            NSLayoutConstraint.activate([
                self.bookmarkButton.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
                self.notificationButton.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),

                self.notificationButton.trailingAnchor.constraint(equalTo: topBarView.trailingAnchor, constant: -20),
                self.bookmarkButton.trailingAnchor.constraint(equalTo: self.notificationButton.leadingAnchor, constant: -16)
            ])
        }
    }

    @objc private func bookmarkButtonTapped() {
        print("Bookmark button was tapped - CONFIRMED")
        
        if bookmarkedViewController == nil {
            bookmarkedViewController = BookmarkViewController()
        }
        
        if let currentVC = navigationController?.topViewController {
            if currentVC is BookmarkViewController {
                // If we're already on the BookmarkViewController, pop back
                navigationController?.popViewController(animated: true)
            } else {
                // Otherwise push to BookmarkViewController
                if let bookmarkedVC = bookmarkedViewController {
                    navigationController?.pushViewController(bookmarkedVC, animated: true)
                }
            }
        }
    }
    
    @objc private func notificationButtonTapped() {
        print("Notification button tapped") // Add print statement for debugging
        let notificationVC = NotificationViewController()
        navigationController?.pushViewController(notificationVC, animated: true)
    }

    // MARK: - Feed Label
    private func setupFeedLabel() {
        feedLabel.text = "Discover"
        feedLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        feedLabel.textAlignment = .left
        view.addSubview(feedLabel)
        feedLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            feedLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            feedLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            feedLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            feedLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    // MARK: - Search Bar
    private func setupSearchBar() {
        searchBar.placeholder = "Search"
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        view.addSubview(searchBar)

        searchBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: feedLabel.bottomAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -48),
            searchBar.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - Filter Button
    private func setupFilterButton() {
        filterButton.setImage(UIImage(systemName: "line.horizontal.3.decrease.circle"), for: .normal)
        filterButton.tintColor = .black
        filterButton.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
        view.addSubview(filterButton)

        filterButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            filterButton.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),
            filterButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            filterButton.widthAnchor.constraint(equalToConstant: 40),
            filterButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    @objc private func filterButtonTapped() {
        let filterVC = FilterViewController()
        filterVC.delegate = self
        present(filterVC, animated: true, completion: nil)
    }

    // MARK: - Collection View Setup
    private func setupCollectionView() {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, _ in
            let sectionName = self.filteredCategories[sectionIndex]

            if sectionName == "Trending" {
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(180))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 8)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.7), heightDimension: .absolute(180))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous

                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44))
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                section.boundarySupplementaryItems = [header]

                return section
            } else {
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(200))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 8)

                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(200))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous

                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44))
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                section.boundarySupplementaryItems = [header]

                return section
            }
        }

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(EventCell.self, forCellWithReuseIdentifier: EventCell.identifier)
        collectionView.register(CategoryHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CategoryHeader.identifier)

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear // ✅ Keep collection view transparent so gradient shows properly

        view.addSubview(collectionView)

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                    ])
                }
                // MARK: - Fetch Events
                private func fetchEventsFromFirestore() {
                    Firestore.firestore().collection("events").whereField("status", isEqualTo: "accepted").getDocuments { [weak self] snapshot, error in
                        if let error = error {
                            print("Error fetching events: \(error.localizedDescription)")
                            return
                        }

                        guard let documents = snapshot?.documents else { return }
                        var events: [EventModel] = []

                        for document in documents {
                            do {
                                let event = try document.data(as: EventModel.self)
                                events.append(event)
                            } catch {
                                print("Error decoding event: \(error.localizedDescription)")
                            }
                        }

                        self?.groupEventsByCategory(events)
                    }
                }

                private func groupEventsByCategory(_ events: [EventModel]) {
                    eventsByCategory = Dictionary(grouping: events, by: { $0.category })
                    filteredEventsByCategory = eventsByCategory
                    categories = predefinedCategories.filter { eventsByCategory.keys.contains($0) }
                    filteredCategories = categories
                    
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                }

                // MARK: - Collection View DataSource
                func numberOfSections(in collectionView: UICollectionView) -> Int {
                    return filteredCategories.count
                }

                func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
                    let category = filteredCategories[section]
                    return filteredEventsByCategory[category]?.count ?? 0
                }

                func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EventCell.identifier, for: indexPath) as! EventCell
                    let category = filteredCategories[indexPath.section]
                    if let event = filteredEventsByCategory[category]?[indexPath.item] {
                        cell.configure(with: event)
                    }
                    return cell
                }

                func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
                    let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CategoryHeader.identifier, for: indexPath) as! CategoryHeader
                    header.titleLabel.text = filteredCategories[indexPath.section]

                    header.titleLabel.font = UIFont.boldSystemFont(ofSize: 18)

                    if filteredCategories[indexPath.section] != "Trending" {
                        header.arrowButton.isHidden = false
                        header.arrowButton.tag = indexPath.section
                        header.arrowButton.addTarget(self, action: #selector(arrowButtonTapped(_:)), for: .touchUpInside)
                        header.arrowButton.tintColor = .systemOrange
                    } else {
                        header.arrowButton.isHidden = true
                    }

                    return header
                }

                @objc func arrowButtonTapped(_ sender: UIButton) {
                    let section = sender.tag
                    let category = filteredCategories[section]

                    let eventsListVC = EventsCardsViewController()
                    eventsListVC.category = CategoryModel(name: category, events: eventsByCategory[category] ?? [])
                    navigationController?.pushViewController(eventsListVC, animated: true)
                }

                // MARK: - Collection View Delegate
                func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
                    let category = filteredCategories[indexPath.section]
                    if let event = filteredEventsByCategory[category]?[indexPath.item] {
                        let eventDetailVC = EventDetailViewController()
                        eventDetailVC.eventId = event.eventId
                        eventDetailVC.openedFromEventVC = false // Set the flag
                        
                        navigationController?.pushViewController(eventDetailVC, animated: true)
                    }
                }

                // MARK: - Search Bar Delegate
                func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
                    if searchText.isEmpty {
                        filteredCategories = categories
                        filteredEventsByCategory = eventsByCategory
                    } else {
                        filteredEventsByCategory = eventsByCategory.mapValues { events in
                            events.filter { event in
                                event.title.lowercased().contains(searchText.lowercased())
                            }
                        }
                        filteredCategories = filteredEventsByCategory.keys.filter { !filteredEventsByCategory[$0]!.isEmpty }
                    }
                    collectionView.reloadData()
                }

                func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
                    searchBar.resignFirstResponder()
                }
            }

protocol FilterViewControllerDelegate: AnyObject {
    func didApplyFilters(_ filters: [String])
}

class FilterViewController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: FilterViewControllerDelegate?
    private var selectedFilters: Set<String> = []
    
    private let availableFilters = [
        "Trending", "Fun & Entertainment", "Tech & Innovation",
        "Club & Societies", "Cultural", "Networking", "Sports", "Hackathons",
        "Career Connect", "Wellness", "Other"
    ]
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 15
        layout.sectionInset = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()
    
    private let applyButton = UIButton()
    private let resetButton = UIButton()
    private let titleLabel = UILabel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .white
        
        // Title Label
        titleLabel.text = "Select Filters"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 26)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .black
        
        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Collection View
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.register(FilterCell.self, forCellWithReuseIdentifier: "FilterCell")
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply Button
        applyButton.setTitle("Apply Filters", for: .normal)
        applyButton.backgroundColor = .systemOrange
        applyButton.setTitleColor(.white, for: .normal)
        applyButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        applyButton.layer.cornerRadius = 12
        applyButton.layer.shadowColor = UIColor.black.cgColor
        applyButton.layer.shadowOpacity = 0.1
        applyButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        applyButton.addTarget(self, action: #selector(applyFilters), for: .touchUpInside)
        
        view.addSubview(applyButton)
        applyButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Reset Button
        resetButton.setTitle("Reset Filters", for: .normal)
        resetButton.backgroundColor = .white
        resetButton.setTitleColor(.systemOrange, for: .normal)
        resetButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        resetButton.layer.borderWidth = 1
        resetButton.layer.borderColor = UIColor.systemOrange.cgColor
        resetButton.layer.cornerRadius = 12
        resetButton.layer.shadowColor = UIColor.black.cgColor
        resetButton.layer.shadowOpacity = 0.05
        resetButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        resetButton.addTarget(self, action: #selector(resetFilters), for: .touchUpInside)
        
        view.addSubview(resetButton)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: applyButton.topAnchor, constant: -20),
            
            resetButton.bottomAnchor.constraint(equalTo: applyButton.topAnchor, constant: -12),
            resetButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            resetButton.heightAnchor.constraint(equalToConstant: 50),
            
            applyButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            applyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            applyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            applyButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    // MARK: - Actions
    @objc private func applyFilters() {
        delegate?.didApplyFilters(Array(selectedFilters))
        dismiss(animated: true)
    }
    
    @objc private func resetFilters() {
        selectedFilters.removeAll()
        collectionView.reloadData()
    }
}

// MARK: - Collection View Delegate & Data Source
extension FilterViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return availableFilters.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterCell", for: indexPath) as! FilterCell
        let filter = availableFilters[indexPath.row]
        
        cell.configure(with: filter, isSelected: selectedFilters.contains(filter))
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let filter = availableFilters[indexPath.row]
        if selectedFilters.contains(filter) {
            selectedFilters.remove(filter)
        } else {
            selectedFilters.insert(filter)
        }
        collectionView.reloadItems(at: [indexPath])
    }
}

// MARK: - Custom Collection View Cell
class FilterCell: UICollectionViewCell {
    private let label = UILabel()
    private let containerView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(containerView)
        containerView.addSubview(label)
        
        containerView.layer.cornerRadius = 15
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.systemOrange.cgColor
        containerView.backgroundColor = .white
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with text: String, isSelected: Bool) {
        label.text = text
        containerView.backgroundColor = isSelected ? .systemOrange : .white
        label.textColor = isSelected ? .white : .black
    }
}

// MARK: - Collection View Flow Layout
extension FilterViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let columns: CGFloat = 2
        let spacing: CGFloat = 16
        let totalSpacing = (columns - 1) * spacing
        let itemWidth = (collectionView.frame.width - totalSpacing - 32) / columns
        return CGSize(width: itemWidth, height: 60) // Adjusted height for better spacing
    }
}

            // MARK: - FilterViewControllerDelegate
            extension EventListViewController: FilterViewControllerDelegate {
                func didApplyFilters(_ filters: [String]) {
                    if filters.isEmpty {
                        // If no filters are selected, show all events
                        filteredCategories = categories
                        filteredEventsByCategory = eventsByCategory
                    } else {
                        // Filter categories and events based on selected filters
                        filteredCategories = filters
                        
                        // Filter events to only include those in the selected categories
                        filteredEventsByCategory = eventsByCategory.filter { filters.contains($0.key) }
                    }
                    
                    // Reload the collection view to reflect the changes
                    collectionView.reloadData()
                }
            }
            #Preview{
                EventListViewController()
            }
