//
//  EventGroupsListViewController.swift
//  ThriveUp
//
//  Created by Sanidhya's MacBook Pro on 16/03/25.
//


import UIKit
import FirebaseFirestore
import FirebaseAuth

class EventGroupsListViewController: UIViewController {
    private let tableView = UITableView()
    private let eventGroupManager = EventGroupManager()
    private var eventGroups: [(eventId: String, name: String, lastMessage: String?, timestamp: Date?)] = []
    private let currentUserID = Auth.auth().currentUser?.uid ?? ""
    private let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "My Event Groups"
        
        setupTableView()
        fetchEventGroups()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh the list when returning to this screen
        fetchEventGroups()
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ChatCell.self, forCellReuseIdentifier: ChatCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.separatorStyle = .singleLine
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func fetchEventGroups() {
        guard !currentUserID.isEmpty else {
            print("No user is logged in")
            return
        }
        
        // Find all event groups where the current user is a member
        db.collection("eventGroups")
            .whereField("uid", isEqualTo: currentUserID)
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching event groups: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    // No groups found
                    self.eventGroups = []
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                    return
                }
                
                // For each group the user is a member of, get the group details
                var pendingGroups = documents.count
                var newEventGroups: [(eventId: String, name: String, lastMessage: String?, timestamp: Date?)] = []
                
                for document in documents {
                    // Get the event group ID (parent document ID)
                    let eventId = document.reference.parent.parent?.documentID ?? ""
                    
                    if eventId.isEmpty { continue }
                    
                    // Fetch event details to get the name
                    self.db.collection("events").document(eventId).getDocument { (eventDoc, error) in
                        if let eventData = eventDoc?.data(),
                           let eventName = eventData["title"] as? String {
                            
                            // Fetch the most recent message (if any)
                            self.fetchLastMessage(for: eventId) { (message, timestamp) in
                                let groupInfo = (
                                    eventId: eventId,
                                    name: eventName,
                                    lastMessage: message,
                                    timestamp: timestamp
                                )
                                
                                newEventGroups.append(groupInfo)
                                pendingGroups -= 1
                                
                                // When all groups are processed, update the UI
                                if pendingGroups == 0 {
                                    // Sort by most recent message
                                    self.eventGroups = newEventGroups.sorted(by: {
                                        ($0.timestamp ?? Date.distantPast) > ($1.timestamp ?? Date.distantPast)
                                    })
                                    
                                    DispatchQueue.main.async {
                                        self.tableView.reloadData()
                                    }
                                }
                            }
                        } else {
                            pendingGroups -= 1
                            if pendingGroups == 0 {
                                self.eventGroups = newEventGroups.sorted(by: {
                                    ($0.timestamp ?? Date.distantPast) > ($1.timestamp ?? Date.distantPast)
                                })
                                
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                }
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
        return eventGroups.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ChatCell.identifier, for: indexPath) as? ChatCell else {
            return UITableViewCell()
        }
        
        let group = eventGroups[indexPath.row]
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
            profileImageURL: nil // You could add an event image here if available
        )
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedGroup = eventGroups[indexPath.row]
        navigateToEventGroup(eventId: selectedGroup.eventId)
    }
}
