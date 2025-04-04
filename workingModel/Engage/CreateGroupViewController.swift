import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class CreateGroupViewController: UIViewController {
    var currentUser: User?
    var friends: [User] = []
    var selectedFriends: [User] = []
    let groupNameTextField = UITextField()
    let tableView = UITableView()
    let createButton = UIButton(type: .system)
    let imageButton = UIButton(type: .system)
    private var db = Firestore.firestore()
    private var storage = Storage.storage()
    private var selectedImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // Image Button
        imageButton.setTitle("Select Group Image", for: .normal)
        imageButton.setTitleColor(.white, for: .normal)
        imageButton.backgroundColor = .systemBlue
        imageButton.layer.cornerRadius = 8
        imageButton.translatesAutoresizingMaskIntoConstraints = false
        imageButton.addTarget(self, action: #selector(selectImage), for: .touchUpInside)
        view.addSubview(imageButton)
        
        // Group Name TextField
        groupNameTextField.placeholder = "Enter Group Name"
        groupNameTextField.borderStyle = .roundedRect
        groupNameTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(groupNameTextField)
        
        // TableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        // Create Button
        createButton.setTitle("Create Group", for: .normal)
        createButton.setTitleColor(.white, for: .normal)
        createButton.backgroundColor = .systemOrange
        createButton.layer.cornerRadius = 8
        createButton.translatesAutoresizingMaskIntoConstraints = false
        createButton.addTarget(self, action: #selector(createGroup), for: .touchUpInside)
        view.addSubview(createButton)

        // Constraints
        NSLayoutConstraint.activate([
            imageButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            imageButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            imageButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            imageButton.heightAnchor.constraint(equalToConstant: 40),
            
            groupNameTextField.topAnchor.constraint(equalTo: imageButton.bottomAnchor, constant: 20),
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

    @objc private func selectImage() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true)
    }
    
    @objc private func createGroup() {
        guard let groupName = groupNameTextField.text, !groupName.isEmpty else {
            showAlert(message: "Please enter a group name")
            return
        }
        
        guard let currentUser = currentUser else {
            showAlert(message: "User not authenticated")
            return
        }
        
        guard !selectedFriends.isEmpty else {
            showAlert(message: "Please select at least one member")
            return
        }
        
        let groupID = UUID().uuidString
        
        // First upload image if selected
        if let image = selectedImage {
            uploadImage(image, groupID: groupID) { [weak self] imageURL in
                self?.createGroupDocument(groupID: groupID,
                                        groupName: groupName,
                                        currentUserID: currentUser.id,
                                        imageURL: imageURL)
            }
        } else {
            createGroupDocument(groupID: groupID,
                             groupName: groupName,
                             currentUserID: currentUser.id,
                             imageURL: nil)
        }
    }
    
    private func uploadImage(_ image: UIImage, groupID: String, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            completion(nil)
            return
        }
        
        let storageRef = storage.reference().child("groupImages/\(groupID).jpg")
        
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Error uploading image: \(error)")
                completion(nil)
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error)")
                    completion(nil)
                } else {
                    completion(url?.absoluteString)
                }
            }
        }
    }
    
    private func createGroupDocument(groupID: String,
                                  groupName: String,
                                  currentUserID: String,
                                  imageURL: String?) {
        // Create the main group document
        let groupData: [String: Any] = [
            "id": groupID,
            "name": groupName,
            "createdBy": currentUserID,
            "createdAt": Timestamp(),
            "imageURL": imageURL ?? NSNull(),
            "memberCount": selectedFriends.count + 1 // +1 for creator
        ]
        
        db.collection("groups").document(groupID).setData(groupData) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error creating group: \(error)")
                self.showAlert(message: "Failed to create group")
                return
            }
            
            // Add creator as first member
            self.addMemberToGroup(groupID: groupID,
                                userID: currentUserID,
                                isAdmin: true)
            
            // Add selected friends as members
            for friend in self.selectedFriends {
                self.addMemberToGroup(groupID: groupID,
                                    userID: friend.id,
                                    isAdmin: false)
            }
            
            // Update user documents with group reference
            self.updateUserGroupReferences(groupID: groupID,
                                        currentUserID: currentUserID)
            
            DispatchQueue.main.async {
                self.dismiss(animated: true)
            }
        }
    }
    
    private func addMemberToGroup(groupID: String, userID: String, isAdmin: Bool) {
        let memberData: [String: Any] = [
            "userId": userID,
            "joinedAt": Timestamp(),
            "isAdmin": isAdmin,
            "status": "active"
        ]
        
        db.collection("groups")
          .document(groupID)
          .collection("members")
          .document(userID)
          .setData(memberData) { error in
              if let error = error {
                  print("Error adding member \(userID) to group: \(error)")
              }
          }
    }
    
    private func updateUserGroupReferences(groupID: String, currentUserID: String) {
        // Update creator's groups
        db.collection("users").document(currentUserID).updateData([
            "groups": FieldValue.arrayUnion([groupID])
        ])
        // Update each member's groups
        for friend in selectedFriends {
            db.collection("users").document(friend.id).updateData([
                "groups": FieldValue.arrayUnion([groupID])
            ])
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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
            selectedFriends.remove(at: index)
        } else {
            selectedFriends.append(friend)
        }

        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

extension CreateGroupViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                             didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            selectedImage = image
            imageButton.setTitle("Image Selected", for: .normal)
        }
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
