//
//  OrganizerProfileViewerController.swift
//  ThriveUp
//
//  Created by Yash's Mackbook on 19/03/25.
//

import UIKit
import Firebase



class OrganizerProfileViewerController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let organizerId: String
    private let db = Firestore.firestore()
    private var createdEvents: [EventModel] = []
    
    // UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let emailLabel = UILabel()
    private let segmentControl = UISegmentedControl(items: ["Details", "Events"])
    private let aboutLabel = UILabel()
    private let aboutDescriptionLabel = UILabel()
    private let detailsStackView = UIStackView()
    private let eventsTableView = UITableView()
    
    init(organizerId: String) {
        self.organizerId = organizerId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        fetchOrganizerData()
        fetchCreatedEvents()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        title = "Organizer Profile"
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
        profileImageView.layer.borderWidth = 3
        profileImageView.layer.borderColor = UIColor.systemOrange.cgColor
        profileImageView.backgroundColor = .lightGray
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileImageView)
        
        // Configure name label
        nameLabel.font = UIFont.boldSystemFont(ofSize: 24)
        nameLabel.textColor = .black
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        
        // Configure email label
        emailLabel.font = UIFont.systemFont(ofSize: 16)
        emailLabel.textColor = .gray
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(emailLabel)
        
        // Configure segment control
        segmentControl.selectedSegmentIndex = 0
        segmentControl.selectedSegmentTintColor = UIColor.orange
        segmentControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(segmentControl)
        
        // Configure about label
        aboutLabel.text = "About"
        aboutLabel.font = UIFont.boldSystemFont(ofSize: 20)
        aboutLabel.textColor = .black
        aboutLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(aboutLabel)
        
        // Configure about description label
        aboutDescriptionLabel.text = "Loading description..."
        aboutDescriptionLabel.font = UIFont.systemFont(ofSize: 16)
        aboutDescriptionLabel.textColor = .darkGray
        aboutDescriptionLabel.numberOfLines = 0
        aboutDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(aboutDescriptionLabel)
        
        // Configure details stack view
        detailsStackView.axis = .vertical
        detailsStackView.distribution = .fillEqually
        detailsStackView.spacing = 16
        detailsStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(detailsStackView)
        
        // Add detail views
        let eventsCountView = createDetailView(title: "Number of Events", value: "Loading...")
        let contactView = createDetailView(title: "Contact", value: "Loading...")
        let pocView = createDetailView(title: "Person of Contact", value: "Loading...")
        [eventsCountView, contactView, pocView].forEach { detailsStackView.addArrangedSubview($0) }
        
        // Configure events table view
        eventsTableView.register(EventTableViewCell.self, forCellReuseIdentifier: EventTableViewCell.identifier)
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
            
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),
            
            nameLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            emailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            emailLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            segmentControl.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            segmentControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            segmentControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            aboutLabel.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 20),
            aboutLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            aboutDescriptionLabel.topAnchor.constraint(equalTo: aboutLabel.bottomAnchor, constant: 8),
            aboutDescriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            aboutDescriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            detailsStackView.topAnchor.constraint(equalTo: aboutDescriptionLabel.bottomAnchor, constant: 20),
            detailsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            detailsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            detailsStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20),
            
            eventsTableView.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 16),
            eventsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            eventsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            eventsTableView.heightAnchor.constraint(equalToConstant: 400),
            eventsTableView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20)
        ])
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
    
    // MARK: - Load Organizer Data
    private func fetchOrganizerData() {
        db.collection("users").document(organizerId).getDocument { [weak self] document, error in
            guard let self = self, let data = document?.data(), error == nil else { return }
            
            self.nameLabel.text = data["name"] as? String ?? "Organizer Name"
            self.emailLabel.text = data["email"] as? String ?? "Email"
            self.aboutDescriptionLabel.text = data["Description"] as? String ?? "No description provided."
            
            if let contact = data["ContactDetails"] as? String,
               let contactLabel = self.detailsStackView.arrangedSubviews[1].subviews.last as? UILabel {
                contactLabel.text = contact
            }
            
            if let poc = data["POC"] as? String,
               let pocLabel = self.detailsStackView.arrangedSubviews[2].subviews.last as? UILabel {
                pocLabel.text = poc
            }
            
            if let profileImageURLString = data["profileImageURL"] as? String,
               let profileImageURL = URL(string: profileImageURLString) {
                self.loadProfileImage(from: profileImageURL)
            }
        }
    }
    
    private func loadProfileImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.profileImageView.image = image
            }
        }.resume()
    }
    
    // MARK: - Fetch Created Events
    private func fetchCreatedEvents() {
        db.collection("events").whereField("userId", isEqualTo: organizerId)
            .whereField("status", isEqualTo: "accepted")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents, error == nil else { return }
                
                self.createdEvents = documents.map { doc in
                    let data = doc.data()
                    
                    // Handle speakers conversion from Firestore data to Speaker objects
                    var speakersArray: [Speaker] = []
                    if let speakersData = data["speakers"] as? [[String: Any]] {
                        speakersArray = speakersData.compactMap { speakerData in
                            // Convert each dictionary to a Speaker object
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
                        speakers: speakersArray,
                        userId: self.organizerId,
                        description: data["description"] as? String ?? "",
                        tags: data["tags"] as? [String] ?? [String]()
                    )
                }
                
                // Update events count in the details section
                if let eventsCountLabel = self.detailsStackView.arrangedSubviews[0].subviews.last as? UILabel {
                    eventsCountLabel.text = "\(self.createdEvents.count)"
                }
                
                DispatchQueue.main.async {
                    self.eventsTableView.reloadData()
                }
            }
    }
    
    // MARK: - UITableView DataSource & Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return createdEvents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: EventTableViewCell.identifier, for: indexPath) as! EventTableViewCell
        cell.configure(with: createdEvents[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Show event details but don't navigate to registration list
        tableView.deselectRow(at: indexPath, animated: true)
        
        // You could implement showing event details here if needed
    }
    
    // MARK: - Actions
    @objc private func segmentChanged() {
        let isEventsSelected = segmentControl.selectedSegmentIndex == 1
        aboutLabel.isHidden = isEventsSelected
        aboutDescriptionLabel.isHidden = isEventsSelected
        detailsStackView.isHidden = isEventsSelected
        eventsTableView.isHidden = !isEventsSelected
        
        if isEventsSelected && createdEvents.isEmpty {
            fetchCreatedEvents()
        }
    }
}

