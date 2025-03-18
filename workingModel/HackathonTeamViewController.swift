//
//  HackathonTeamViewController.swift
//  ThriveUp
//
//  Created by Sanidhya's MacBook Pro on 18/03/25.
//


import UIKit
import FirebaseFirestore
import FirebaseAuth

class HackathonTeamViewController: UIViewController {
    
    // MARK: - Properties
    private let event: EventModel
    private let db = Firestore.firestore()
    private var teams: [Team] = []
    
    // UI Elements
    private let segmentedControl = UISegmentedControl(items: ["Join Team", "Create Team"])
    private let teamTableView = UITableView()
    private let createTeamView = UIView()
    private let teamNameField = UITextField()
    private let teamSizeField = UITextField()
    private let participantTableView = UITableView()
    private let createTeamButton = UIButton(type: .system)
    private var selectedParticipants: [String] = []
    private var participants: [Participant] = []
    
    // Models
    struct Team {
        let id: String
        let name: String
        let leaderId: String
        let leaderName: String
        let currentMemberCount: Int
        let maxMemberCount: Int
        let members: [String]
    }
    
    struct Participant {
        let id: String
        let name: String
        let selected: Bool
    }
    
    // MARK: - Initialization
    init(event: EventModel) {
        self.event = event
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchTeams()
        fetchParticipants()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
        title = "Hackathon Teams"
        
        // Setup Segmented Control
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        view.addSubview(segmentedControl)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup Team Table View (for Join Team)
        teamTableView.delegate = self
        teamTableView.dataSource = self
        teamTableView.register(TeamCell.self, forCellReuseIdentifier: "TeamCell")
        teamTableView.rowHeight = 100
        view.addSubview(teamTableView)
        teamTableView.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup Create Team View
        setupCreateTeamView()
        
        NSLayoutConstraint.activate([
            // Segmented Control Constraints
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Team Table View Constraints
            teamTableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 20),
            teamTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            teamTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            teamTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Create Team View Constraints
            createTeamView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 20),
            createTeamView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            createTeamView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            createTeamView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Initially hide Create Team View
        createTeamView.isHidden = true
    }
    
    private func setupCreateTeamView() {
        view.addSubview(createTeamView)
        createTeamView.translatesAutoresizingMaskIntoConstraints = false
        
        // Team Name Field
        teamNameField.placeholder = "Team Name"
        teamNameField.borderStyle = .roundedRect
        createTeamView.addSubview(teamNameField)
        teamNameField.translatesAutoresizingMaskIntoConstraints = false
        
        // Team Size Field
        teamSizeField.placeholder = "Team Size (max)"
        teamSizeField.borderStyle = .roundedRect
        teamSizeField.keyboardType = .numberPad
        createTeamView.addSubview(teamSizeField)
        teamSizeField.translatesAutoresizingMaskIntoConstraints = false
        
        // Participant Selection Table View
        participantTableView.delegate = self
        participantTableView.dataSource = self
        participantTableView.register(ParticipantCell.self, forCellReuseIdentifier: "ParticipantCell")
        participantTableView.rowHeight = 70
        createTeamView.addSubview(participantTableView)
        participantTableView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create Team Button
        createTeamButton.setTitle("Create Team", for: .normal)
        createTeamButton.backgroundColor = .orange
        createTeamButton.setTitleColor(.white, for: .normal)
        createTeamButton.layer.cornerRadius = 10
        createTeamButton.addTarget(self, action: #selector(createTeamButtonTapped), for: .touchUpInside)
        createTeamView.addSubview(createTeamButton)
        createTeamButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Team Name Field Constraints
            teamNameField.topAnchor.constraint(equalTo: createTeamView.topAnchor, constant: 20),
            teamNameField.leadingAnchor.constraint(equalTo: createTeamView.leadingAnchor, constant: 20),
            teamNameField.trailingAnchor.constraint(equalTo: createTeamView.trailingAnchor, constant: -20),
            teamNameField.heightAnchor.constraint(equalToConstant: 50),
            
            // Team Size Field Constraints
            teamSizeField.topAnchor.constraint(equalTo: teamNameField.bottomAnchor, constant: 15),
            teamSizeField.leadingAnchor.constraint(equalTo: createTeamView.leadingAnchor, constant: 20),
            teamSizeField.trailingAnchor.constraint(equalTo: createTeamView.trailingAnchor, constant: -20),
            teamSizeField.heightAnchor.constraint(equalToConstant: 50),
            
            // Participant Selection Table View Constraints
            participantTableView.topAnchor.constraint(equalTo: teamSizeField.bottomAnchor, constant: 20),
            participantTableView.leadingAnchor.constraint(equalTo: createTeamView.leadingAnchor),
            participantTableView.trailingAnchor.constraint(equalTo: createTeamView.trailingAnchor),
            participantTableView.bottomAnchor.constraint(equalTo: createTeamButton.topAnchor, constant: -20),
            
            // Create Team Button Constraints
            createTeamButton.leadingAnchor.constraint(equalTo: createTeamView.leadingAnchor, constant: 20),
            createTeamButton.trailingAnchor.constraint(equalTo: createTeamView.trailingAnchor, constant: -20),
            createTeamButton.bottomAnchor.constraint(equalTo: createTeamView.bottomAnchor, constant: -30),
            createTeamButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Actions
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            // "Join Team" selected
            teamTableView.isHidden = false
            createTeamView.isHidden = true
            fetchTeams()
        } else {
            // "Create Team" selected
            teamTableView.isHidden = true
            createTeamView.isHidden = false
            fetchParticipants()
        }
    }
    
