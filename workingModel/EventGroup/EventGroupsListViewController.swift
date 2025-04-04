import UIKit
import FirebaseFirestore
import FirebaseAuth

class EventGroupsListViewController: UIViewController {
    private let tableView = UITableView()
    private let eventGroupManager = EventGroupManager()
    private var eventGroups: [(eventId: String, name: String, lastMessage: String?, timestamp: Date?, imageURL: String?)] = []
    private let currentUserID = Auth.auth().currentUser?.uid ?? ""
    private let db = Firestore.firestore()
    
    // UI Components (from ChatViewController)
    private let searchBar = UISearchBar()
    private let titleLabel = UILabel()
    private let titleStackView = UIStackView()
    private let createEventButton = UIButton(type: .system)
    
    // Filtered groups for search functionality
    private var filteredEventGroups: [(eventId: String, name: String, lastMessage: String?, timestamp: Date?, imageURL: String?)] = []
    
    // Timestamp to track the last fetch time
    private var lastFetchTime: Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupTitleStackView()
        setupSearchBar()
        setupTableView()
        fetchEventGroups()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Check if the data needs to be refreshed
        if shouldFetchData() {
            fetchEventGroups()
        }
    }
    
    private func shouldFetchData() -> Bool {
        // Add logic to determine if data needs to be fetched
        // For example, fetch data if it has been more than 5 minutes since the last fetch
        if let lastFetchTime = lastFetchTime {
            let currentTime = Date()
            let timeInterval = currentTime.timeIntervalSince(lastFetchTime)
            return timeInterval > 300 // 5 minutes
        }
        return true
    }
    
    private func setupTitleStackView() {
        // Configure titleLabel
        titleLabel.text = "Event Groups"
        titleLabel.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        titleLabel.textAlignment = .left
        
        // Configure titleStackView
        titleStackView.axis = .horizontal
        titleStackView.alignment = .center
        titleStackView.distribution = .equalSpacing
        titleStackView.spacing = 8
        
        // Add titleLabel and createEventButton to titleStackView
        titleStackView.addArrangedSubview(titleLabel)
        
        // Add titleStackView to the view
        view.addSubview(titleStackView)
        titleStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            titleStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            titleStackView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.placeholder = "Search events"
        
        // Style to match ChatViewController
        let greyColor = UIColor.systemGray6
        searchBar.barTintColor = greyColor
        searchBar.layer.cornerRadius = 12
        searchBar.clipsToBounds = true
        
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = greyColor
            textField.layer.cornerRadius = 12
            textField.borderStyle = .none
        }
        
        view.addSubview(searchBar)
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: titleStackView.bottomAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchBar.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ChatCell.self, forCellReuseIdentifier: ChatCell.identifier)
        tableView.rowHeight = 80
        tableView.separatorStyle = .none // Match ChatViewController
        tableView.backgroundColor = .white
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func createEventTapped() {
        // Implement navigation to create event screen
        // This is a placeholder for when you want to add event creation functionality
        print("Create event tapped")
        // let createEventVC = CreateEventViewController()
        // navigationController?.pushViewController(createEventVC, animated: true)
    }
    
    private func fetchEventGroups() {
        guard !currentUserID.isEmpty else {
            print("No user is logged in")
            return
        }
        
        // Find all event groups where the current user is a member
        db.collection("eventGroups").getDocuments { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching event groups: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                // No groups found
                self.eventGroups = []
                self.filteredEventGroups = []
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                return
            }
            
            // For each group, check if the user is a member
            var pendingGroups = documents.count
            var newEventGroups: [(eventId: String, name: String, lastMessage: String?, timestamp: Date?, imageURL: String?)] = []
            
            for document in documents {
                let eventId = document.documentID
                
                // Check if the current user is a member of this event group
                self.db.collection("eventGroups")
                    .document(eventId)
                    .collection("members")
                    .document(self.currentUserID)
                    .getDocument { [weak self] (memberDoc, memberError) in
                        guard let self = self else { return }
                        pendingGroups -= 1
                        
                        // If the document exists, the user is a member
                        if let memberDoc = memberDoc, memberDoc.exists {
                            // Fetch event details to get the name and image URL
                            self.db.collection("events").document(eventId).getDocument { [weak self] (eventDoc, error) in
                                guard let self = self else { return }
                                
                                if let eventData = eventDoc?.data(),
                                   let eventName = eventData["title"] as? String {
                                    
                                    // Get the image URL if available
                                    let imageURL = eventData["imageName"] as? String
                                    
                                    // Fetch the most recent message
                                    self.fetchLastMessage(for: eventId) { (message, timestamp) in
                                        let groupInfo = (
                                            eventId: eventId,
                                            name: eventName,
                                            lastMessage: message,
                                            timestamp: timestamp,
                                            imageURL: imageURL
                                        )
                                        
                                        newEventGroups.append(groupInfo)
                                        
                                        // When all groups are processed, update the UI
                                        if pendingGroups == 0 {
                                            // Sort by most recent message
                                            self.eventGroups = newEventGroups.sorted(by: {
                                                ($0.timestamp ?? Date.distantPast) > ($1.timestamp ?? Date.distantPast)
                                            })
                                            
                                            self.filteredEventGroups = self.eventGroups
                                            
                                            DispatchQueue.main.async {
                                                self.tableView.reloadData()
                                            }
                                        }
                                    }
                                } else if pendingGroups == 0 {
                                    self.eventGroups = newEventGroups.sorted(by: {
                                        ($0.timestamp ?? Date.distantPast) > ($1.timestamp ?? Date.distantPast)
                                    })
                                    
                                    self.filteredEventGroups = self.eventGroups
                                    
                                    DispatchQueue.main.async {
                                        self.tableView.reloadData()
                                    }
                                }
                            }
                        } else if pendingGroups == 0 {
                            self.eventGroups = newEventGroups.sorted(by: {
                                ($0.timestamp ?? Date.distantPast) > ($1.timestamp ?? Date.distantPast)
                            })
                            
                            self.filteredEventGroups = self.eventGroups
                            
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        }
                    }
            }
        }
    }
    
    private func fetchLastMessage(for eventId: String, completion: @escaping (String?, Date?) -> Void) {
        db.collection("eventGroups").document(eventId)
            .collection("messages")
            .order(by: "timestamp", descending: true)
            .limit(to: 1)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error fetching last message: \(error.localizedDescription)")
                    completion(nil, nil)
                    return
                }
                
                guard let document = snapshot?.documents.first,
                      let message = document.data()["text"] as? String,
                      let timestamp = document.data()["timestamp"] as? Timestamp else {
                    completion(nil, nil)
                    return
                }
                
                completion(message, timestamp.dateValue())
            }
    }
    
    private func navigateToEventGroup(eventId: String) {
        // Determine if current user is an organizer of this event
        db.collection("eventGroups").document(eventId)
            .collection("members").document(currentUserID)
            .getDocument { [weak self] (document, error) in
                guard let self = self else { return }
                
                let isOrganizer = document?.data()?["role"] as? String == "organizer"
                
                DispatchQueue.main.async {
                    let eventGroupVC = EventGroupViewController(eventId: eventId, isOrganizer: isOrganizer)
                    self.navigationController?.pushViewController(eventGroupVC, animated: true)
                }
            }
    }
}

