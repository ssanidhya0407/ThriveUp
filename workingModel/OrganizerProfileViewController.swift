//
//  OrganizerProfileViewController.swift
//  ThriveUp
//
//  Created by Yash's Mackbook on 19/11/24.
//
import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class OrganizerProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: - Properties
    private var createdEvents: [EventModel] = []
    private let db = Firestore.firestore()
 

    // Profile Header
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "default_profile")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 50
        imageView.layer.borderWidth = 3
        imageView.layer.borderColor = UIColor.systemOrange.cgColor
        return imageView
    }()
    
    // Add these properties to your OrganizerProfileViewController
//    private let statsContainer: UIView = {
//        let view = UIView()
//        view.backgroundColor = .secondarySystemBackground
//        view.layer.cornerRadius = 12
//        view.layer.shadowColor = UIColor.black.cgColor
//        view.layer.shadowOpacity = 0.1
//        view.layer.shadowOffset = CGSize(width: 0, height: 2)
//        view.layer.shadowRadius = 4
//        return view
//    }()
    private let statsContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 16
        return view
    }()

    private let statsStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        return stackView
    }()

    // Scroll View
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    private let contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Name"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let emailLabel: UILabel = {
        let label = UILabel()
        label.text = "Email"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    // Segment Control
    private let segmentControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Details", "Events"])
        control.selectedSegmentIndex = 0
        control.selectedSegmentTintColor = .systemOrange
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        control.setTitleTextAttributes([.foregroundColor: UIColor.systemOrange], for: .normal)
        return control
    }()

    // Details Container
    private let detailsContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 16
        return view
    }()

    private let aboutLabel: UILabel = {
        let label = UILabel()
        label.text = "About"
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textColor = .black
        return label
    }()

    

    private let detailsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        return stackView
    }()

    // About Section
    private let aboutStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        return stackView
    }()
    private let aboutHeader: UILabel = {
        let label = UILabel()
        label.text = "ABOUT"
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .tertiaryLabel
        return label
    }()

    private let aboutDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "No description available"
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    // Contact Info
    private let contactStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        return stackView
    }()

    private let contactHeader: UILabel = {
        let label = UILabel()
        label.text = "CONTACT INFO"
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .tertiaryLabel
        return label
    }()

    private let contactDetailsLabel: UILabel = {
        let label = UILabel()
        label.text = "Not available"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    // Person of Contact
    private let pocStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        return stackView
    }()

    private let pocHeader: UILabel = {
        let label = UILabel()
        label.text = "PERSON OF CONTACT"
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .tertiaryLabel
        return label
    }()

    private let pocDetailsLabel: UILabel = {
        let label = UILabel()
        label.text = "Not available"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    

    private let eventsTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(EventTableViewCell.self, forCellReuseIdentifier: EventTableViewCell.identifier)
        tableView.isHidden = true
        return tableView
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        configureNavigationBar()
        fetchOrganizerData()
        fetchCreatedEvents()
        updateStatsView(eventsCount: 0)
        view.layoutIfNeeded()
    }

//    // MARK: - Setup UI
//    private func setupUI() {
//        view.backgroundColor = .white
//        view.addSubview(profileImageView)
//        view.addSubview(nameLabel)
//        view.addSubview(emailLabel)
//        view.addSubview(segmentControl)
//        view.addSubview(aboutLabel)
//        view.addSubview(aboutDescriptionLabel)
//        view.addSubview(detailsStackView)
//        view.addSubview(eventsTableView)
//
//        // Add detail views
//        let eventsCountView = createDetailView(title: "Number of Events", value: "0")
//        let contactView = createDetailView(title: "Contact", value: "-")
//        let pocView = createDetailView(title: "Person of Contact", value: "-")
//        [eventsCountView, contactView, pocView].forEach { detailsStackView.addArrangedSubview($0) }
//
//        eventsTableView.dataSource = self
//        eventsTableView.delegate = self
//    }
    
    
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Scroll View
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Profile Header
        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(emailLabel)
        
        // Stats View
           contentView.addSubview(statsContainer)
           statsContainer.addSubview(statsStack)
        
        // Segment Control
        contentView.addSubview(segmentControl)
        segmentControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        
        // Details Container
        contentView.addSubview(detailsContainer)
        detailsContainer.addSubview(detailsStackView)
        
        // About Section
        aboutStack.addArrangedSubview(aboutHeader)
        aboutStack.addArrangedSubview(aboutDescriptionLabel)
        detailsStackView.addArrangedSubview(aboutStack)
        
        // Contact Info
        contactStack.addArrangedSubview(contactHeader)
        contactStack.addArrangedSubview(contactDetailsLabel)
        detailsStackView.addArrangedSubview(contactStack)
        
        // Person of Contact
        pocStack.addArrangedSubview(pocHeader)
        pocStack.addArrangedSubview(pocDetailsLabel)
        detailsStackView.addArrangedSubview(pocStack)
        
        // Events Table
        contentView.addSubview(eventsTableView)
        eventsTableView.dataSource = self
        eventsTableView.delegate = self
        
        // Add gesture recognizer for image tap
        let imageTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleImageTap))
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(imageTapGesture)
    }