    @objc private func createTeamButtonTapped() {
        guard let currentUser = Auth.auth().currentUser,
              let teamName = teamNameField.text, !teamName.isEmpty,
              let teamSizeText = teamSizeField.text, !teamSizeText.isEmpty,
              let teamSize = Int(teamSizeText) else {
            showAlert(title: "Error", message: "Please fill in all fields properly.")
            return
        }
        
        // Get user data for the team leader (current user)
        db.collection("users").document(currentUser.uid).getDocument { [weak self] documentSnapshot, error in
            guard let self = self,
                  let document = documentSnapshot,
                  let userData = document.data(),
                  let leaderName = userData["name"] as? String else {
                self?.showAlert(title: "Error", message: "Could not fetch user data.")
                return
            }
            
            // Create team data
            let teamData: [String: Any] = [
                "name": teamName,
                "leaderId": currentUser.uid,
                "leaderName": leaderName,
                "eventId": self.event.eventId,
                "maxMemberCount": teamSize,
                "createdAt": FieldValue.serverTimestamp(),
                "members": [currentUser.uid] + self.selectedParticipants,
                "pendingMembers": self.selectedParticipants
            ]
            
            // Save team to Firestore
            self.db.collection("hackathon_teams").addDocument(data: teamData) { error in
                if let error = error {
                    self.showAlert(title: "Error", message: "Failed to create team: \(error.localizedDescription)")
                    return
                }
                
                // Send notifications to selected participants
                for participantId in self.selectedParticipants {
                    let notificationData: [String: Any] = [
                        "type": "team_invitation",
                        "senderId": currentUser.uid,
                        "senderName": leaderName,
                        "receiverId": participantId,
                        "eventId": self.event.eventId,
                        "eventName": self.event.title,
                        "teamName": teamName,
                        "message": "\(leaderName) has invited you to join team '\(teamName)' for \(self.event.title)",
                        "createdAt": FieldValue.serverTimestamp(),
                        "read": false
                    ]
                    
                    self.db.collection("notifications").addDocument(data: notificationData)
                }
                
                // Show success message and navigate back
                self.showAlert(title: "Success", message: "Team created successfully!") {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    }
    
    // MARK: - Firestore Operations
    private func fetchTeams() {
        db.collection("hackathon_teams")
            .whereField("eventId", isEqualTo: event.eventId)
            .getDocuments { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching teams: \(error)")
                    return
                }
                
                self.teams = []
                
                for document in querySnapshot?.documents ?? [] {
                    let data = document.data()
                    
                    if let name = data["name"] as? String,
                       let leaderId = data["leaderId"] as? String,
                       let leaderName = data["leaderName"] as? String,
                       let maxMemberCount = data["maxMemberCount"] as? Int,
                       let members = data["members"] as? [String] {
                        
                        let team = Team(
                            id: document.documentID,
                            name: name,
                            leaderId: leaderId,
                            leaderName: leaderName,
                            currentMemberCount: members.count,
                            maxMemberCount: maxMemberCount,
                            members: members
                        )
                        
                        self.teams.append(team)
                    }
                }
                
                DispatchQueue.main.async {
                    self.teamTableView.reloadData()
                }
            }
    }
    
    private func fetchParticipants() {
        // Fetch all registered participants for this event
        db.collection("event_registrations")
            .whereField("eventId", isEqualTo: event.eventId)
            .getDocuments { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching participants: \(error)")
                    return
                }
                
                var participantIds: [String] = []
                
                for document in querySnapshot?.documents ?? [] {
                    if let userId = document.data()["userId"] as? String {
                        participantIds.append(userId)
                    }
                }
                
                // Fetch user details for each participant
                self.fetchParticipantDetails(participantIds: participantIds)
            }
    }
    
    private func fetchParticipantDetails(participantIds: [String]) {
        guard !participantIds.isEmpty else {
            DispatchQueue.main.async {
                self.participantTableView.reloadData()
            }
            return
        }
        
        var fetchedParticipants: [Participant] = []
        let dispatchGroup = DispatchGroup()
        
        for userId in participantIds {
            // Skip the current user
            if userId == Auth.auth().currentUser?.uid {
                continue
            }
            
            dispatchGroup.enter()
            db.collection("users").document(userId).getDocument { documentSnapshot, error in
                defer { dispatchGroup.leave() }
                
                if let document = documentSnapshot, document.exists,
                   let userData = document.data(),
                   let name = userData["name"] as? String {
                    
                    let participant = Participant(
                        id: userId,
                        name: name,
                        selected: false
                    )
                    
                    fetchedParticipants.append(participant)
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.participants = fetchedParticipants
            self.participantTableView.reloadData()
        }
    }
    
    // MARK: - Join Team
    private func joinTeam(_ team: Team) {
        guard let currentUser = Auth.auth().currentUser else {
            showAlert(title: "Error", message: "User not logged in")
            return
        }
        
        // Check if team is full
        if team.currentMemberCount >= team.maxMemberCount {
            showAlert(title: "Team Full", message: "This team has reached its maximum capacity.")
            return
        }
        
        // Check if user is already in the team
        if team.members.contains(currentUser.uid) {
            showAlert(title: "Already Joined", message: "You are already a member of this team.")
            return
        }
        
        // Send join request
        db.collection("users").document(currentUser.uid).getDocument { [weak self] documentSnapshot, error in
            guard let self = self,
                  let document = documentSnapshot,
                  let userData = document.data(),
                  let userName = userData["name"] as? String else {
                self?.showAlert(title: "Error", message: "Could not fetch user data.")
                return
            }
            
            // Update team with pending request
            self.db.collection("hackathon_teams").document(team.id).updateData([
                "pendingMembers": FieldValue.arrayUnion([currentUser.uid])
            ]) { error in
                if let error = error {
                    self.showAlert(title: "Error", message: "Failed to send join request: \(error.localizedDescription)")
                    return
                }
                
                // Send notification to team leader
                let notificationData: [String: Any] = [
                    "type": "team_join_request",
                    "senderId": currentUser.uid,
                    "senderName": userName,
                    "receiverId": team.leaderId,
                    "eventId": self.event.eventId,
                    "eventName": self.event.title,
                    "teamName": team.name,
                    "teamId": team.id,
                    "message": "\(userName) has requested to join your team '\(team.name)' for \(self.event.title)",
                    "createdAt": FieldValue.serverTimestamp(),
                    "read": false
                ]
                
                self.db.collection("notifications").addDocument(data: notificationData) { error in
                    if let error = error {
                        print("Error sending notification: \(error)")
                    }
                    
                    self.showAlert(title: "Request Sent", message: "Your request to join the team has been sent to the team leader.") {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension HackathonTeamViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == teamTableView {
            return teams.count
        } else if tableView == participantTableView {
            return participants.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == teamTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TeamCell", for: indexPath) as! TeamCell
            let team = teams[indexPath.row]
            cell.configure(with: team)
            return cell
        } else if tableView == participantTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantCell", for: indexPath) as! ParticipantCell
            let participant = participants[indexPath.row]
            cell.configure(with: participant, isSelected: selectedParticipants.contains(participant.id))
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == teamTableView {
            let team = teams[indexPath.row]
            let alert = UIAlertController(title: "Join Team", message: "Would you like to join the team '\(team.name)'?", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Join", style: .default) { [weak self] _ in
                self?.joinTeam(team)
            })
            
            present(alert, animated: true)
        } else if tableView == participantTableView {
            let participant = participants[indexPath.row]
            
            // Toggle selection
            if selectedParticipants.contains(participant.id) {
                selectedParticipants.removeAll { $0 == participant.id }
            } else {
                selectedParticipants.append(participant.id)
            }
            
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
}

// MARK: - Custom Cell Classes
class TeamCell: UITableViewCell {
    
    private let teamNameLabel = UILabel()
    private let leaderNameLabel = UILabel()
    private let memberCountLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Configure teamNameLabel
        teamNameLabel.font = UIFont.boldSystemFont(ofSize: 18)
        contentView.addSubview(teamNameLabel)
        teamNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure leaderNameLabel
        leaderNameLabel.font = UIFont.systemFont(ofSize: 16)
        leaderNameLabel.textColor = .darkGray
        contentView.addSubview(leaderNameLabel)
        leaderNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure memberCountLabel
        memberCountLabel.font = UIFont.systemFont(ofSize: 14)
        memberCountLabel.textColor = .gray
        contentView.addSubview(memberCountLabel)
        memberCountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Team Name Label Constraints
            teamNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            teamNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            teamNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Leader Name Label Constraints
            leaderNameLabel.topAnchor.constraint(equalTo: teamNameLabel.bottomAnchor, constant: 8),
            leaderNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            leaderNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Member Count Label Constraints
            memberCountLabel.topAnchor.constraint(equalTo: leaderNameLabel.bottomAnchor, constant: 8),
            memberCountLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            memberCountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            memberCountLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with team: HackathonTeamViewController.Team) {
        teamNameLabel.text = team.name
        leaderNameLabel.text = "Team Lead: \(team.leaderName)"
        memberCountLabel.text = "Members: \(team.currentMemberCount)/\(team.maxMemberCount)"
        
        // Change text color if team is full
        if team.currentMemberCount >= team.maxMemberCount {
            memberCountLabel.textColor = .red
        } else {
            memberCountLabel.textColor = .gray
        }
    }
}

class ParticipantCell: UITableViewCell {
    
    private let nameLabel = UILabel()
    private let checkImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Configure nameLabel
        nameLabel.font = UIFont.systemFont(ofSize: 16)
        contentView.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure checkImageView
        checkImageView.contentMode = .scaleAspectFit
        checkImageView.tintColor = .orange
        contentView.addSubview(checkImageView)
        checkImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Name Label Constraints
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: checkImageView.leadingAnchor, constant: -16),
            
            // Check Image View Constraints
            checkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            checkImageView.widthAnchor.constraint(equalToConstant: 24),
            checkImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    func configure(with participant: HackathonTeamViewController.Participant, isSelected: Bool) {
        nameLabel.text = participant.name
        
        if isSelected {
            checkImageView.image = UIImage(systemName: "checkmark.circle.fill")
        } else {
            checkImageView.image = UIImage(systemName: "circle")
        }
    }
}


extension HackathonTeamViewController {
    // Send team invitation notifications
    private func sendTeamInvitations(teamId: String, completion: @escaping (Bool) -> Void) {
        guard let teamName = teamNameField.text, !teamName.isEmpty else {
            completion(false)
            return
        }
        
        NotificationHandler.shared.sendTeamInvitations(
            teamId: teamId,
            teamName: teamName,
            eventId: event.eventId,
            eventName: event.title,
            members: selectedParticipants,
            completion: completion
        )
    }
    
    // Create the team and send invitations
    // Create team and send invitations
    // Create team and send invitations
    private func createTeamWithNotifications() {
        guard let currentUser = Auth.auth().currentUser,
              let teamName = teamNameField.text, !teamName.isEmpty,
              let teamSizeText = teamSizeField.text, !teamSizeText.isEmpty,
              let teamSize = Int(teamSizeText) else {
            showAlert(title: "Error", message: "Please fill in all fields properly.")
            return
        }
        
        // Get user data for the team leader (current user)
        db.collection("users").document(currentUser.uid).getDocument { [weak self] documentSnapshot, error in
            // THIS IS THE LINE THAT NEEDS FIXING:
            // The issue is that "guard let self = self" doesn't check for Optional type
            guard let self = self else { return }
            
            guard let document = documentSnapshot,
                  let userData = document.data(),
                  let leaderName = userData["name"] as? String else {
                self.showAlert(title: "Error", message: "Could not fetch user data.")
                return
            }
            
            // Create team data
            let teamData: [String: Any] = [
                "name": teamName,
                "leaderId": currentUser.uid,
                "leaderName": leaderName,
                "eventId": self.event.eventId,
                "maxMemberCount": teamSize,
                "createdAt": FieldValue.serverTimestamp(),
                "members": [currentUser.uid],
                "pendingMembers": self.selectedParticipants
            ]
            
            // Save team to Firestore - CORRECTED CLOSURE SIGNATURE
            var teamDocRef: DocumentReference? = nil
            teamDocRef = self.db.collection("hackathon_teams").addDocument(data: teamData) { error in
                // This line also needs fixing:
                if let error = error {
                    self.showAlert(title: "Error", message: "Failed to create team: \(error.localizedDescription)")
                    return
                }
                
                if let teamId = teamDocRef?.documentID {
                    // Send notifications to team members
                    self.sendTeamInvitations(teamId: teamId) { success in
                        if success {
                            self.showAlert(title: "Success", message: "Team created and invitations sent!") {
                                self.navigationController?.popToRootViewController(animated: true)
                            }
                        } else {
                            self.showAlert(title: "Partial Success", message: "Team created but there were issues sending some invitations.")
                        }
                    }
                } else {
                    self.showAlert(title: "Success", message: "Team created successfully!") {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
            }
        }
    }
    
    
    
    
}
