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
        "Club and Societies", "Cultural", "Networking", "Sports","Hackathons",
        "Career Connect", "Wellness", "Other"
    ]
    private var categories: [String] = []
    private var filteredCategories: [String] = []
    private var collectionView: UICollectionView!
    private let searchBar = UISearchBar()
    private let feedLabel = UILabel()
    private let filterButton = UIButton(type: .system)
    
    // Navigation buttons
    private lazy var bookmarkButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "bookmark"), for: .normal)
        button.tintColor = .black
        button.addTarget(self, action: #selector(bookmarkButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var notificationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "bell"), for: .normal)
        button.tintColor = .black
        button.addTarget(self, action: #selector(notificationButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var bookmarkedViewController: BookmarkViewController?

    // Helper struct
    private struct EventWithDeadline {
        let event: EventModel
        let deadlineDate: Date?
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchEventsFromFirestore()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        setupNavigationBar()
        setupGradientBackground()
        setupFeedLabel()
        setupSearchBar()
        setupFilterButton()
        setupCollectionView()
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
            profileImageView.layer.cornerRadius = 25
            profileImageView.translatesAutoresizingMaskIntoConstraints = false
            profileImageView.sd_setImage(with: URL(string: profileImageURL), placeholderImage: UIImage(named: "defaultProfile"))
            
            // Name Label
            let nameLabel = UILabel()
            nameLabel.text = userName
            nameLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
            nameLabel.textColor = .black
            nameLabel.translatesAutoresizingMaskIntoConstraints = false

            // Container View
            let profileContainerView = UIView()
            profileContainerView.addSubview(profileImageView)
            profileContainerView.addSubview(nameLabel)
            profileContainerView.translatesAutoresizingMaskIntoConstraints = false

            // Top Bar View
            let topBarView = UIView()
            topBarView.addSubview(profileContainerView)
            topBarView.addSubview(self.bookmarkButton)
            topBarView.addSubview(self.notificationButton)
            topBarView.translatesAutoresizingMaskIntoConstraints = false

            self.view.addSubview(topBarView)
            
            // Constraints
            NSLayoutConstraint.activate([
                topBarView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
                topBarView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                topBarView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                topBarView.heightAnchor.constraint(equalToConstant: 60),
                
                profileContainerView.leadingAnchor.constraint(equalTo: topBarView.leadingAnchor, constant: 16),
                profileContainerView.centerYAnchor.constraint(equalTo: topBarView.centerYAnchor),
                
                profileImageView.widthAnchor.constraint(equalToConstant: 50),
                profileImageView.heightAnchor.constraint(equalToConstant: 50),
                profileImageView.leadingAnchor.constraint(equalTo: profileContainerView.leadingAnchor),
                profileImageView.centerYAnchor.constraint(equalTo: profileContainerView.centerYAnchor,constant: -26),

                nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
                nameLabel.trailingAnchor.constraint(equalTo: profileContainerView.trailingAnchor),
                nameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
                
                self.notificationButton.trailingAnchor.constraint(equalTo: topBarView.trailingAnchor, constant: -16),
                self.notificationButton.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
                self.notificationButton.widthAnchor.constraint(equalToConstant: 44),
                self.notificationButton.heightAnchor.constraint(equalToConstant: 44),
                
                self.bookmarkButton.trailingAnchor.constraint(equalTo: self.notificationButton.leadingAnchor, constant: -16),
                self.bookmarkButton.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
                self.bookmarkButton.widthAnchor.constraint(equalToConstant: 44),
                self.bookmarkButton.heightAnchor.constraint(equalToConstant: 44)
            ])
            
            // Ensure buttons are on top
            topBarView.bringSubviewToFront(self.bookmarkButton)
            topBarView.bringSubviewToFront(self.notificationButton)
        }
    }

    private func setupGradientBackground() {
        let topGradientLayer = CAGradientLayer()
        let topGradientHeight = view.bounds.height * 1
        topGradientLayer.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: topGradientHeight)
        topGradientLayer.colors = [
            UIColor(red: 1.0, green: 0.7, blue: 0.4, alpha: 1.0).cgColor,
            UIColor.white.cgColor
        ]
        topGradientLayer.locations = [0.0, 0.4]
        topGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        topGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)

        let bottomGradientLayer = CAGradientLayer()
        let bottomGradientHeight = view.bounds.height * 0.4
        bottomGradientLayer.frame = CGRect(x: 0, y: topGradientHeight, width: view.bounds.width, height: bottomGradientHeight)
        bottomGradientLayer.colors = [
            UIColor(red: 1.0, green: 0.85, blue: 0.7, alpha: 0.7).cgColor,
            UIColor.white.cgColor
        ]
        bottomGradientLayer.locations = [0.0, 1.0]
        bottomGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        bottomGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)

        let topGradientView = UIView(frame: topGradientLayer.frame)
        topGradientView.layer.addSublayer(topGradientLayer)
        view.addSubview(topGradientView)

        let bottomGradientView = UIView(frame: bottomGradientLayer.frame)
        bottomGradientView.layer.addSublayer(bottomGradientLayer)
        view.addSubview(bottomGradientView)

        view.sendSubviewToBack(bottomGradientView)
        view.sendSubviewToBack(topGradientView)
    }

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

    private func setupCollectionView() {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, _ in
            let sectionName = self.filteredCategories[sectionIndex]

            if sectionName == "Expiring Soon" {
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(200))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(220))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 12
                
                let backgroundDecoration = NSCollectionLayoutDecorationItem.background(
                    elementKind: "ExpiringBackground"
                )
                backgroundDecoration.contentInsets = NSDirectionalEdgeInsets(
                    top: 0, leading: 16, bottom: 20, trailing: 16
                )
                section.decorationItems = [backgroundDecoration]
                
                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(60))
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                section.boundarySupplementaryItems = [header]
                
                return section
                
            } else if sectionName == "Trending" {
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
        
        layout.register(ExpiringBackgroundView.self, forDecorationViewOfKind: "ExpiringBackground")
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(EventCell.self, forCellWithReuseIdentifier: EventCell.identifier)
        collectionView.register(CategoryHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CategoryHeader.identifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        
        view.addSubview(collectionView)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Data Methods
    private func fetchEventsFromFirestore() {
        Firestore.firestore().collection("events")
            .whereField("status", isEqualTo: "accepted")
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching events: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }
                var eventsWithDeadlines: [EventWithDeadline] = []
                let group = DispatchGroup()

                for document in documents {
                    group.enter()
                    
                    do {
                        let event = try document.data(as: EventModel.self)
                        let deadlineDate = document.get("deadlineDate") as? Timestamp
                        let eventWithDeadline = EventWithDeadline(
                            event: event,
                            deadlineDate: deadlineDate?.dateValue()
                        )
                        eventsWithDeadlines.append(eventWithDeadline)
                    } catch {
                        print("Error decoding event: \(error.localizedDescription)")
                    }
                    
                    group.leave()
                }

                group.notify(queue: .main) {
                    self?.processEvents(eventsWithDeadlines)
                }
            }
    }

    private func processEvents(_ events: [EventWithDeadline]) {
        // Group events by category
        var tempEventsByCategory: [String: [EventModel]] = [:]
        
        for eventWithDeadline in events {
            let event = eventWithDeadline.event
            if tempEventsByCategory[event.category] == nil {
                tempEventsByCategory[event.category] = []
            }
            tempEventsByCategory[event.category]?.append(event)
        }
        
        eventsByCategory = tempEventsByCategory
        filteredEventsByCategory = eventsByCategory
        
        // Get expiring events
        let now = Date()
        let oneDayFromNow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        
        let expiringEvents = events.filter { eventWithDeadline in
            guard let deadline = eventWithDeadline.deadlineDate else { return false }
            return deadline > now && deadline <= oneDayFromNow
        }.sorted {
            ($0.deadlineDate ?? Date()) < ($1.deadlineDate ?? Date())
        }.map { $0.event }
        
        // Add expiring events as a special category
        if !expiringEvents.isEmpty {
            eventsByCategory["Expiring Soon"] = expiringEvents
            filteredEventsByCategory["Expiring Soon"] = expiringEvents
        }
        
        categories = predefinedCategories.filter { eventsByCategory.keys.contains($0) }
        if eventsByCategory.keys.contains("Expiring Soon") {
            categories.insert("Expiring Soon", at: 0)
        }
        filteredCategories = categories
        
        collectionView.reloadData()
    }

    private func getDeadlineDate(for eventId: String, completion: @escaping (Date?) -> Void) {
        Firestore.firestore().collection("events").document(eventId).getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let timestamp = data["deadlineDate"] as? Timestamp {
                completion(timestamp.dateValue())
            } else {
                completion(nil)
            }
        }
    }
    private func timeRemainingString(from date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: now, to: date)
        
        if let hours = components.hour, let minutes = components.minute, let seconds = components.second {
            if hours > 0 {
                return "Ends in \(hours)h \(minutes)m"
            } else if minutes > 0 {
                return "Ends in \(minutes)m \(seconds)s"
            } else {
                return "Ends in \(seconds)s"
            }
        }
        return "Ending soon"
    }

    // MARK: - UICollectionViewDataSource
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
            
            // Remove any existing countdown labels first
            cell.contentView.subviews.forEach {
                if $0 is UILabel && $0.tag == 999 { // Use tag to identify our countdown label
                    $0.removeFromSuperview()
                }
            }
            
            // Only apply special styling for expiring events
            if category == "Expiring Soon" {
                cell.backgroundColor = UIColor(red: 1.0, green: 0.95, blue: 0.9, alpha: 1.0)
                cell.layer.cornerRadius = 8
                cell.layer.borderWidth = 1
                cell.layer.borderColor = UIColor.systemOrange.withAlphaComponent(0.2).cgColor
                
                // Get deadline date and setup countdown
                getDeadlineDate(for: event.eventId) { [weak cell] deadline in
                    guard let deadline = deadline, let cell = cell else { return }
                    
                    DispatchQueue.main.async {
                        let countdownLabel = UILabel()
                        countdownLabel.tag = 999 // Mark our countdown label
                        countdownLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
                        countdownLabel.textColor = .systemRed
                        countdownLabel.text = self.timeRemainingString(from: deadline)
                        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
                        cell.contentView.addSubview(countdownLabel)
                        
                        NSLayoutConstraint.activate([
                            countdownLabel.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -8),
                            countdownLabel.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8)
                        ])
                        
                        // Update the countdown every second
                        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                            countdownLabel.text = self.timeRemainingString(from: deadline)
                            if deadline < Date() {
                                timer.invalidate()
                            }
                        }
                    }
                }
            } else {
                // Reset to default styling for non-expiring events
                cell.backgroundColor = .clear
                cell.layer.borderWidth = 0
            }
        }
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CategoryHeader.identifier, for: indexPath) as! CategoryHeader
        header.titleLabel.text = filteredCategories[indexPath.section]
        
        if filteredCategories[indexPath.section] == "Expiring Soon" {
            header.titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
            header.titleLabel.textColor = .systemRed
            header.arrowButton.isHidden = true
            
            // Add a fire icon
//            let fireIcon = UIImageView(image: UIImage(systemName: "flame.fill"))
//            fireIcon.tintColor = .systemOrange
//            fireIcon.translatesAutoresizingMaskIntoConstraints = false
//            header.addSubview(fireIcon)
//
//            NSLayoutConstraint.activate([
//                fireIcon.leadingAnchor.constraint(equalTo: header.titleLabel.trailingAnchor, constant: 8),
//                fireIcon.centerYAnchor.constraint(equalTo: header.titleLabel.centerYAnchor),
//                fireIcon.widthAnchor.constraint(equalToConstant: 20),
//                fireIcon.heightAnchor.constraint(equalToConstant: 24)
//            ])
        } else {
            header.titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
            header.titleLabel.textColor = .black
            
            if filteredCategories[indexPath.section] != "Trending" {
                header.arrowButton.isHidden = false
                header.arrowButton.tag = indexPath.section
                header.arrowButton.addTarget(self, action: #selector(arrowButtonTapped(_:)), for: .touchUpInside)
                header.arrowButton.tintColor = .systemOrange
            } else {
                header.arrowButton.isHidden = true
            }
        }
        
        return header
    }

    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let category = filteredCategories[indexPath.section]
        if let event = filteredEventsByCategory[category]?[indexPath.item] {
            let eventDetailVC = EventDetailViewController()
            eventDetailVC.eventId = event.eventId
            eventDetailVC.openedFromEventVC = false
            navigationController?.pushViewController(eventDetailVC, animated: true)
        }
    }

    // MARK: - UISearchBarDelegate
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

    // MARK: - Actions
    @objc private func filterButtonTapped() {
        let filterVC = FilterViewController()
        filterVC.delegate = self
        present(filterVC, animated: true, completion: nil)
    }

    @objc private func bookmarkButtonTapped() {
           print("Bookmark button tapped")
           
           if bookmarkedViewController == nil {
               bookmarkedViewController = BookmarkViewController()
           }
           
           if let navController = navigationController {
               if navController.topViewController is BookmarkViewController {
                   navController.popViewController(animated: true)
               } else if let bookmarkedVC = bookmarkedViewController {
                   navController.pushViewController(bookmarkedVC, animated: true)
               }
           }
       }
    
    @objc private func notificationButtonTapped() {
            print("Notification button tapped")
            let notificationVC = NotificationViewController()
            navigationController?.pushViewController(notificationVC, animated: true)
        }

    @objc private func arrowButtonTapped(_ sender: UIButton) {
        let section = sender.tag
        let category = filteredCategories[section]

        let eventsListVC = EventsCardsViewController()
        eventsListVC.category = CategoryModel(name: category, events: eventsByCategory[category] ?? [])
        navigationController?.pushViewController(eventsListVC, animated: true)
    }
}