// MARK: - UITableViewDataSource and UITableViewDelegate
extension EventGroupsListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredEventGroups.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ChatCell.identifier, for: indexPath) as? ChatCell else {
            return UITableViewCell()
        }
        
        let group = filteredEventGroups[indexPath.row]
        let messageText = group.lastMessage ?? "No messages yet"
        
        // Format timestamp if available
        var timeString = ""
        if let timestamp = group.timestamp {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            timeString = formatter.string(from: timestamp)
        }
        
        cell.configure(
            with: group.name,
            message: messageText,
            time: timeString,
            profileImageURL: group.imageURL // Pass the image URL
        )
        
        // Use cached images to prevent flickering
        if let imageURL = group.imageURL, let url = URL(string: imageURL) {
            ImageCache.shared.image(for: url) { image in
                DispatchQueue.main.async {
                    // Ensure the cell is still visible and correct before updating
                    if tableView.indexPath(for: cell) == indexPath {
                        cell.profileImageView.image = image
                    }
                }
            }
        } else {
            cell.profileImageView.image = UIImage(named: "placeholder") // Use a placeholder image
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedGroup = filteredEventGroups[indexPath.row]
        navigateToEventGroup(eventId: selectedGroup.eventId)
    }
}

// MARK: - UISearchBarDelegate
extension EventGroupsListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredEventGroups = eventGroups
        } else {
            filteredEventGroups = eventGroups.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
