import UIKit
import FirebaseFirestore


class RegistrationListTabViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    
    // MARK: - Properties
    private var registrations: [[String: Any]] = []
    private var filteredRegistrations: [[String: Any]] = []
    private var eventDetails: [String: Any]?
    private let eventId: String
    private let db = Firestore.firestore()
    private let refreshControl = UIRefreshControl()
    private let searchController = UISearchController(searchResultsController: nil)
    private var userProfileImages: [String: String] = [:] // Cache for user profile image URLs
    
    // MARK: - UI Components
    private let headerContentView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let eventImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 25
        imageView.backgroundColor = UIColor(red: 0.95, green: 0.61, blue: 0.07, alpha: 0.1)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let eventNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = .black
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let eventDateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let totalRegistrationsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.textColor = UIColor(red: 0.95, green: 0.61, blue: 0.07, alpha: 1.0)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let registrationsTextLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.text = "Registrations"
        label.textColor = UIColor.darkGray
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let registrationsTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(RegistrationTabCell.self, forCellReuseIdentifier: RegistrationTabCell.identifier)
        tableView.rowHeight = 80
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1.0)
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private let emptyStateView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let emptyStateImageView: UIImageView = {
        let imageView = UIImageView()
        if #available(iOS 13.0, *) {
            imageView.image = UIImage(systemName: "person.fill.questionmark")
        } else {
            imageView.image = UIImage(named: "person.fill.questionmark")
        }
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.lightGray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.text = "No registrations found"
        label.textColor = UIColor.darkGray
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let floatingActionButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(red: 0.95, green: 0.61, blue: 0.07, alpha: 1.0)
        
        if #available(iOS 13.0, *) {
            button.setImage(UIImage(systemName: "arrow.down.doc.fill"), for: .normal)
        } else {
            button.setImage(UIImage(named: "download"), for: .normal)
        }
        
        button.tintColor = .white
        button.layer.cornerRadius = 28
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .gray)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Initializer
    init(eventId: String) {
        self.eventId = eventId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        setupSearchController()
        setupConstraints()
        setupRefreshControl()
        setupActions()
        fetchEventDetails()
    }
    
    // MARK: - Setup UI
    private func setupNavigationBar() {
        title = "Registrations"
        navigationController?.navigationBar.barTintColor = .white
        navigationController?.navigationBar.tintColor = UIColor(red: 0.95, green: 0.61, blue: 0.07, alpha: 1.0)
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.black]
        
        let sortButton = UIBarButtonItem(image: UIImage(named: "sort") ?? UIImage(), style: .plain, target: self, action: #selector(showSortOptions))
        navigationItem.rightBarButtonItem = sortButton
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1.0)
        
        // Add components to view hierarchy
        view.addSubview(headerContentView)
        
        headerContentView.addSubview(eventImageView)
        headerContentView.addSubview(eventNameLabel)
        headerContentView.addSubview(eventDateLabel)
        
        view.addSubview(statsContainerView)
        statsContainerView.addSubview(totalRegistrationsLabel)
        statsContainerView.addSubview(registrationsTextLabel)
        
        view.addSubview(registrationsTableView)
        registrationsTableView.delegate = self
        registrationsTableView.dataSource = self
        
        view.addSubview(emptyStateView)
        emptyStateView.addSubview(emptyStateImageView)
        emptyStateView.addSubview(emptyStateLabel)
        
        view.addSubview(floatingActionButton)
        view.addSubview(activityIndicator)
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search by name or reg number..."
        searchController.searchBar.tintColor = UIColor(red: 0.95, green: 0.61, blue: 0.07, alpha: 1.0)
        searchController.searchBar.delegate = self
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
    
    private func setupRefreshControl() {
        refreshControl.tintColor = UIColor(red: 0.95, green: 0.61, blue: 0.07, alpha: 1.0)
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refreshRegistrations), for: .valueChanged)
        registrationsTableView.refreshControl = refreshControl
    }
    
    private func setupActions() {
        floatingActionButton.addTarget(self, action: #selector(showExportOptions), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Header content view
            headerContentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            headerContentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerContentView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            headerContentView.heightAnchor.constraint(equalToConstant: 90),
            
            // Event image view
            eventImageView.leadingAnchor.constraint(equalTo: headerContentView.leadingAnchor, constant: 16),
            eventImageView.centerYAnchor.constraint(equalTo: headerContentView.centerYAnchor),
            eventImageView.widthAnchor.constraint(equalToConstant: 50),
            eventImageView.heightAnchor.constraint(equalToConstant: 50),
            
            // Event name and date
            eventNameLabel.topAnchor.constraint(equalTo: headerContentView.topAnchor, constant: 16),
            eventNameLabel.leadingAnchor.constraint(equalTo: eventImageView.trailingAnchor, constant: 16),
            eventNameLabel.trailingAnchor.constraint(equalTo: headerContentView.trailingAnchor, constant: -16),
            
            eventDateLabel.topAnchor.constraint(equalTo: eventNameLabel.bottomAnchor, constant: 4),
            eventDateLabel.leadingAnchor.constraint(equalTo: eventImageView.trailingAnchor, constant: 16),
            eventDateLabel.trailingAnchor.constraint(equalTo: headerContentView.trailingAnchor, constant: -16),
            eventDateLabel.bottomAnchor.constraint(lessThanOrEqualTo: headerContentView.bottomAnchor, constant: -16),
            
            // Stats container
            statsContainerView.topAnchor.constraint(equalTo: headerContentView.bottomAnchor, constant: 16),
            statsContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statsContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            statsContainerView.heightAnchor.constraint(equalToConstant: 90),
            
            totalRegistrationsLabel.centerXAnchor.constraint(equalTo: statsContainerView.centerXAnchor),
            totalRegistrationsLabel.topAnchor.constraint(equalTo: statsContainerView.topAnchor, constant: 12),
            
            registrationsTextLabel.centerXAnchor.constraint(equalTo: statsContainerView.centerXAnchor),
            registrationsTextLabel.topAnchor.constraint(equalTo: totalRegistrationsLabel.bottomAnchor, constant: 4),
            registrationsTextLabel.bottomAnchor.constraint(lessThanOrEqualTo: statsContainerView.bottomAnchor, constant: -12),
            
            // Table view
            registrationsTableView.topAnchor.constraint(equalTo: statsContainerView.bottomAnchor, constant: 16),
            registrationsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            registrationsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            registrationsTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Empty state view
            emptyStateView.centerXAnchor.constraint(equalTo: registrationsTableView.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: registrationsTableView.centerYAnchor),
            emptyStateView.widthAnchor.constraint(equalToConstant: 240),
            emptyStateView.heightAnchor.constraint(equalToConstant: 240),
            
            emptyStateImageView.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateImageView.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 100),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 100),
            
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor, constant: 20),
            emptyStateLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            
            // Floating action button
            floatingActionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            floatingActionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            floatingActionButton.widthAnchor.constraint(equalToConstant: 56),
            floatingActionButton.heightAnchor.constraint(equalToConstant: 56),
            
            // Activity indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Data Handling
    @objc private func refreshRegistrations() {
        fetchEventDetails()
    }
    
    private func fetchEventDetails() {
        activityIndicator.startAnimating()
        
        // Fetch event details from Firestore
        db.collection("events").document(eventId).getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching event details: \(error.localizedDescription)")
                self.activityIndicator.stopAnimating()
                self.refreshControl.endRefreshing()
                self.showAlert(title: "Error", message: "Failed to load event details.")
                return
            }
            
            if let document = document, document.exists {
                self.eventDetails = document.data()
                
                // Update UI with event details
                self.updateEventDetails()
                
                // Now that we have the event details, fetch registrations
                self.fetchRegistrations()
            } else {
                self.activityIndicator.stopAnimating()
                self.refreshControl.endRefreshing()
                self.showAlert(title: "Error", message: "Event details not found.")
            }
        }
    }
    
    // In the updateEventDetails() method
    private func updateEventDetails() {
        guard let eventDetails = eventDetails else { return }
        
        // Update event name
        if let eventName = eventDetails["title"] as? String {
            eventNameLabel.text = eventName
        } else {
            eventNameLabel.text = "Event Details"
        }
        
        // Update event date - now handling string format "10 January 2025"
        if let eventDateString = eventDetails["date"] as? String {
            eventDateLabel.text = eventDateString
        } else if let eventDate = eventDetails["date"] as? Timestamp {
            // Fallback for Timestamp format if used
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "d MMMM yyyy"
            eventDateLabel.text = dateFormatter.string(from: eventDate.dateValue())
        } else {
            eventDateLabel.text = "Date not available"
        }
        
        // Load event image
        if let imageURLString = eventDetails["imageName"] as? String, let imageURL = URL(string: imageURLString) {
            loadEventImage(from: imageURL)
        }
    }
    
    private func loadEventImage(from url: URL) {
        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let self = self,
                  let imageData = data,
                  error == nil,
                  let image = UIImage(data: imageData) else {
                return
            }
            
            DispatchQueue.main.async {
                self.eventImageView.image = image
            }
        }
        task.resume()
    }
    
    private func fetchRegistrations() {
        db.collection("registrations")
            .whereField("eventId", isEqualTo: eventId)
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching registrations: \(error.localizedDescription)")
                    self.activityIndicator.stopAnimating()
                    self.refreshControl.endRefreshing()
                    self.showAlert(title: "Error", message: "Failed to load registrations.")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No registrations found for event \(self.eventId)")
                    self.registrations = []
                    self.updateUI()
                    self.activityIndicator.stopAnimating()
                    self.refreshControl.endRefreshing()
                    return
                }
                
                self.registrations = documents.map { $0.data() }
                self.filteredRegistrations = self.registrations
                
                // Fetch user profile images
                self.fetchUserProfileImages {
                    self.activityIndicator.stopAnimating()
                    self.refreshControl.endRefreshing()
                    self.updateUI()
                }
            }
    }
    
    private func fetchUserProfileImages(completion: @escaping () -> Void) {
        let dispatchGroup = DispatchGroup()
        
        for registration in registrations {
            // Check if the registration has a userId field
            if let userId = registration["uid"] as? String {
                dispatchGroup.enter()
                
                // Fetch user data from Firestore
                db.collection("users").document(userId).getDocument { [weak self] (document, error) in
                    guard let self = self else {
                        dispatchGroup.leave()
                        return
                    }
                    
                    if let document = document, document.exists {
                        if let profileImageURL = document.data()?["profileImageURL"] as? String {
                            self.userProfileImages[userId] = profileImageURL
                        }
                    }
                    
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion()
        }
    }
    
    private func updateUI() {
        let count = filteredRegistrations.count
        totalRegistrationsLabel.text = "\(count)"
        
        // Show/hide empty state
        emptyStateView.isHidden = count > 0
        
        // Update floatingActionButton state
        floatingActionButton.isEnabled = count > 0
        floatingActionButton.alpha = count > 0 ? 1.0 : 0.6
        
        registrationsTableView.reloadData()
    }
    
    // MARK: - Search & Filtering
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.lowercased(), !searchText.isEmpty else {
            filteredRegistrations = registrations
            updateUI()
            return
        }
        
        filteredRegistrations = registrations.filter { registration in
            let name = (registration["Name"] as? String ?? "").lowercased()
            let regNumber = (registration["Registration No."] as? String ?? "").lowercased()
            
            return name.contains(searchText) || regNumber.contains(searchText)
        }
        
        updateUI()
    }
    
    // MARK: - Sorting & Export
    @objc private func showSortOptions() {
        let alertController = UIAlertController(title: "Sort Registrations", message: nil, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "Name (A-Z)", style: .default) { _ in
            self.sortRegistrations(by: "Name", ascending: true)
        })
        
        alertController.addAction(UIAlertAction(title: "Name (Z-A)", style: .default) { _ in
            self.sortRegistrations(by: "Name", ascending: false)
        })
        
        alertController.addAction(UIAlertAction(title: "Registration No. (Ascending)", style: .default) { _ in
            self.sortRegistrations(by: "Registration No.", ascending: true)
        })
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(alertController, animated: true)
    }
    
    private func sortRegistrations(by field: String, ascending: Bool) {
        filteredRegistrations.sort { registration1, registration2 in
            let value1 = registration1[field] as? String ?? ""
            let value2 = registration2[field] as? String ?? ""
            
            return ascending ? value1 < value2 : value1 > value2
        }
        
        registrationsTableView.reloadData()
    }
    
    @objc private func showExportOptions() {
        let alertController = UIAlertController(
            title: "Export Options",
            message: "Choose export format and content",
            preferredStyle: .actionSheet
        )
        
        alertController.addAction(UIAlertAction(title: "Basic CSV (Name, Email, Reg Number)", style: .default) { _ in
            self.exportCSV(detailed: false)
        })
        
        alertController.addAction(UIAlertAction(title: "Detailed CSV (All Fields)", style: .default) { _ in
            self.exportCSV(detailed: true)
        })
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = floatingActionButton
            popoverController.sourceRect = floatingActionButton.bounds
        }
        
        present(alertController, animated: true)
    }
    
    private func exportCSV(detailed: Bool) {
        let eventName = (eventDetails?["name"] as? String ?? "event").replacingOccurrences(of: " ", with: "_")
        let fileName = "\(eventName)_registrations_\(Date().timeIntervalSince1970).csv"
        
        let csvData = detailed ? generateDetailedCSVData() : generateBasicCSVData()
        
        let fileManager = FileManager.default
        let tempURL = fileManager.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csvData.write(to: tempURL, atomically: true, encoding: .utf8)
            
            let activityViewController = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            
            if let popoverPresentationController = activityViewController.popoverPresentationController {
                popoverPresentationController.sourceView = floatingActionButton
                popoverPresentationController.sourceRect = floatingActionButton.bounds
            }
            
            present(activityViewController, animated: true)
        } catch {
            print("Error writing CSV file: \(error.localizedDescription)")
            showAlert(title: "Export Error", message: "Failed to create CSV file")
        }
    }
    
    private func generateBasicCSVData() -> String {
        var csvString = "S.No,Name,Email,Registration No.\n"
        
        for (index, registration) in registrations.enumerated() {
            let serialNumber = index + 1
            let name = registration["Name"] as? String ?? "N/A"
            let email = registration["email"] as? String ?? "N/A"
            let regNo = registration["Registration No."] as? String ?? "N/A"
            
            // Sanitize fields for CSV format
            let sanitizedName = name.replacingOccurrences(of: "\"", with: "\"\"")
            let sanitizedEmail = email.replacingOccurrences(of: "\"", with: "\"\"")
            let sanitizedRegNo = regNo.replacingOccurrences(of: "\"", with: "\"\"")
            
            csvString += "\(serialNumber),\"\(sanitizedName)\",\"\(sanitizedEmail)\",\"\(sanitizedRegNo)\"\n"
        }
        
        return csvString
    }
    
    private func generateDetailedCSVData() -> String {
        // Get all possible keys from the registrations
        let possibleKeys = ["Name", "email", "Year of Study", "College Email ID", "Contact Number",
                            "Course", "Department", "FA Number", "Faculty Advisor", "Personal Email ID",
                            "Registration No.", "Section", "Specialization"]
        
        // Create header row with event information
        let eventName = eventDetails?["name"] as? String ?? "Event"
        let currentDate = "2025-04-07 05:18:28" // Current date from your provided value
        var csvString = "# \(eventName) - Registration Export\n"
        csvString += "# Generated on: \(currentDate)\n"
        csvString += "# Total Registrations: \(registrations.count)\n\n"
        csvString += "# Generated by: ssanidhya0407\n\n" // Current user login from your provided value
        
        // Add column headers
        csvString += "S.No," + possibleKeys.map { "\"\($0)\"" }.joined(separator: ",") + "\n"
        
        // Add data rows
        for (index, registration) in registrations.enumerated() {
            let serialNumber = index + 1
            csvString += "\(serialNumber),"
            
            for key in possibleKeys {
                let value = registration[key] as? String ?? "N/A"
                let sanitizedValue = value.replacingOccurrences(of: "\"", with: "\"\"")
                csvString += "\"\(sanitizedValue)\","
            }
            
            // Remove trailing comma and add newline
            csvString = String(csvString.dropLast()) + "\n"
        }
        
        return csvString
    }
    
    // MARK: - UITableView DataSource & Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredRegistrations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RegistrationTabCell.identifier, for: indexPath) as! RegistrationTabCell
        let registration = filteredRegistrations[indexPath.row]
        
        // Get profile image URL if available
        var profileImageURL: String? = nil
        if let userId = registration["uid"] as? String {
            profileImageURL = userProfileImages[userId]
        }
        
        cell.configure(with: registration, index: indexPath.row, profileImageURL: profileImageURL)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Show detail view when a row is selected
        let registration = filteredRegistrations[indexPath.row]
        let profileImageURL = registration["uid"] as? String != nil ?
                              userProfileImages[registration["uid"] as! String] : nil
                              
        let detailVC = RegistrationDetailViewController(registration: registration,
                                                       index: indexPath.row,
                                                       profileImageURL: profileImageURL)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }
}

