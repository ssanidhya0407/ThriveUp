import UIKit
import FirebaseFirestore
import FirebaseStorage

class EventViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UISearchBarDelegate, FilterViewControllerDelegate {
    
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupGradientBackground() // Add gradient background first
        setupFeedLabel()
        setupSearchBar()
        setupFilterButton()
        setupCollectionView()
        fetchEventsFromFirestore()
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

    // MARK: - Feed Label
    private func setupFeedLabel() {
        feedLabel.text = "Discover"
        feedLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold) // Increased font size from 24 to 32
        feedLabel.textAlignment = .left
        view.addSubview(feedLabel)
        feedLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            feedLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16), // Moved up since logo is removed
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
        collectionView.backgroundColor = .clear // Keep collection view transparent so gradient shows properly

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
            eventDetailVC.openedFromEventVC = true // Set the flag
            
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

    // MARK: - FilterViewControllerDelegate
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