//    private func setupConstraints() {
//        profileImageView.translatesAutoresizingMaskIntoConstraints = false
//        nameLabel.translatesAutoresizingMaskIntoConstraints = false
//        emailLabel.translatesAutoresizingMaskIntoConstraints = false
//        segmentControl.translatesAutoresizingMaskIntoConstraints = false
//        aboutLabel.translatesAutoresizingMaskIntoConstraints = false
//        aboutDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
//        detailsStackView.translatesAutoresizingMaskIntoConstraints = false
//        eventsTableView.translatesAutoresizingMaskIntoConstraints = false
//
//        NSLayoutConstraint.activate([
//            profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
//            profileImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            profileImageView.widthAnchor.constraint(equalToConstant: 100),
//            profileImageView.heightAnchor.constraint(equalToConstant: 100),
//
//            nameLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor),
//            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16),
//            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//
//            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
//            emailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
//            emailLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
//
//            segmentControl.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
//            segmentControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            segmentControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//
//            aboutLabel.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 20),
//            aboutLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//
//            aboutDescriptionLabel.topAnchor.constraint(equalTo: aboutLabel.bottomAnchor, constant: 8),
//            aboutDescriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            aboutDescriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//
//            detailsStackView.topAnchor.constraint(equalTo: aboutDescriptionLabel.bottomAnchor, constant: 20),
//            detailsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            detailsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//
//            eventsTableView.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 16),
//            eventsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            eventsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            eventsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        ])
//    }
    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        statsContainer.translatesAutoresizingMaskIntoConstraints = false
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Scroll View
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Profile Image
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        // Name and Email
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            nameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            emailLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
        
        // Stats Container
        NSLayoutConstraint.activate([
//            statsContainer.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 24),
//            statsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            statsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            statsContainer.heightAnchor.constraint(equalToConstant: 80),
            
            statsContainer.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 24),
                statsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                statsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                statsContainer.heightAnchor.constraint(equalToConstant: 100), // Increased from 80 to 100
            
            statsStack.centerYAnchor.constraint(equalTo: statsContainer.centerYAnchor), // Center vertically
               statsStack.leadingAnchor.constraint(equalTo: statsContainer.leadingAnchor, constant: 16),
               statsStack.trailingAnchor.constraint(equalTo: statsContainer.trailingAnchor, constant: -16)
        ])
        
        // Segment Control
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            segmentControl.topAnchor.constraint(equalTo: statsContainer.bottomAnchor, constant: 16),
            segmentControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            segmentControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            segmentControl.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Details Container
        detailsContainer.translatesAutoresizingMaskIntoConstraints = false
        detailsStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            detailsContainer.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 16),
            detailsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            detailsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            detailsStackView.topAnchor.constraint(equalTo: detailsContainer.topAnchor, constant: 16),
            detailsStackView.leadingAnchor.constraint(equalTo: detailsContainer.leadingAnchor, constant: 16),
            detailsStackView.trailingAnchor.constraint(equalTo: detailsContainer.trailingAnchor, constant: -16),
            detailsStackView.bottomAnchor.constraint(equalTo: detailsContainer.bottomAnchor, constant: -16)
        ])
        
        // Events Table
        eventsTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            eventsTableView.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 16),
            eventsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            eventsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            eventsTableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            eventsTableView.heightAnchor.constraint(equalToConstant: 400)
        ])
    }
    private func updateStatsView(eventsCount: Int) {
        // Clear existing views
        statsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Events Stat
        let eventsStat = createStatView(count: eventsCount, title: "Events Posted", icon: UIImage(systemName: "calendar.badge.plus"))
        statsStack.addArrangedSubview(eventsStat)
    }

    private func createStatView(count: Int, title: String, icon: UIImage?) -> UIView {
        let container = UIView()
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        
        
        if let icon = icon {
            let iconView = UIImageView(image: icon)
            iconView.contentMode = .scaleAspectFit
            iconView.tintColor = .systemOrange
            iconView.heightAnchor.constraint(equalToConstant: 30).isActive = true
            stack.addArrangedSubview(iconView)
        }
        
        let countLabel = UILabel()
        countLabel.text = "\(count)"
        countLabel.font = .systemFont(ofSize: 24, weight: .bold)
        countLabel.textColor = .label
        stack.addArrangedSubview(countLabel)
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        stack.addArrangedSubview(titleLabel)
        
        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }
    private func createDetailView(title: String, value: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = .orange

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 14)
        valueLabel.textColor = .gray

        let stackView = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .leading
        return stackView
    }

    // MARK: - Navigation Bar
    private func configureNavigationBar() {
        navigationItem.title = "Organizer Profile"
        navigationController?.navigationBar.titleTextAttributes = [
            .font: UIFont.boldSystemFont(ofSize: 20),
            .foregroundColor: UIColor.black
        ]
        
        // Create Edit button
        let editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(handleEdit))
        
        // Create Logout button
        let logoutButton = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        
        // Set the buttons in order: Edit first, then Logout
        navigationItem.leftBarButtonItem = editButton
        navigationItem.rightBarButtonItem = logoutButton
    }


    @objc private func handleEdit() {
        let editVC = EditOrganizerViewController()
        editVC.name = nameLabel.text
        editVC.descriptionText = aboutDescriptionLabel.text
        editVC.contact = (detailsStackView.arrangedSubviews[1].subviews.last as? UILabel)?.text
        editVC.poc = (detailsStackView.arrangedSubviews[2].subviews.last as? UILabel)?.text
        editVC.imageUrl = "Current image URL if available" // Pass the current image URL

        editVC.onSave = { [weak self] updatedDetails in
            self?.updateProfile(with: updatedDetails)
        }

        navigationController?.pushViewController(editVC, animated: true)
    }

    private func updateProfile(with details: OrganizerDetails) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User ID not found.")
            return
        }

        let data: [String: Any] = [
            "name": details.name,
            "Description": details.description,
            "ContactDetails": details.contact,
            "POC": details.poc,
            "profileImageURL": details.imageUrl // Save the new image URL
        ]

        db.collection("users").document(userId).updateData(data) { error in
            if let error = error {
                print("Failed to update profile: \(error.localizedDescription)")
            } else {
                print("Profile updated successfully.")
                self.fetchOrganizerData() // Refresh UI with updated data
            }
        }
    }




    private func saveProfileData(userId: String, data: [String: Any]) {
        db.collection("users").document(userId).updateData(data) { [weak self] error in
            guard error == nil else { return }
            self?.fetchOrganizerData()
        }
    }
    
    @objc private func handleLogout() {
        do {
            try Auth.auth().signOut()
            let loginVC = GeneralTabbarController()
            if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate {
                sceneDelegate.window?.rootViewController = loginVC
                sceneDelegate.window?.makeKeyAndVisible()
            }
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }

// MARK: - Fetch Organizer Data
//    private func fetchOrganizerData() {
//        guard let userId = Auth.auth().currentUser?.uid else { return }
//
//        db.collection("users").document(userId).getDocument { [weak self] document, error in
//            guard let self = self, let data = document?.data(), error == nil else { return }
//
//            self.nameLabel.text = data["name"] as? String ?? "Organizer Name"
//            self.emailLabel.text = data["email"] as? String ?? "Email"
//            self.aboutDescriptionLabel.text = data["Description"] as? String ?? "No description provided."
//
//            if let contact = data["ContactDetails"] as? String,
//               let contactLabel = self.detailsStackView.arrangedSubviews[1].subviews.last as? UILabel {
//                contactLabel.text = contact
//            }
//
//            if let poc = data["POC"] as? String,
//               let pocLabel = self.detailsStackView.arrangedSubviews[2].subviews.last as? UILabel {
//                pocLabel.text = poc
//            }
//
//            if let profileImageURLString = data["profileImageURL"] as? String,
//               let profileImageURL = URL(string: profileImageURLString) {
//                self.loadProfileImage(from: profileImageURL)
//            }
//        }
//    }
//
//    private func loadProfileImage(from url: URL) {
//        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
//            guard let data = data, let image = UIImage(data: data) else { return }
//            DispatchQueue.main.async {
//                self?.profileImageView.image = image
//            }
//        }.resume()
//    }

    private func fetchOrganizerData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(userId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching user details: \(error.localizedDescription)")
                return
            }
            
            guard let data = document?.data() else {
                print("No user data found")
                return
            }
            
            DispatchQueue.main.async {
                self.nameLabel.text = data["name"] as? String ?? "Name"
                self.emailLabel.text = data["email"] as? String ?? "Email"
                
                // Remove events count from about description
                self.aboutDescriptionLabel.text = data["Description"] as? String ?? "No description available"
                
                if let contact = data["ContactDetails"] as? String, !contact.isEmpty {
                    self.contactDetailsLabel.text = contact
                } else {
                    self.contactDetailsLabel.text = "Not available"
                }
                
                if let poc = data["POC"] as? String, !poc.isEmpty {
                    self.pocDetailsLabel.text = poc
                } else {
                    self.pocDetailsLabel.text = "Not available"
                }
                
                if let profileImageURLString = data["profileImageURL"] as? String,
                   let profileImageURL = URL(string: profileImageURLString) {
                    self.loadProfileImage(from: profileImageURL)
                }
            }
        }
    }
    
    // MARK: - Image Handling
    @objc private func handleImageTap() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }

    private func loadProfileImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error downloading profile image: \(error.localizedDescription)")
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                print("Invalid image data")
                return
            }
            
            DispatchQueue.main.async {
                self.profileImageView.image = image
            }
        }.resume()
    }

    // MARK: - Image Picker Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        
        guard
            let editedImage = info[.editedImage] as? UIImage,
            let userId = Auth.auth().currentUser?.uid
        else { return }
        
        uploadProfileImage(editedImage, for: userId) { imageURL in
            self.db.collection("users").document(userId).updateData(["profileImageURL": imageURL]) { error in
                if let error = error {
                    print("Error updating image URL: \(error.localizedDescription)")
                } else {
                    self.profileImageView.image = editedImage
                }
            }
        }
    }

    private func uploadProfileImage(_ image: UIImage, for userId: String, completion: @escaping (String) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        let storageRef = Storage.storage().reference().child("profile_images/\(userId).jpg")
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                } else if let url = url {
                    completion(url.absoluteString)
                }
            }
        }
    }
    // MARK: - Fetch Created Events
    private func fetchCreatedEvents() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        db.collection("events").whereField("userId", isEqualTo: userId).whereField("status", isEqualTo: "accepted").getDocuments { [weak self] snapshot, error in
            guard let self = self, let documents = snapshot?.documents, error == nil else { return }
                
            self.createdEvents = documents.map { doc in
                let data = doc.data()
                
                // Handle speakers conversion from Firestore data to Speaker objects
                var speakersArray: [Speaker] = []
                if let speakersData = data["speakers"] as? [[String: Any]] {
                    speakersArray = speakersData.compactMap { speakerData in
                        // Convert each dictionary to a Speaker object
                        // Adjust the properties according to your Speaker model
                        let name = speakerData["name"] as? String ?? ""
                        let bio = speakerData["bio"] as? String ?? ""
                        let imageUrl = speakerData["imageUrl"] as? String ?? ""
                        
                        return Speaker(name: name, imageURL: imageUrl)
                    }
                }
                
                return EventModel(
                    eventId: doc.documentID,
                    title: data["title"] as? String ?? "Untitled Event",
                    category: data["category"] as? String ?? "Uncategorized",
                    attendanceCount: data["attendanceCount"] as? Int ?? 0,
                    organizerName: data["organizerName"] as? String ?? "Unknown Organizer",
                    date: data["date"] as? String ?? "Unknown Date",
                    time: data["time"] as? String ?? "Unknown Time",
                    location: data["location"] as? String ?? "Unknown Location",
                    locationDetails: data["locationDetails"] as? String ?? "",
                    imageName: data["imageName"] as? String ?? "",
                    speakers: speakersArray, // Use the converted Speaker array
                    userId: userId,
                    description: data["description"] as? String ?? "",
                    tags: data["tags"] as? [String] ?? [String]()
                )
            }

            if let eventsCountLabel = self.detailsStackView.arrangedSubviews[0].subviews.last as? UILabel {
                eventsCountLabel.text = "\(self.createdEvents.count)"
            }

            DispatchQueue.main.async {
                self.updateStatsView(eventsCount: self.createdEvents.count)
                self.eventsTableView.reloadData()
            }
        }
    }

       // MARK: - UITableView DataSource
       func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
           return createdEvents.count
       }

       func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
           let cell = tableView.dequeueReusableCell(withIdentifier: EventTableViewCell.identifier, for: indexPath) as! EventTableViewCell
           cell.configure(with: createdEvents[indexPath.row])
           return cell
       }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
           let selectedEvent = createdEvents[indexPath.row]
           let registrationsListVC = RegistrationListTabViewController(eventId: selectedEvent.eventId)
           navigationController?.pushViewController(registrationsListVC, animated: true)
       }
    

    @objc private func segmentChanged() {
        let isShowingEvents = segmentControl.selectedSegmentIndex == 1
        detailsContainer.isHidden = isShowingEvents
        eventsTableView.isHidden = !isShowingEvents
        
        if isShowingEvents {
            fetchCreatedEvents()
        }
    }
   }