// MARK: - RegistrationTabCell
class RegistrationTabCell: UITableViewCell {
    
    static let identifier = "RegistrationTabCell"
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor(red: 0.95, green: 0.61, blue: 0.07, alpha: 0.1)
        imageView.layer.cornerRadius = 25
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let initialsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = UIColor(red: 0.95, green: 0.61, blue: 0.07, alpha: 1.0)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let regNumberLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let accessoryImageView: UIImageView = {
        let imageView = UIImageView()
        if #available(iOS 13.0, *) {
            imageView.image = UIImage(systemName: "chevron.right")
        } else {
            imageView.image = UIImage(named: "chevron.right")
        }
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.lightGray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // MARK: - Initializers
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        contentView.addSubview(containerView)
        
        containerView.addSubview(profileImageView)
        profileImageView.addSubview(initialsLabel)
        
        containerView.addSubview(nameLabel)
        containerView.addSubview(regNumberLabel)
        containerView.addSubview(accessoryImageView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            profileImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 50),
            profileImageView.heightAnchor.constraint(equalToConstant: 50),
            
            initialsLabel.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: accessoryImageView.leadingAnchor, constant: -8),
            
            regNumberLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            regNumberLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            regNumberLabel.trailingAnchor.constraint(equalTo: accessoryImageView.leadingAnchor, constant: -8),
            regNumberLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -16),
            
            accessoryImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            accessoryImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            accessoryImageView.widthAnchor.constraint(equalToConstant: 14),
            accessoryImageView.heightAnchor.constraint(equalToConstant: 14),
        ])
    }
    
    // MARK: - Configure Cell
    func configure(with registration: [String: Any], index: Int, profileImageURL: String?) {
        // Get data from registration
        let fullName = registration["Name"] as? String ?? "N/A"
        let regNumber = registration["Registration No."] as? String ?? "N/A"
        
        // Set labels
        nameLabel.text = fullName
        regNumberLabel.text = regNumber
        
        // If we have a profile image URL, load the image
        if let profileURL = profileImageURL, let url = URL(string: profileURL) {
            initialsLabel.isHidden = true
            loadImage(from: url)
        } else {
            // Otherwise use initials
            initialsLabel.isHidden = false
            
            // Create initials from name
            let components = fullName.components(separatedBy: " ")
            var initials = ""
            if components.count > 0 {
                if let first = components.first?.prefix(1) {
                    initials += String(first)
                }
                if components.count > 1, let last = components.last?.prefix(1) {
                    initials += String(last)
                } else if let first = components.first?.prefix(2) {
                    initials = String(first)
                }
            }
            initialsLabel.text = initials.uppercased()
        }
    }
    
    private func loadImage(from url: URL) {
        // Create a URLSession task to fetch the image
        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let self = self,
                  let imageData = data,
                  error == nil,
                  let image = UIImage(data: imageData) else {
                return
            }
            
            // Update UI on the main thread
            DispatchQueue.main.async {
                self.profileImageView.image = image
            }
        }
        task.resume()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        profileImageView.image = nil
        initialsLabel.isHidden = false
    }
}
