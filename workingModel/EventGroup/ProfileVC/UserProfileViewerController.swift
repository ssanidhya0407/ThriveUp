//
//  UserProfileViewerController.swift
//  ThriveUp
//
//  Created by Yash's Mackbook on 19/03/25.
//

import UIKit
import Firebase


// MARK: - Profile Viewer Controllers
// Modified UserProfileViewerController class to match ProfileViewController functionality
class UserProfileViewerController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let userId: String
    private let db = Firestore.firestore()
    private var registeredEvents: [EventModel] = []
    private var userInterests: [String] = []
    
    // UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let emailLabel = UILabel()
    private let friendsLabel = UILabel()
    private let segmentControl = UISegmentedControl(items: ["Details", "Events"])
    private let detailsStackView = UIStackView()
    private let descriptionLabel = UILabel()
    private let contactDetailsLabel = UILabel()
    private let githubLabel = UILabel()
    private let linkedinLabel = UILabel()
    private let techStackLabel = UILabel()
    private let interestsView = UIView()
    private let interestsLabel = UILabel()
    private let interestsGridView = UIStackView()
    private let eventsTableView = UITableView()
    
    init(userId: String) {
        self.userId = userId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        loadUserDetails()
        loadUserInterests()
        loadRegisteredEvents()
        fetchFriendsCount()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        title = "User Profile"
        view.backgroundColor = .white
        
        // Configure scrollView and contentView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Configure profileImageView
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 50
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor.white.cgColor
        profileImageView.backgroundColor = .lightGray
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileImageView)
        
        // Configure name label
        nameLabel.font = UIFont.boldSystemFont(ofSize: 22)
        nameLabel.textColor = .black
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        
        // Configure email label
        emailLabel.font = UIFont.systemFont(ofSize: 16)
        emailLabel.textColor = .gray
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(emailLabel)
        
        // Configure friends label
        friendsLabel.font = UIFont.systemFont(ofSize: 18)
        friendsLabel.textColor = .darkGray
        friendsLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(friendsLabel)
        
        // Configure segment control
        segmentControl.selectedSegmentIndex = 0
        segmentControl.selectedSegmentTintColor = UIColor.orange
        segmentControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(segmentControl)
        
        // Configure details stack view
        detailsStackView.axis = .vertical
        detailsStackView.distribution = .fill
        detailsStackView.spacing = 12
        detailsStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(detailsStackView)
        
        // Configure description label
        descriptionLabel.text = "Description: Loading..."
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textColor = .darkGray
        descriptionLabel.numberOfLines = 0
        detailsStackView.addArrangedSubview(descriptionLabel)
        
        // Configure contact details label
        contactDetailsLabel.text = "Contact: Loading..."
        contactDetailsLabel.font = UIFont.systemFont(ofSize: 16)
        contactDetailsLabel.textColor = .gray
        contactDetailsLabel.numberOfLines = 0
        detailsStackView.addArrangedSubview(contactDetailsLabel)
        
        // Configure github label
        githubLabel.text = "GitHub: Loading..."
        githubLabel.font = UIFont.systemFont(ofSize: 16)
        githubLabel.textColor = .gray
        githubLabel.numberOfLines = 0
        detailsStackView.addArrangedSubview(githubLabel)
        
        // Configure linkedin label
        linkedinLabel.text = "LinkedIn: Loading..."
        linkedinLabel.font = UIFont.systemFont(ofSize: 16)
        linkedinLabel.textColor = .gray
        linkedinLabel.numberOfLines = 0
        detailsStackView.addArrangedSubview(linkedinLabel)
        
        // Configure tech stack label
        techStackLabel.text = "Tech Stack: Loading..."
        techStackLabel.font = UIFont.systemFont(ofSize: 16)
        techStackLabel.textColor = .gray
        techStackLabel.numberOfLines = 0
        detailsStackView.addArrangedSubview(techStackLabel)
        
        // Configure interests view
        interestsView.translatesAutoresizingMaskIntoConstraints = false
        detailsStackView.addArrangedSubview(interestsView)
        
        // Configure interests label
        interestsLabel.text = "Interests"
        interestsLabel.font = UIFont.boldSystemFont(ofSize: 18)
        interestsLabel.textColor = .black
        interestsLabel.translatesAutoresizingMaskIntoConstraints = false
        interestsView.addSubview(interestsLabel)
        
        // Configure interests grid view
        interestsGridView.axis = .vertical
        interestsGridView.spacing = 16
        interestsGridView.distribution = .fillEqually
        interestsGridView.translatesAutoresizingMaskIntoConstraints = false
        interestsView.addSubview(interestsGridView)
        
        // Configure events table view
        eventsTableView.register(RegisteredEventCell.self, forCellReuseIdentifier: RegisteredEventCell.identifier)
        eventsTableView.delegate = self
        eventsTableView.dataSource = self
        eventsTableView.isHidden = true
        eventsTableView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(eventsTableView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),
            
            nameLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            emailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            emailLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            friendsLabel.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 4),
            friendsLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            friendsLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            segmentControl.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            segmentControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            segmentControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            detailsStackView.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 20),
            detailsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            detailsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            detailsStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20),
            
            interestsLabel.topAnchor.constraint(equalTo: interestsView.topAnchor),
            interestsLabel.leadingAnchor.constraint(equalTo: interestsView.leadingAnchor),
            
            interestsGridView.topAnchor.constraint(equalTo: interestsLabel.bottomAnchor, constant: 8),
            interestsGridView.leadingAnchor.constraint(equalTo: interestsView.leadingAnchor),
            interestsGridView.trailingAnchor.constraint(equalTo: interestsView.trailingAnchor),
            interestsGridView.bottomAnchor.constraint(equalTo: interestsView.bottomAnchor),
            
            eventsTableView.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 16),
            eventsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            eventsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            eventsTableView.heightAnchor.constraint(equalToConstant: 400),
            eventsTableView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Load User Details
    private func loadUserDetails() {
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching user details: \(error.localizedDescription)")
                return
            }
            
            guard let data = document?.data() else {
                print("No user data found for userId: \(userId)")
                return
            }
            
            self.nameLabel.text = data["name"] as? String ?? "Name"
            self.emailLabel.text = data["email"] as? String ?? "Email"
            self.contactDetailsLabel.text = "Contact: \(data["ContactDetails"] as? String ?? "Not Available")"
            self.descriptionLabel.text = "Description: \(data["Description"] as? String ?? "No Description Available")"
            self.githubLabel.text = "GitHub: \(data["githubUrl"] as? String ?? "Not Available")"
            self.linkedinLabel.text = "LinkedIn: \(data["linkedinUrl"] as? String ?? "Not Available")"
            self.techStackLabel.text = "Tech Stack: \(data["techStack"] as? String ?? "Not Available")"
            
            if let profileImageURLString = data["profileImageURL"] as? String,
               let profileImageURL = URL(string: profileImageURLString) {
                self.loadProfileImage(from: profileImageURL)
            } else {
                self.profileImageView.image = UIImage(named: "default_profile")
            }
        }
    }
    
    // MARK: - Load User Interests
    private func loadUserInterests() {
        db.collection("Interest").document(userId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching user interests: \(error.localizedDescription)")
                return
            }
            
            guard let data = document?.data(), let interests = data["interests"] as? [String] else {
                print("No interests data found.")
                return
            }
            
            self.userInterests = interests
            self.updateInterestsUI()
        }
    }
    
    private func updateInterestsUI() {
        interestsGridView.arrangedSubviews.forEach { $0.removeFromSuperview() } // Clear existing views
        
        let columns = 2
        var currentRowStack: UIStackView?
        
        for (index, interest) in userInterests.enumerated() {
            if index % columns == 0 {
                currentRowStack = UIStackView()
                currentRowStack?.axis = .horizontal
                currentRowStack?.spacing = 12
                currentRowStack?.distribution = .fillEqually
                interestsGridView.addArrangedSubview(currentRowStack!)
            }
            
            let button = UIButton(type: .system)
            button.setTitle(interest, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            button.backgroundColor = UIColor.systemGray5
            button.layer.cornerRadius = 8
            button.clipsToBounds = true
            
            currentRowStack?.addArrangedSubview(button)
        }
        
        interestsView.isHidden = false
    }
    
    // MARK: - Load Profile Image
    private func loadProfileImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Error downloading profile image: \(error.localizedDescription)")
                return
            }
            
            guard
                let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode),
                let data = data,
                let image = UIImage(data: data)
            else {
                print("Invalid response or image data.")
                return
            }
            
            DispatchQueue.main.async {
                self?.profileImageView.image = image
            }
        }.resume()
    }
    
    // MARK: - Load Registered Events
    private func loadRegisteredEvents() {
        db.collection("registrations").whereField("uid", isEqualTo: userId).getDocuments { [weak self] querySnapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching registrations: \(error.localizedDescription)")
                return
            }
            
            let eventIds = querySnapshot?.documents.compactMap { $0.data()["eventId"] as? String } ?? []
            if eventIds.isEmpty {
                print("No registered events found.")
            } else {
                self.fetchEvents(for: eventIds)
            }
        }
    }
    
    private func fetchEvents(for eventIds: [String]) {
        let group = DispatchGroup()
        registeredEvents.removeAll()
        
        for eventId in eventIds {
            group.enter()
            db.collection("events").document(eventId).getDocument { [weak self] document, error in
                defer { group.leave() }
                
                if let error = error {
                    print("Error fetching event details for \(eventId): \(error.localizedDescription)")
                    return
                }
                
                guard let data = document?.data(), let self = self else {
                    print("No data found for eventId: \(eventId)")
                    return
                }
                
                let imageNameOrUrl = data["imageName"] as? String ?? ""
                let isImageUrl = URL(string: imageNameOrUrl)?.scheme != nil
                
                let event = EventModel(
                    eventId: eventId,
                    title: data["title"] as? String ?? "Untitled",
                    category: data["category"] as? String ?? "Uncategorized",
                    attendanceCount: data["attendanceCount"] as? Int ?? 0,
                    organizerName: data["organizerName"] as? String ?? "Unknown",
                    date: data["date"] as? String ?? "Unknown Date",
                    time: data["time"] as? String ?? "Unknown Time",
                    location: data["location"] as? String ?? "Unknown Location",
                    locationDetails: data["locationDetails"] as? String ?? "",
                    imageName: isImageUrl ? imageNameOrUrl : "",
                    speakers: [],
                    userId: data["userId"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    latitude: data["latitude"] as? Double,
                    longitude: data["longitude"] as? Double,
                    tags: []
                )
                self.registeredEvents.append(event)
            }
        }
        
        group.notify(queue: .main) {
            self.eventsTableView.reloadData()
        }
    }
    
    // MARK: - Fetch Friends Count
    private func fetchFriendsCount() {
        db.collection("friends")
            .whereField("userID", isEqualTo: userId)
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching friends count: \(error.localizedDescription)")
                    return
                }
                
                let count = snapshot?.documents.count ?? 0
                DispatchQueue.main.async {
                    self.friendsLabel.text = "Friends: \(count)"
                }
            }
    }
    
    // MARK: - UITableView DataSource & Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return registeredEvents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RegisteredEventCell.identifier, for: indexPath) as! RegisteredEventCell
        cell.configure(with: registeredEvents[indexPath.row])
        cell.delegate = nil // Don't allow unregistering from another user's profile
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Display event details but don't allow actions
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Actions
    @objc private func segmentChanged() {
        let isShowingEvents = segmentControl.selectedSegmentIndex == 1
        detailsStackView.isHidden = isShowingEvents
        eventsTableView.isHidden = !isShowingEvents
        
        if isShowingEvents {
            loadRegisteredEvents()
        }
    }
}