class EventTableViewCell: UITableViewCell {

    static let identifier = "EventTableViewCell"

    private let eventImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .black
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Initializer
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(eventImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(dateLabel)

        NSLayoutConstraint.activate([
            eventImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            eventImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            eventImageView.widthAnchor.constraint(equalToConstant: 60),
            eventImageView.heightAnchor.constraint(equalToConstant: 60),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: eventImageView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: eventImageView.trailingAnchor, constant: 16),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            dateLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }

    func configure(with event: EventModel) {
        titleLabel.text = event.title
        dateLabel.text = "\(event.date) at \(event.time)"

        if let imageUrl = URL(string: event.imageName ?? "") {
            loadImage(from: imageUrl)
        } else {
            eventImageView.image = UIImage(named: "placeholderImage")
        }
    }

    private func loadImage(from url: URL) {
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url) {
                DispatchQueue.main.async {
                    self.eventImageView.image = UIImage(data: data)
                }
            }
        }
    }
}

//class EditOrganizerViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
//    // Your existing code
//
//    // MARK: - Properties
//    var name: String?
//    var descriptionText: String?
//    var contact: String?
//    var poc: String?
//    var imageUrl: String?
//    var onSave: ((OrganizerDetails) -> Void)?
//
//    // MARK: - UI Elements
//    private let profileImageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.image = UIImage(named: "defaultProfileImage")
//        imageView.contentMode = .scaleAspectFill
//        imageView.clipsToBounds = true
//        imageView.layer.cornerRadius = 50
//        imageView.layer.borderWidth = 1
//        imageView.layer.borderColor = UIColor.lightGray.cgColor
//        return imageView
//    }()
//
//    private let selectImageButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("Select Image", for: .normal)
//        button.addTarget(self, action: #selector(handleSelectImage), for: .touchUpInside)
//        return button
//    }()
//
//
//    private let nameTextField: UITextField = {
//        let textField = UITextField()
//        textField.borderStyle = .roundedRect
//        textField.placeholder = "Enter name"
//        return textField
//    }()
//
//    private let descriptionTextView: UITextView = {
//        let textView = UITextView()
//        textView.layer.borderWidth = 1
//        textView.layer.borderColor = UIColor.lightGray.cgColor
//        textView.layer.cornerRadius = 8
//        textView.font = UIFont.systemFont(ofSize: 16)
//        return textView
//    }()
//
//    private let contactTextField: UITextField = {
//        let textField = UITextField()
//        textField.borderStyle = .roundedRect
//        textField.placeholder = "Enter contact"
//        return textField
//    }()
//
//    private let pocTextField: UITextField = {
//        let textField = UITextField()
//        textField.borderStyle = .roundedRect
//        textField.placeholder = "Enter Person of Contact"
//        return textField
//    }()
//
//    private let saveButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("Save", for: .normal)
//        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
//        button.backgroundColor = .systemOrange
//        button.setTitleColor(.white, for: .normal)
//        button.layer.cornerRadius = 8
//        button.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
//        return button
//    }()
//
//    // MARK: - Lifecycle
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        setupConstraints()
//        populateFields()
//    }
//
//    // MARK: - Setup UI
//    // MARK: - Setup UI
//    private func setupUI() {
//        view.backgroundColor = .white
//        view.addSubview(profileImageView)
//        view.addSubview(selectImageButton)
//        view.addSubview(nameTextField)
//        view.addSubview(descriptionTextView)
//        view.addSubview(contactTextField)
//        view.addSubview(pocTextField)
//        view.addSubview(saveButton)
//    }
//
//
//    private func setupConstraints() {
//        profileImageView.translatesAutoresizingMaskIntoConstraints = false
//        selectImageButton.translatesAutoresizingMaskIntoConstraints = false
//        nameTextField.translatesAutoresizingMaskIntoConstraints = false
//        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
//        contactTextField.translatesAutoresizingMaskIntoConstraints = false
//        pocTextField.translatesAutoresizingMaskIntoConstraints = false
//        saveButton.translatesAutoresizingMaskIntoConstraints = false
//
//        NSLayoutConstraint.activate([
//            profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
//            profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            profileImageView.widthAnchor.constraint(equalToConstant: 100),
//            profileImageView.heightAnchor.constraint(equalToConstant: 100),
//
//            selectImageButton.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 10),
//            selectImageButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//
//            nameTextField.topAnchor.constraint(equalTo: selectImageButton.bottomAnchor, constant: 20),
//            nameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            nameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//
//            descriptionTextView.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 20),
//            descriptionTextView.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),
//            descriptionTextView.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
//            descriptionTextView.heightAnchor.constraint(equalToConstant: 100),
//
//            contactTextField.topAnchor.constraint(equalTo: descriptionTextView.bottomAnchor, constant: 20),
//            contactTextField.leadingAnchor.constraint(equalTo: descriptionTextView.leadingAnchor),
//            contactTextField.trailingAnchor.constraint(equalTo: descriptionTextView.trailingAnchor),
//
//            pocTextField.topAnchor.constraint(equalTo: contactTextField.bottomAnchor, constant: 20),
//            pocTextField.leadingAnchor.constraint(equalTo: contactTextField.leadingAnchor),
//            pocTextField.trailingAnchor.constraint(equalTo: contactTextField.trailingAnchor),
//
//            saveButton.topAnchor.constraint(equalTo: pocTextField.bottomAnchor, constant: 20),
//            saveButton.leadingAnchor.constraint(equalTo: pocTextField.leadingAnchor),
//            saveButton.trailingAnchor.constraint(equalTo: pocTextField.trailingAnchor),
//            saveButton.heightAnchor.constraint(equalToConstant: 50)
//        ])
//    }
//
//    @objc private func handleSelectImage() {
//        let imagePicker = UIImagePickerController()
//        imagePicker.delegate = self
//        imagePicker.sourceType = .photoLibrary
//        imagePicker.allowsEditing = true
//        present(imagePicker, animated: true, completion: nil)
//    }
//
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
//        picker.dismiss(animated: true, completion: nil)
//        if let editedImage = info[.editedImage] as? UIImage {
//            profileImageView.image = editedImage
//        } else if let originalImage = info[.originalImage] as? UIImage {
//            profileImageView.image = originalImage
//        }
//    }
//
//    private func populateFields() {
//        if let imageUrlString = imageUrl, let url = URL(string: imageUrlString) {
//            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
//                if let data = data, let image = UIImage(data: data) {
//                    DispatchQueue.main.async {
//                        self?.profileImageView.image = image
//                    }
//                }
//            }.resume()
//        }
//        nameTextField.text = name
//        descriptionTextView.text = descriptionText
//        contactTextField.text = contact
//        pocTextField.text = poc
//    }
//
//
//    // MARK: - Actions
//    @objc private func handleSave() {
//        guard let updatedName = nameTextField.text,
//              let updatedDescription = descriptionTextView.text,
//              let updatedContact = contactTextField.text,
//              let updatedPOC = pocTextField.text,
//              let profileImage = profileImageView.image,
//              let imageData = profileImage.jpegData(compressionQuality: 0.8) else {
//            return
//        }
//
//        // Upload image to Firebase Storage
//        let storageRef = Storage.storage().reference().child("profile_images/\(UUID().uuidString).jpg")
//        storageRef.putData(imageData, metadata: nil) { [weak self] metadata, error in
//            guard error == nil else {
//                print("Failed to upload image: \(error!.localizedDescription)")
//                return
//            }
//
//            // Get download URL
//            storageRef.downloadURL { url, error in
//                guard let url = url, error == nil else {
//                    print("Failed to fetch download URL: \(error!.localizedDescription)")
//                    return
//                }
//
//                // Pass updated details with image URL
//                let updatedDetails = OrganizerDetails(
//                    name: updatedName,
//                    description: updatedDescription,
//                    contact: updatedContact,
//                    poc: updatedPOC,
//                    imageUrl: url.absoluteString
//                )
//
//                self?.onSave?(updatedDetails)
//                self?.navigationController?.popViewController(animated: true)
//            }
//        }
//    }
//
//}
class EditOrganizerViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: - Properties
    var name: String?
    var descriptionText: String?
    var contact: String?
    var poc: String?
    var imageUrl: String?
    var onSave: ((OrganizerDetails) -> Void)?
    
    private var presidentName: String = ""
    private var vicePresidentName: String = ""

    // MARK: - UI Elements
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        return view
    }()

    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "defaultProfileImage")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 50
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        return imageView
    }()

    private let selectImageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Select Image", for: .normal)
        button.setTitleColor(.systemOrange, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.addTarget(self, action: #selector(handleSelectImage), for: .touchUpInside)
        return button
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Name"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        return label
    }()

    private let nameTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "Enter name"
        textField.font = UIFont.systemFont(ofSize: 16)
        return textField
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Description"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        return label
    }()

    private let descriptionTextView: UITextView = {
        let textView = UITextView()
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.cornerRadius = 8
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        return textView
    }()

    private let contactLabel: UILabel = {
        let label = UILabel()
        label.text = "Contact"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        return label
    }()

    private let contactTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "Enter contact"
        textField.font = UIFont.systemFont(ofSize: 16)
        return textField
    }()

    private let pocLabel: UILabel = {
        let label = UILabel()
        label.text = "Person of Contact"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        return label
    }()

    private let presidentLabel: UILabel = {
        let label = UILabel()
        label.text = "President"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        return label
    }()

    private let presidentTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "Enter president's name"
        textField.font = UIFont.systemFont(ofSize: 16)
        return textField
    }()

    private let vicePresidentLabel: UILabel = {
        let label = UILabel()
        label.text = "Vice President"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        return label
    }()

    private let vicePresidentTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "Enter vice president's name"
        textField.font = UIFont.systemFont(ofSize: 16)
        return textField
    }()

    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.backgroundColor = .systemOrange
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
        return button
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        populateFields()
        setupNavigationBar()
    }

    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(profileImageView)
        contentView.addSubview(selectImageButton)
        
        // Name section
        contentView.addSubview(nameLabel)
        contentView.addSubview(nameTextField)
        
        // Description section
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(descriptionTextView)
        
        // Contact section
        contentView.addSubview(contactLabel)
        contentView.addSubview(contactTextField)
        
        // Person of Contact section
        contentView.addSubview(pocLabel)
        contentView.addSubview(presidentLabel)
        contentView.addSubview(presidentTextField)
        contentView.addSubview(vicePresidentLabel)
        contentView.addSubview(vicePresidentTextField)
        
        // Save button
        contentView.addSubview(saveButton)
    }
    
    private func setupNavigationBar() {
        navigationItem.title = "Edit Profile"
        navigationController?.navigationBar.titleTextAttributes = [
            .font: UIFont.boldSystemFont(ofSize: 20),
            .foregroundColor: UIColor.black
        ]
    }

    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        selectImageButton.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        contactLabel.translatesAutoresizingMaskIntoConstraints = false
        contactTextField.translatesAutoresizingMaskIntoConstraints = false
        pocLabel.translatesAutoresizingMaskIntoConstraints = false
        presidentLabel.translatesAutoresizingMaskIntoConstraints = false
        presidentTextField.translatesAutoresizingMaskIntoConstraints = false
        vicePresidentLabel.translatesAutoresizingMaskIntoConstraints = false
        vicePresidentTextField.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false

        // Scroll view constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // Profile image and select button
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),
            
            selectImageButton.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 10),
            selectImageButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])

        // Name section
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: selectImageButton.bottomAnchor, constant: 30),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            nameTextField.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            nameTextField.heightAnchor.constraint(equalToConstant: 40)
        ])

        // Description section
        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            descriptionTextView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 4),
            descriptionTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            descriptionTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            descriptionTextView.heightAnchor.constraint(equalToConstant: 120)
        ])

        // Contact section
        NSLayoutConstraint.activate([
            contactLabel.topAnchor.constraint(equalTo: descriptionTextView.bottomAnchor, constant: 16),
            contactLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contactLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            contactTextField.topAnchor.constraint(equalTo: contactLabel.bottomAnchor, constant: 4),
            contactTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contactTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            contactTextField.heightAnchor.constraint(equalToConstant: 40)
        ])

        // Person of Contact section
        NSLayoutConstraint.activate([
            pocLabel.topAnchor.constraint(equalTo: contactTextField.bottomAnchor, constant: 16),
            pocLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            pocLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            presidentLabel.topAnchor.constraint(equalTo: pocLabel.bottomAnchor, constant: 8),
            presidentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            presidentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            presidentTextField.topAnchor.constraint(equalTo: presidentLabel.bottomAnchor, constant: 4),
            presidentTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            presidentTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            presidentTextField.heightAnchor.constraint(equalToConstant: 40),
            
            vicePresidentLabel.topAnchor.constraint(equalTo: presidentTextField.bottomAnchor, constant: 8),
            vicePresidentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            vicePresidentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            vicePresidentTextField.topAnchor.constraint(equalTo: vicePresidentLabel.bottomAnchor, constant: 4),
            vicePresidentTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            vicePresidentTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            vicePresidentTextField.heightAnchor.constraint(equalToConstant: 40)
        ])

        // Save button
        NSLayoutConstraint.activate([
            saveButton.topAnchor.constraint(equalTo: vicePresidentTextField.bottomAnchor, constant: 30),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }

    private func populateFields() {
        // Only load image if we have a URL and it's not the default image
        if let imageUrlString = imageUrl,
           !imageUrlString.isEmpty,
           let url = URL(string: imageUrlString) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.profileImageView.image = image
                    }
                }
            }.resume()
        } else {
            profileImageView.image = UIImage(named: "defaultProfileImage")
        }
        
        nameTextField.text = name
        descriptionTextView.text = descriptionText
        contactTextField.text = contact
        
        // Parse POC field into president and vice president
        if let poc = poc {
            let components = poc.components(separatedBy: "|")
            if components.count >= 1 {
                presidentTextField.text = components[0].trimmingCharacters(in: .whitespaces)
            }
            if components.count >= 2 {
                vicePresidentTextField.text = components[1].trimmingCharacters(in: .whitespaces)
            }
        }
    }

    // MARK: - Actions
    @objc private func handleSelectImage() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let editedImage = info[.editedImage] as? UIImage {
            profileImageView.image = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            profileImageView.image = originalImage
        }
    }

    @objc private func handleSave() {
        guard let updatedName = nameTextField.text,
              let updatedDescription = descriptionTextView.text,
              let updatedContact = contactTextField.text,
              let presidentName = presidentTextField.text,
              let vicePresidentName = vicePresidentTextField.text else {
            return
        }
        
        // Combine president and vice president into POC field
        let updatedPOC = "\(presidentName) | \(vicePresidentName)"
        
        if let profileImage = profileImageView.image,
           profileImage != UIImage(named: "defaultProfileImage"),
           let imageData = profileImage.jpegData(compressionQuality: 0.8) {
            // Upload new image if it's changed from default
            let storageRef = Storage.storage().reference().child("profile_images/\(UUID().uuidString).jpg")
            storageRef.putData(imageData, metadata: nil) { [weak self] metadata, error in
                guard error == nil else {
                    print("Failed to upload image: \(error!.localizedDescription)")
                    return
                }

                storageRef.downloadURL { url, error in
                    self?.completeSave(
                        name: updatedName,
                        description: updatedDescription,
                        contact: updatedContact,
                        poc: updatedPOC,
                        imageUrl: url?.absoluteString ?? self?.imageUrl
                    )
                }
            }
        } else {
            // Use existing image URL if no new image was selected
            completeSave(
                name: updatedName,
                description: updatedDescription,
                contact: updatedContact,
                poc: updatedPOC,
                imageUrl: self.imageUrl
            )
        }
    }

    private func completeSave(name: String, description: String, contact: String, poc: String, imageUrl: String?) {
        let updatedDetails = OrganizerDetails(
            name: name,
            description: description,
            contact: contact,
            poc: poc,
            imageUrl: imageUrl ?? ""
        )
        
        // Show success message
        let alert = UIAlertController(title: "Success", message: "Changes have been saved", preferredStyle: .alert)
        self.present(alert, animated: true, completion: nil)
        
        // Dismiss after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            alert.dismiss(animated: true) {
                self.onSave?(updatedDetails)
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}

// MARK: - OrganizerDetails Model
struct OrganizerDetails {
    let name: String
    let description: String
    let contact: String
    let poc: String
    let imageUrl: String?
}
#Preview{
    OrganizerProfileViewController()
}