// MARK: - FilterViewControllerDelegate
extension EventListViewController: FilterViewControllerDelegate {
    func didApplyFilters(_ filters: [String]) {
        if filters.isEmpty {
            filteredCategories = categories
            filteredEventsByCategory = eventsByCategory
        } else {
            filteredCategories = filters
            filteredEventsByCategory = eventsByCategory.filter { filters.contains($0.key) }
        }
        collectionView.reloadData()
    }
}

// MARK: - ExpiringBackgroundView
class ExpiringBackgroundView: UICollectionReusableView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = UIColor(red: 1.0, green: 0.9, blue: 0.8, alpha: 1.0)
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemOrange.withAlphaComponent(0.3).cgColor
        layer.shadowColor = UIColor.systemOrange.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
    }
}

import UIKit

protocol FilterViewControllerDelegate: AnyObject {
    func didApplyFilters(_ filters: [String])
}

class FilterViewController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: FilterViewControllerDelegate?
    private var selectedFilters: Set<String> = []
    
    private let availableFilters = [
        "Trending", "Fun & Entertainment", "Tech & Innovation",
        "Club & Societies", "Cultural", "Networking", "Sports",
        "Career Connect", "Wellness", "Other"
    ]
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
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
        view.backgroundColor = .systemBackground
        
        // Title Label
        titleLabel.text = "Select Filters"
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        
        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Collection View
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.register(FilterCell.self, forCellWithReuseIdentifier: FilterCell.identifier)
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply Button
        applyButton.setTitle("Apply Filters", for: .normal)
        applyButton.backgroundColor = .systemOrange
        applyButton.setTitleColor(.white, for: .normal)
        applyButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        applyButton.layer.cornerRadius = 10
        applyButton.addTarget(self, action: #selector(applyFilters), for: .touchUpInside)
        
        view.addSubview(applyButton)
        applyButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Reset Button
        resetButton.setTitle("Reset Filters", for: .normal)
        resetButton.backgroundColor = .systemBackground
        resetButton.setTitleColor(.systemOrange, for: .normal)
        resetButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        resetButton.layer.borderWidth = 1.5
        resetButton.layer.borderColor = UIColor.systemOrange.cgColor
        resetButton.layer.cornerRadius = 10
        resetButton.addTarget(self, action: #selector(resetFilters), for: .touchUpInside)
        
        view.addSubview(resetButton)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: resetButton.topAnchor, constant: -20),
            
            resetButton.bottomAnchor.constraint(equalTo: applyButton.topAnchor, constant: -12),
            resetButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            resetButton.heightAnchor.constraint(equalToConstant: 48),
            
            applyButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            applyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            applyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            applyButton.heightAnchor.constraint(equalToConstant: 48)
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

// MARK: - Collection View Data Source
extension FilterViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return availableFilters.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterCell.identifier, for: indexPath) as? FilterCell else {
            return UICollectionViewCell()
        }
        
        let filter = availableFilters[indexPath.item]
        cell.configure(with: filter, isSelected: selectedFilters.contains(filter))
        return cell
    }
}

