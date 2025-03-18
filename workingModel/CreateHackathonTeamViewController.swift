//
//  CreateHackathonTeamViewController.swift
//  ThriveUp
//
//  Created by Sanidhya's MacBook Pro on 19/03/25.
//


//
//  CreateHackathonTeamViewController.swift
//  workingModel
//
//  Created by ThriveUp on 2025-03-18.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class CreateHackathonTeamViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    private var event: EventModel
    private var userId: String?
    private var userName: String = "Team Lead"
    
    private var participants: [RegisteredParticipant] = []
    private var selectedParticipants: [RegisteredParticipant] = []
    
    private let headerView = UIView()
    private let teamNameTextField = UITextField()
    private let maxMembersSegmentedControl = UISegmentedControl(items: ["2", "3", "4", "5"])
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let createTeamButton = UIButton(type: .system)
    
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
        fetchParticipants()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
        title = "Create a Team"
        
        // Setup Header View
        headerView.backgroundColor = UIColor(red: 1.0, green: 0.95, blue: 0.9, alpha: 1.0)
        view.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        let teamNameLabel = UILabel()
        teamNameLabel.text = "Team Name"
        teamNameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        headerView.addSubview(teamNameLabel)
        teamNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Team Name TextField
        teamNameTextField.placeholder = "Enter team name"
        teamNameTextField.borderStyle = .roundedRect
        teamNameTextField.font = UIFont.systemFont(ofSize: 16)
        headerView.addSubview(teamNameTextField)
        teamNameTextField.translatesAutoresizingMaskIntoConstraints = false
        
        let maxMembersLabel = UILabel()
        maxMembersLabel.text = "Max Team Members"
        maxMembersLabel.font = UIFont.boldSystemFont(ofSize: 16)
        headerView.addSubview(maxMembersLabel)
        maxMembersLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Max Members Segmented Control
        maxMembersSegmentedControl.selectedSegmentIndex = 2 // Default to 4
        headerView.addSubview(maxMembersSegmentedControl)
        maxMembersSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        let selectMembersLabel = UILabel()
        selectMembersLabel.text = "Select Team Members"
        selectMembersLabel.font = UIFont.boldSystemFont(ofSize: 16)
        headerView.addSubview(selectMembersLabel)
        selectMembersLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup Table View
        tableView.register(ParticipantCell.self, forCellReuseIdentifier: "ParticipantCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 70
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup Create Team Button
        createTeamButton.setTitle("Create Team", for: .normal)
        createTeamButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        createTeamButton.backgroundColor = .orange
        createTeamButton.setTitleColor(.white, for: .normal)
        createTeamButton.layer.cornerRadius = 10
        createTeamButton.addTarget(self, action: #selector(createTeamButtonTapped), for: .touchUpInside)
        view.addSubview(createTeamButton)
        createTeamButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup Constraints
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            teamNameLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            teamNameLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            teamNameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            teamNameTextField.topAnchor.constraint(equalTo: teamNameLabel.bottomAnchor, constant: 8),
            teamNameTextField.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            teamNameTextField.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            maxMembersLabel.topAnchor.constraint(equalTo: teamNameTextField.bottomAnchor, constant: 16),
            maxMembersLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            maxMembersLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            maxMembersSegmentedControl.topAnchor.constraint(equalTo: maxMembersLabel.bottomAnchor, constant: 8),
            maxMembersSegmentedControl.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            maxMembersSegmentedControl.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            selectMembersLabel.topAnchor.constraint(equalTo: maxMembersSegmentedControl.bottomAnchor, constant: 16),
            selectMembersLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            selectMembersLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            selectMembersLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: createTeamButton.topAnchor, constant: -16),
            
            createTeamButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            createTeamButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            createTeamButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            createTeamButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Table View DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return participants.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantCell", for: indexPath) as! ParticipantCell
        let participant = participants[indexPath.row]
        cell.configure(with: participant)
        
        // Check if this participant is selected
        cell.accessoryType = selectedParticipants.contains(where: { $0.id == participant.id }) ? .checkmark : .none
        
        return cell
    }
    
    // MARK: - Table View Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let participant = participants[indexPath.row]
        
        // Check if we've already reached max members
        let maxMembers = Int(maxMembersSegmentedControl.titleForSegment(at: maxMembersSegmentedControl.selectedSegmentIndex) ?? "4") ?? 4
        
        // Add/remove participant from selected list
        if let index = selectedParticipants.firstIndex(where: { $0.id == participant.id }) {
            // Remove participant if already selected
            selectedParticipants.remove(at: index)
        } else {
            // Add participant if not already selected and not at max capacity
            if selectedParticipants.count < maxMembers - 1 { // -1 to account for team lead (current user)
                selectedParticipants.append(participant)
            } else {
                // Show alert that team is at max capacity
                let alert = UIAlertController(
                    title: "Team at Max Capacity",
                    message: "You can only select up to \(maxMembers - 1) team members.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
        }
        
        // Reload the row to update the checkmark
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    // MARK: - Actions
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func createTeamButtonTapped() {
        // Validate team name
        guard let teamName = teamNameTextField.text, !teamName.isEmpty else {
            let alert = UIAlertController(title: "Missing Team Name", message: "Please enter a name for your team.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Create the team
        createTeam(name: teamName)
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
    
    private func fetchParticipants() {
        db.collection("registrations")
            .whereField("eventId", isEqualTo: event.eventId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching participants: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                var newParticipants: [RegisteredParticipant] = []
                
                for document in documents {
                    let data = document.data()
                    let userId = data["uid"] as? String ?? ""
                    
                    // Skip current user
                    if userId == self.userId {
                        continue
                    }
                    
                    let participant = RegisteredParticipant(
                        id: document.documentID,
                        userId: userId,
                        name: data["name"] as? String ?? "",
                        phoneNumber: data["phone_number"] as? String ?? "",
                        yearOfStudy: data["year_of_study"] as? String ?? "",
                        course: data["course"] as? String ?? "",
                        department: data["department"] as? String ?? "",
                        specialization: data["specialization"] as? String ?? "",
                        eventId: data["eventId"] as? String ?? "",
                        registrationDate: (data["registrationDate"] as? Timestamp)?.dateValue() ?? Date(),
                        profileImageURL: nil
                    )
                    
                    newParticipants.append(participant)
                }
                
                self.participants = newParticipants
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }
    
    private func createTeam(name: String) {
        guard let userId = self.userId else {
            let alert = UIAlertController(title: "Authentication Error", message: "You must be logged in to create a team.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Get max team members from segmented control
        let maxMembers = Int(maxMembersSegmentedControl.titleForSegment(at: maxMembersSegmentedControl.selectedSegmentIndex) ?? "4") ?? 4
        
        // Create array of member IDs (including team lead)
        var memberIds = [userId]
        var memberNames = [userName]
        
        // Add selected participants
        for participant in selectedParticipants {
            memberIds.append(participant.userId)
            memberNames.append(participant.name)
        }
        
        // Create team data
        let teamData: [String: Any] = [
            "name": name,
            "eventId": event.eventId,
            "teamLeadId": userId,
            "teamLeadName": userName,
            "memberIds": memberIds,
            "memberNames": memberNames,
            "maxMembers": maxMembers,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        // Add to "hackathonTeams" collection
        db.collection("hackathonTeams").addDocument(data: teamData) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error creating team: \(error.localizedDescription)")
                let alert = UIAlertController(title: "Team Creation Failed", message: "There was an error creating your team. Please try again.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
                return
            }
            
            // Successfully created team
            print("Successfully created team")
            
            // Send invitations to selected participants
            self.sendTeamInvitations()
        }
    }
    
    private func sendTeamInvitations() {
        guard let userId = self.userId else { return }
        
        for participant in selectedParticipants {
            // Create notification
            let notificationData: [String: Any] = [
                "title": "Team Invitation",
                "message": "\(userName) has invited you to join their hackathon team for \(event.title)",
                "timestamp": FieldValue.serverTimestamp(),
                "isRead": false,
                "senderId": userId,
                "eventId": event.eventId
            ]
            
            // Add notification to user's notifications collection
            db.collection("users").document(participant.userId).collection("notifications").addDocument(data: notificationData)
        }
        
        // Show success alert and navigate back to events
        let alert = UIAlertController(
            title: "Team Created",
            message: "Your team has been created successfully! Invitations have been sent to selected participants.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popToRootViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
}

// MARK: - Participant Cell
class ParticipantCell: UITableViewCell {
    
    private let nameLabel = UILabel()
    private let detailsLabel = UILabel()
    private let avatarImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Avatar Image
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 25
        avatarImageView.backgroundColor = .lightGray
        avatarImageView.image = UIImage(systemName: "person.circle")
        avatarImageView.tintColor = .gray
        contentView.addSubview(avatarImageView)
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Name Label
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        contentView.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Details Label
        detailsLabel.font = UIFont.systemFont(ofSize: 14)
        detailsLabel.textColor = .gray
        contentView.addSubview(detailsLabel)
        detailsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 50),
            avatarImageView.heightAnchor.constraint(equalToConstant: 50),
            
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            detailsLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            detailsLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            detailsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            detailsLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with participant: RegisteredParticipant) {
        nameLabel.text = participant.name
        detailsLabel.text = "\(participant.course), \(participant.yearOfStudy) Year"
        
        // Load profile image if available
        if let profileImageURL = participant.profileImageURL, let url = URL(string: profileImageURL) {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url) {
                    DispatchQueue.main.async { [weak self] in
                        self?.avatarImageView.image = UIImage(data: data)
                    }
                }
            }
        }
    }
}
