//
//  GroupMemberVC.swift
//  ThriveUp
//
//  Created by Yash's Mackbook on 19/03/25.
//

import UIKit
import FirebaseFirestore

class GroupMemberVC: UIViewController {
    
    // MARK: - Properties
    private let eventId: String
    private var members: [EventGroupMember] = []
    private let db = Firestore.firestore()
    
    // UI Components
    private let tableView = UITableView()
    // MARK: - Initialization
    init(eventId: String) {
        self.eventId = eventId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadMembers()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .white
        title = "Event Members"
        
        // Setup table view
        tableView.register(MemberCell.self, forCellReuseIdentifier: "MemberCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Data Loading
    private func loadMembers() {
        db.collection("eventGroups").document(eventId)
            .collection("members")
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self, let documents = snapshot?.documents else {
                    return
                }
                
                self.members = documents.compactMap { document -> EventGroupMember? in
                    let userId = document.documentID
                    guard let role = document.data()["role"] as? String,
                          let name = document.data()["name"] as? String else {
                        return nil
                    }
                    return EventGroupMember(userId: userId,
                                            name: name,
                                            role: role,
                                            joinedAt: (document.data()["joinedAt"] as? Timestamp)?.dateValue() ?? Date(),
                                            canChat: document.data()["canChat"] as? Bool ?? false,
                                            profileImageURL: document.data()["profileImageURL"] as? String)
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }
}

// MARK: - UITableViewDataSource
extension GroupMemberVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return members.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MemberCell", for: indexPath) as! MemberCell
        let member = members[indexPath.row]
        cell.configure(with: member)  // Configure cell with member details
        return cell
    }
}

// MARK: - UITableViewDelegate
extension GroupMemberVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let member = members[indexPath.row]
        showProfileForMember(member)
    }
    
    private func showProfileForMember(_ member: EventGroupMember) {
        if member.role == "organizer" {
            
            // Show organizer profile (You can implement a profile viewer for organizers)
        } else {
            // Show regular user profile (You can implement a profile viewer for regular members)
            let userProfileVC = UserProfileViewerController(userId: member.userId)
            navigationController?.pushViewController(userProfileVC, animated: true)
        }
    }
}
