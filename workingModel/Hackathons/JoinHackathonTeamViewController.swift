//
//  JoinHackathonTeamViewController.swift
//  ThriveUp
//
//  Created by Sanidhya's MacBook Pro on 19/03/25.
//


//
//  JoinHackathonTeamViewController.swift
//  workingModel
//
//  Created by ThriveUp on 2025-03-18.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class JoinHackathonTeamViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    private var event: EventModel
    private var userId: String?
    private var userName: String = "User"
    
    private var teams: [HackathonTeam] = []
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let noTeamsLabel = UILabel()
    
    // MARK: - Initializer
    init(event: EventModel) {
        self.event = event
        super.init(nibName: nil, bundle: nil)
        
        // Get current user ID if available
        if let currentUser = Auth.auth().currentUser {
            self.userId = currentUser.uid
            fetchUserName(userId: currentUser.uid)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchTeams()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
        title = "Join a Team"
        
        // Setup No Teams Label
        noTeamsLabel.text = "No teams available for this event yet."
        noTeamsLabel.font = UIFont.systemFont(ofSize: 16)
        noTeamsLabel.textColor = .gray
        noTeamsLabel.textAlignment = .center
        noTeamsLabel.isHidden = true
        view.addSubview(noTeamsLabel)
        noTeamsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup Table View
        tableView.register(TeamCell.self, forCellReuseIdentifier: "TeamCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 100
        tableView.separatorStyle = .singleLine
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup Constraints
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            noTeamsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noTeamsLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            noTeamsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            noTeamsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }
    
    // MARK: - Table View DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return teams.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TeamCell", for: indexPath) as! TeamCell
        let team = teams[indexPath.row]
        cell.configure(with: team)
        return cell
    }
    
    // MARK: - Table View Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let team = teams[indexPath.row]
        
        // Check if the team is full
        if team.isFull {
            let alert = UIAlertController(title: "Team is Full", message: "This team already has the maximum number of members.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Show confirmation alert
        let alert = UIAlertController(
            title: "Join Team?",
            message: "Would you like to send a request to join \(team.name)?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Send Request", style: .default) { [weak self] _ in
            self?.sendJoinRequest(to: team)
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Helper Methods
    private func fetchUserName(userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching user name: \(error.localizedDescription)")
                return
            }
            
            if let data = snapshot?.data(), let name = data["name"] as? String {
                self?.userName = name
            }
        }
    }
    
    private func fetchTeams() {
        guard let userId = self.userId else { return }
        
        db.collection("hackathonTeams")
            .whereField("eventId", isEqualTo: event.eventId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching teams: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                var availableTeams: [HackathonTeam] = []
                
                for document in documents {
                    let data = document.data()
                    let memberIds = data["memberIds"] as? [String] ?? []
                    
                    // Skip teams that already include the current user
                    if memberIds.contains(userId) {
                        continue
                    }
                    
                    let team = HackathonTeam(
                        id: document.documentID,
                        name: data["name"] as? String ?? "Unnamed Team",
                        eventId: data["eventId"] as? String ?? "",
                        teamLeadId: data["teamLeadId"] as? String ?? "",
                        teamLeadName: data["teamLeadName"] as? String ?? "Unknown Leader",
                        memberIds: memberIds,
                        memberNames: data["memberNames"] as? [String] ?? [],
                        maxMembers: data["maxMembers"] as? Int ?? 4,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                    
                    availableTeams.append(team)
                }
                
                self.teams = availableTeams
                
                // Show/hide no teams label
                self.noTeamsLabel.isHidden = !availableTeams.isEmpty
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }
    
    private func sendJoinRequest(to team: HackathonTeam) {
        guard let userId = self.userId else { return }
        
        // Create join request data
        let requestData: [String: Any] = [
            "teamId": team.id,
            "senderId": userId,
            "senderName": userName,
            "receiverId": team.teamLeadId,
            "receiverName": team.teamLeadName,
            "eventId": event.eventId,
            "status": "pending",
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        // Add to "teamJoinRequests" collection
        db.collection("teamJoinRequests").addDocument(data: requestData) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error sending join request: \(error.localizedDescription)")
                let alert = UIAlertController(title: "Request Failed", message: "There was an error sending your join request. Please try again.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
                return
            }
            
            // Create notification for team lead
            let notificationData: [String: Any] = [
                "title": "Team Join Request",
                "message": "\(self.userName) has requested to join your team \(team.name) for \(self.event.title)",
                "timestamp": FieldValue.serverTimestamp(),
                "isRead": false,
                "senderId": userId,
                "eventId": self.event.eventId,
                "teamId": team.id
            ]
            
            // Add notification to team lead's notifications collection
            self.db.collection("users").document(team.teamLeadId).collection("notifications").addDocument(data: notificationData)
            
            // Show success alert and navigate back to events
            let alert = UIAlertController(
                title: "Request Sent",
                message: "Your request to join \(team.name) has been sent. You'll be notified when the team lead responds.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                self?.navigationController?.popToRootViewController(animated: true)
            })
            
            self.present(alert, animated: true)
        }
    }
}

// MARK: - Team Cell
class TeamCell: UITableViewCell {
    
    private let teamNameLabel = UILabel()
    private let leadNameLabel = UILabel()
    private let memberCountLabel = UILabel()
    private let containerView = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Container View
        containerView.backgroundColor = UIColor(red: 1.0, green: 0.95, blue: 0.9, alpha: 1.0)
        containerView.layer.cornerRadius = 10
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowOffset = CGSize(width: 0, height: 1)
        containerView.layer.shadowRadius = 2
        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Team Name Label
        teamNameLabel.font = UIFont.boldSystemFont(ofSize: 18)
        containerView.addSubview(teamNameLabel)
        teamNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Lead Name Label
        leadNameLabel.font = UIFont.systemFont(ofSize: 14)
        leadNameLabel.textColor = .darkGray
        containerView.addSubview(leadNameLabel)
        leadNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Member Count Label
        memberCountLabel.font = UIFont.systemFont(ofSize: 14)
        memberCountLabel.textColor = .gray
        containerView.addSubview(memberCountLabel)
        memberCountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            teamNameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            teamNameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            teamNameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            leadNameLabel.topAnchor.constraint(equalTo: teamNameLabel.bottomAnchor, constant: 4),
            leadNameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            leadNameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            memberCountLabel.topAnchor.constraint(equalTo: leadNameLabel.bottomAnchor, constant: 4),
            memberCountLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            memberCountLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            memberCountLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with team: HackathonTeam) {
        teamNameLabel.text = team.name
        leadNameLabel.text = "Team Lead: \(team.teamLeadName)"
        memberCountLabel.text = "Members: \(team.memberIds.count) / \(team.maxMembers)"
        
        // Change background color if team is full
        containerView.backgroundColor = team.isFull ?
            UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0) :
            UIColor(red: 1.0, green: 0.95, blue: 0.9, alpha: 1.0)
    }
}
