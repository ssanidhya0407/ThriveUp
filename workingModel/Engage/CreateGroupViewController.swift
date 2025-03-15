//
//  CreateGroupViewController.swift
//  ThriveUp
//
//  Created by Sanidhya's MacBook Pro on 14/03/25.
//


//
//  CreateGroupViewController.swift
//  ThriveUp
//
//  Created by palak seth on 12/03/25.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore

class CreateGroupViewController: UIViewController {
    var currentUser: User?
    var friends: [User] = []
    var selectedFriends: [User] = []
    let groupNameTextField = UITextField()
    let tableView = UITableView()
    let createButton = UIButton(type: .system)
    private var db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .white // Set background color
        
        groupNameTextField.placeholder = "Enter Group Name"
        groupNameTextField.borderStyle = .roundedRect
        groupNameTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(groupNameTextField)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        createButton.setTitle("Create Group", for: .normal)
        createButton.setTitleColor(.white, for: .normal)
        createButton.backgroundColor = .systemBlue
        createButton.layer.cornerRadius = 8
        createButton.translatesAutoresizingMaskIntoConstraints = false
        createButton.addTarget(self, action: #selector(createGroup), for: .touchUpInside)
        view.addSubview(createButton)

        // Add constraints
        NSLayoutConstraint.activate([
            groupNameTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            groupNameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            groupNameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            groupNameTextField.heightAnchor.constraint(equalToConstant: 40),

            tableView.topAnchor.constraint(equalTo: groupNameTextField.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: createButton.topAnchor, constant: -20),

            createButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            createButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    
    @objc private func createGroup() {
        guard let groupName = groupNameTextField.text, !groupName.isEmpty else { return }
        guard let currentUser = currentUser else { return }
        
        var memberIDs = selectedFriends.map { $0.id }
        memberIDs.append(currentUser.id)
        
        let groupID = UUID().uuidString
        let groupData: [String: Any] = [
            "id": groupID,
            "name": groupName,
            "members": memberIDs,
            "createdBy": currentUser.id,
            "timestamp": Timestamp()
        ]
        
        db.collection("groups").document(groupID).setData(groupData) { error in
            if let error = error {
                print("Error creating group: \(error)")
            } else {
                DispatchQueue.main.async {
                    self.dismiss(animated: true) // ✅ Ensures screen closes after group creation
                }
            }
        }
    }
}
extension CreateGroupViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let friend = friends[indexPath.row]
        
        cell.textLabel?.text = friend.name
        cell.accessoryType = selectedFriends.contains(where: { $0.id == friend.id }) ? .checkmark : .none

        return cell
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let friend = friends[indexPath.row]

        if let index = selectedFriends.firstIndex(where: { $0.id == friend.id }) {
            selectedFriends.remove(at: index) // Deselect if already selected
        } else {
            selectedFriends.append(friend) // Select if not already in the list
        }

        tableView.reloadRows(at: [indexPath], with: .automatic) // Refresh row
    }

}