// MARK: - Collection View Delegate
extension FilterViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let filter = availableFilters[indexPath.item]
        
        if selectedFilters.contains(filter) {
            selectedFilters.remove(filter)
        } else {
            selectedFilters.insert(filter)
        }
        
        collectionView.reloadItems(at: [indexPath])
    }
}

// MARK: - Collection View Flow Layout
extension FilterViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let columns: CGFloat = 2
        let spacing: CGFloat = 12
        let totalSpacing = (columns - 1) * spacing + 32
        let itemWidth = (collectionView.frame.width - totalSpacing) / columns
        return CGSize(width: itemWidth, height: 48)
    }
}

// MARK: - Filter Cell
class FilterCell: UICollectionViewCell {
    static let identifier = "FilterCell"
    
    private let label = UILabel()
    private let containerView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(containerView)
        containerView.addSubview(label)
        
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1.5
        containerView.layer.borderColor = UIColor.systemOrange.cgColor
        containerView.backgroundColor = .systemBackground
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
        ])
    }
    
    func configure(with text: String, isSelected: Bool) {
        label.text = text
        containerView.backgroundColor = isSelected ? .systemOrange : .systemBackground
        label.textColor = isSelected ? .white : .label
        containerView.layer.borderColor = isSelected ? UIColor.clear.cgColor : UIColor.systemOrange.cgColor
    }
}


#Preview{
    EventListViewController()
}
