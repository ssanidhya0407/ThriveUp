//
//  HackathonTeamSelectionViewController.swift
//  ThriveUp
//
//  Created by Sanidhya's MacBook Pro on 19/03/25.
//


//
//  HackathonTeamSelectionViewController.swift
//  workingModel
//
//  Created by ThriveUp on 2025-03-18.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class HackathonTeamSelectionViewController: UIViewController {
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    private var event: EventModel
    private var userId: String?
    
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let createTeamButton = UIButton(type: .system)
    private let joinTeamButton = UIButton(type: .system)
    
    // MARK: - Initializer
    init(event: EventModel) {
        self.event = event
        super.init(nibName: nil, bundle: nil)
        
        // Get current user ID if available
        if let currentUser = Auth.auth().currentUser {
            self.userId = currentUser.uid
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        checkExistingTeam()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
        title = "Team Selection"
        navigationItem.hidesBackButton = true
        
        // Add gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor(red: 1.0, green: 0.7, blue: 0.4, alpha: 1.0).cgColor,
            UIColor.white.cgColor
        ]
        gradientLayer.locations = [0.0, 0.6]
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        // Setup Title Label
        titleLabel.text = "You're registered!"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 28)
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup Subtitle Label
        subtitleLabel.text = "Now, would you like to create a new team or join an existing team?"
        subtitleLabel.font = UIFont.systemFont(ofSize: 18)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        view.addSubview(subtitleLabel)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup Create Team Button
        createTeamButton.setTitle("Create a Team", for: .normal)
        createTeamButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        createTeamButton.backgroundColor = .orange
        createTeamButton.setTitleColor(.white, for: .normal)
        createTeamButton.layer.cornerRadius = 15
        createTeamButton.addTarget(self, action: #selector(createTeamButtonTapped), for: .touchUpInside)
        view.addSubview(createTeamButton)
        createTeamButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup Join Team Button
        joinTeamButton.setTitle("Join a Team", for: .normal)
        joinTeamButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        joinTeamButton.backgroundColor = .clear
        joinTeamButton.setTitleColor(.orange, for: .normal)
        joinTeamButton.layer.cornerRadius = 15
        joinTeamButton.layer.borderWidth = 2
        joinTeamButton.layer.borderColor = UIColor.orange.cgColor
        joinTeamButton.addTarget(self, action: #selector(joinTeamButtonTapped), for: .touchUpInside)
        view.addSubview(joinTeamButton)
        joinTeamButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup Constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            createTeamButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 60),
            createTeamButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            createTeamButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            createTeamButton.heightAnchor.constraint(equalToConstant: 60),
            
            joinTeamButton.topAnchor.constraint(equalTo: createTeamButton.bottomAnchor, constant: 30),
            joinTeamButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            joinTeamButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            joinTeamButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    // MARK: - Actions
    @objc private func createTeamButtonTapped() {
        let createTeamVC = CreateHackathonTeamViewController(event: event)
        navigationController?.pushViewController(createTeamVC, animated: true)
    }
    
    @objc private func joinTeamButtonTapped() {
        let joinTeamVC = JoinHackathonTeamViewController(event: event)
        navigationController?.pushViewController(joinTeamVC, animated: true)
    }
    
    // MARK: - Helper Methods
    private func checkExistingTeam() {
        guard let userId = self.userId else { return }
        
        // Check if the user is already in a team for this event
        db.collection("hackathonTeams")
            .whereField("eventId", isEqualTo: event.eventId)
            .whereField("memberIds", arrayContains: userId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error checking for existing team: \(error.localizedDescription)")
                    return
                }
                
                if let documents = snapshot?.documents, !documents.isEmpty {
                    // User is already in a team, show alert and navigate to team detail
                    DispatchQueue.main.async {
                        let alert = UIAlertController(
                            title: "You're already in a team",
                            message: "You are already part of a team for this hackathon.",
                            preferredStyle: .alert
                        )
                        
                        alert.addAction(UIAlertAction(title: "View Team", style: .default) { _ in
                            if let teamData = documents.first?.data(),
                               let teamId = documents.first?.documentID {
                                let team = HackathonTeam(
                                    id: teamId,
                                    name: teamData["name"] as? String ?? "Team",
                                    eventId: teamData["eventId"] as? String ?? "",
                                    teamLeadId: teamData["teamLeadId"] as? String ?? "",
                                    teamLeadName: teamData["teamLeadName"] as? String ?? "",
                                    memberIds: teamData["memberIds"] as? [String] ?? [],
                                    memberNames: teamData["memberNames"] as? [String] ?? [],
                                    maxMembers: teamData["maxMembers"] as? Int ?? 4,
                                    createdAt: (teamData["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                                )
                                
                                let teamDetailVC = HackathonTeamDetailViewController(team: team, event: self.event)
                                self.navigationController?.pushViewController(teamDetailVC, animated: true)
                            }
                        })
                        
                        self.present(alert, animated: true)
                    }
                }
            }
    }
}