//import UIKit
//import FirebaseFirestore
//
//class RegistrationListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UISearchBarDelegate {
//    
//    // MARK: - Properties
//    private var registrations: [[String: Any]] = [] // Holds all fetched registrations data
//    private var filteredRegistrations: [[String: Any]] = [] // Holds filtered registrations data
//    private let eventId: String
//    private let db = Firestore.firestore()
//    private let refreshControl = UIRefreshControl()
//    private let searchController = UISearchController(searchResultsController: nil)
//    
//    // MARK: - UI Components
//    private let headerView: UIView = {
//        let view = UIView()
//        view.backgroundColor = UIColor(red: 0.95, green: 0.61, blue: 0.07, alpha: 1.0) // Orange
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
//    
//    private let eventNameLabel: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
//        label.textColor = .white
//        label.textAlignment = .center
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//    
//    private let registrationsCountView: UIView = {
//        let view = UIView()
//        view.backgroundColor = .white
//        view.layer.cornerRadius = 12
//        view.layer.shadowColor = UIColor.black.cgColor
//        view.layer.shadowOpacity = 0.1
//        view.layer.shadowOffset = CGSize(width: 0, height: 2)
//        view.layer.shadowRadius = 4
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
//    
//    private let countIconImageView: UIImageView = {
//        let imageView = UIImageView()
//        if #available(iOS 13.0, *) {
//            imageView.image = UIImage(systemName: "person.3.fill")
//        } else {
//            imageView.image = UIImage(named: "person.3.fill")
//        }
//        imageView.contentMode = .scaleAspectFit
//        imageView.tintColor = UIColor(red: 0.95, green: 0.61, blue: 0.07, alpha: 1.0) // Orange
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        return imageView
//    }()
//    
//    private let totalCountLabel: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
//        label.textColor = UIColor(red: 0.95, green: 0.61, blue: 0.07, alpha: 1.0) // Orange
//        label.textAlignment = .center
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//    
//    private let totalCountDescriptionLabel: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
//        label.text = "Registrations"
//        label.textColor = UIColor.darkGray
//        label.textAlignment = .center
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//    
//    private let registrationsTableView: UITableView = {
//        let tableView = UITableView()
//        tableView.register(RegistrationTableViewCell.self, forCellReuseIdentifier: RegistrationTableViewCell.identifier)
//        tableView.rowHeight = UITableView.automaticDimension
//        tableView.estimatedRowHeight = 200
//        tableView.separatorStyle = .none
//        tableView.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1.0) // Light background
//        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
//        tableView.translatesAutoresizingMaskIntoConstraints = false
//        return tableView
//    }()
//    
//    private let emptyStateView: UIView = {
//        let view = UIView()
//        view.isHidden = true
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
//    
//    private let emptyStateImageView: UIImageView = {
//        let imageView = UIImageView()
//        if #available(iOS 13.0, *) {
//            imageView.image = UIImage(systemName: "person.fill.questionmark")
//        } else {
//            imageView.image = UIImage(named: "person.fill.questionmark")
//        }
//        imageView.contentMode = .scaleAspectFit
//        imageView.tintColor = UIColor.lightGray
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        return imageView
//    }()
//    
//    private let emptyStateLabel: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
//        label.text = "No registrations found"
//        label.textColor = UIColor.darkGray
//        label.textAlignment = .center
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//    
//    private let downloadButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("Export to CSV", for: .normal)
//        button.backgroundColor = UIColor(red: 0.95, green: 0.61, blue: 0.07, alpha: 1.0) // Orange
//        button.setTitleColor(.white, for: .normal)
//        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
//        button.layer.cornerRadius = 25
//        button.layer.shadowColor = UIColor.black.cgColor
//        button.layer.shadowOpacity = 0.2
//        button.layer.shadowOffset = CGSize(width: 0, height: 2)
//        button.layer.shadowRadius = 4
//        button.translatesAutoresizingMaskIntoConstraints = false
//        return button
//    }()
//    
//    // MARK: - Activity Indicator
//    private let activityIndicator: UIActivityIndicatorView = {
//        let indicator = UIActivityIndicatorView(style: .gray)
//        indicator.hidesWhenStopped = true
//        indicator.translatesAutoresizingMaskIntoConstraints = false
//        return indicator
//    }()
//    
//    // MARK: - Initializer
//    init(eventId: String, eventName: String = "Event Registrations") {
//        self.eventId = eventId
//        super.init(nibName: nil, bundle: nil)
//        self.eventNameLabel.text = eventName
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    // MARK: - Lifecycle
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        setupSearchController()
//        setupConstraints()
//        setupRefreshControl()
//        fetchRegistrations()
//    }
//    
//    // MARK: - Setup UI
//    private func setupUI() {
//        title = "Registrations"
//        view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1.0) // Light background
//        
//        // Add components to view hierarchy
//        view.addSubview(headerView)
//        headerView.addSubview(eventNameLabel)
//        
//        view.addSubview(registrationsCountView)
//        registrationsCountView.addSubview(countIconImageView)
//        registrationsCountView.addSubview(totalCountLabel)
//        registrationsCountView.addSubview(totalCountDescriptionLabel)
//        
//        view.addSubview(registrationsTableView)
//        registrationsTableView.delegate = self
//        registrationsTableView.dataSource = self
//        
//        view.addSubview(emptyStateView)
//        emptyStateView.addSubview(emptyStateImageView)
//        emptyStateView.addSubview(emptyStateLabel)
//        
//        view.addSubview(downloadButton)
//        view.addSubview(activityIndicator)
//        
//        // Setup download button action
//        downloadButton.addTarget(self, action: #selector(handleDownload), for: .touchUpInside)
//    }
//    
//    private func setupSearchController() {
//        searchController.searchResultsUpdater = self
//        searchController.obscuresBackgroundDuringPresentation = false
//        searchController.searchBar.placeholder = "Search by name, email, or registration number"
//        searchController.searchBar.tintColor = UIColor(red: 0.95, green: 0.61, blue: 0.07, alpha: 1.0) // Orange
//        searchController.searchBar.delegate = self
//        
//        navigationItem.searchController = searchController
//        navigationItem.hidesSearchBarWhenScrolling = false
//        definesPresentationContext = true
//    }
//    
//    private func setupRefreshControl() {
//        refreshControl.tintColor = UIColor(red: 0.95, green: 0.61, blue: 0.07, alpha: 1.0) // Orange
//        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
//        refreshControl.addTarget(self, action: #selector(refreshRegistrations), for: .valueChanged)
//        registrationsTableView.refreshControl = refreshControl
//    }
//    
//    private func setupConstraints() {
//        NSLayoutConstraint.activate([
//            // Header view
//            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            headerView.heightAnchor.constraint(equalToConstant: 44),
//            
//            eventNameLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
//            eventNameLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
//            eventNameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
//            
//            // Count view
//            registrationsCountView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
//            registrationsCountView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            registrationsCountView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//            registrationsCountView.heightAnchor.constraint(equalToConstant: 100),
//            
//            countIconImageView.topAnchor.constraint(equalTo: registrationsCountView.topAnchor, constant: 16),
//            countIconImageView.centerXAnchor.constraint(equalTo: registrationsCountView.centerXAnchor),
//            countIconImageView.widthAnchor.constraint(equalToConstant: 30),
//            countIconImageView.heightAnchor.constraint(equalToConstant: 30),
//            
//            totalCountLabel.topAnchor.constraint(equalTo: countIconImageView.bottomAnchor, constant: 4),
//            totalCountLabel.centerXAnchor.constraint(equalTo: registrationsCountView.centerXAnchor),
//            
//            totalCountDescriptionLabel.topAnchor.constraint(equalTo: totalCountLabel.bottomAnchor),
//            totalCountDescriptionLabel.centerXAnchor.constraint(equalTo: registrationsCountView.centerXAnchor),
//            totalCountDescriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: registrationsCountView.bottomAnchor, constant: -8),
//            
//            // Table view
//            registrationsTableView.topAnchor.constraint(equalTo: registrationsCountView.bottomAnchor, constant: 16),
//            registrationsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            registrationsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            registrationsTableView.bottomAnchor.constraint(equalTo: downloadButton.topAnchor, constant: -16),
//            
//            // Empty state view
//            emptyStateView.centerXAnchor.constraint(equalTo: registrationsTableView.centerXAnchor),
//            emptyStateView.centerYAnchor.constraint(equalTo: registrationsTableView.centerYAnchor),
//            emptyStateView.widthAnchor.constraint(equalToConstant: 200),
//            emptyStateView.heightAnchor.constraint(equalToConstant: 200),
//            
//            emptyStateImageView.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
//            emptyStateImageView.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
//            emptyStateImageView.widthAnchor.constraint(equalToConstant: 80),
//            emptyStateImageView.heightAnchor.constraint(equalToConstant: 80),
//            
//            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor, constant: 16),
//            emptyStateLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
//            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
//            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
//            
//            // Download button
//            downloadButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
//            downloadButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
//            downloadButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
//            downloadButton.heightAnchor.constraint(equalToConstant: 50),
//            
//            // Activity indicator
//            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
//        ])
//    }
//    
//    // MARK: - Data Handling
//    @objc private func refreshRegistrations() {
//        fetchRegistrations()
//    }
//    
//    private func fetchRegistrations() {
//        activityIndicator.startAnimating()
//        
//        db.collection("registrations")
//            .whereField("eventId", isEqualTo: eventId)
//            .getDocuments { [weak self] (snapshot, error) in
//                guard let self = self else { return }
//                
//                self.activityIndicator.stopAnimating()
//                self.refreshControl.endRefreshing()
//                
//                if let error = error {
//                    print("Error fetching registrations: \(error.localizedDescription)")
//                    self.showAlert(title: "Error", message: "Failed to load registrations. Please try again.")
//                    return
//                }
//                
//                guard let documents = snapshot?.documents else {
//                    print("No registrations found for event \(self.eventId)")
//                    self.registrations = []
//                    self.updateUI()
//                    return
//                }
//                
//                self.registrations = documents.map { $0.data() }
//                self.filteredRegistrations = self.registrations
//                self.updateUI()
//            }
//    }
//    
//    private func updateUI() {
//        let count = filteredRegistrations.count
//        totalCountLabel.text = "\(count)"
//        
//        // Show/hide empty state
//        emptyStateView.isHidden = count > 0
//        
//        // Update download button state
//        downloadButton.isEnabled = count > 0
//        downloadButton.alpha = count > 0 ? 1.0 : 0.6
//        
//        registrationsTableView.reloadData()
//    }
//    
//    // MARK: - Search Handling
//    func updateSearchResults(for searchController: UISearchController) {
//        guard let searchText = searchController.searchBar.text?.lowercased(), !searchText.isEmpty else {
//            filteredRegistrations = registrations
//            updateUI()
//            return
//        }
//        
//        filteredRegistrations = registrations.filter { registration in
//            let name = (registration["Name"] as? String ?? "").lowercased()
//            let email = (registration["email"] as? String ?? "").lowercased()
//            let regNumber = (registration["Registration No."] as? String ?? "").lowercased()
//            let collegeEmail = (registration["College Email ID"] as? String ?? "").lowercased()
//            
//            return name.contains(searchText) ||
//                   email.contains(searchText) ||
//                   regNumber.contains(searchText) ||
//                   collegeEmail.contains(searchText)
//        }
//        
//        updateUI()
//    }
//    
//    // MARK: - UITableView DataSource & Delegate
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return filteredRegistrations.count
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: RegistrationTableViewCell.identifier, for: indexPath) as! RegistrationTableViewCell
//        let registration = filteredRegistrations[indexPath.row]
//        cell.configure(with: registration, index: indexPath.row)
//        return cell
//    }
//    
//    // MARK: - Download Button Action
//    @objc private func handleDownload() {
//        let actionSheet = UIAlertController(title: "Export Options",
//                                           message: "Choose export format",
//                                           preferredStyle: .actionSheet)
//        
//        actionSheet.addAction(UIAlertAction(title: "Basic CSV (Name, Email, Year)", style: .default) { _ in
//            self.exportCSV(detailed: false)
//        })
//        
//        actionSheet.addAction(UIAlertAction(title: "Detailed CSV (All Fields)", style: .default) { _ in
//            self.exportCSV(detailed: true)
//        })
//        
//        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
//        
//        // For iPad compatibility
//        if let popoverController = actionSheet.popoverPresentationController {
//            popoverController.sourceView = downloadButton
//            popoverController.sourceRect = downloadButton.bounds
//        }
//        
//        present(actionSheet, animated: true)
//    }
//    
//    private func exportCSV(detailed: Bool) {
//        let fileName = "registrations_event_\(eventId)_\(Date().timeIntervalSince1970).csv"
//        let csvData = detailed ? generateDetailedCSVData() : generateBasicCSVData()
//        
//        let fileManager = FileManager.default
//        let tempURL = fileManager.temporaryDirectory.appendingPathComponent(fileName)
//        
//        do {
//            try csvData.write(to: tempURL, atomically: true, encoding: .utf8)
//            let activityViewController = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
//            
//            // For iPad compatibility
//            if let popoverPresentationController = activityViewController.popoverPresentationController {
//                popoverPresentationController.sourceView = downloadButton
//                popoverPresentationController.sourceRect = downloadButton.bounds
//            }
//            
//            present(activityViewController, animated: true)
//        } catch {
//            print("Error writing CSV file: \(error.localizedDescription)")
//            showAlert(title: "Export Error", message: "Failed to create CSV file")
//        }
//    }
//    
//    private func generateBasicCSVData() -> String {
//        var csvString = "S.No,Name,Email,Year of Study\n" // Header row
//        
//        for (index, registration) in filteredRegistrations.enumerated() {
//            let serialNumber = index + 1
//            let name = registration["Name"] as? String ?? "N/A"
//            let email = registration["email"] as? String ?? "N/A"
//            let year = registration["Year of Study"] as? String ?? "N/A"
//            
//            // Sanitize fields for CSV format
//            let sanitizedName = name.replacingOccurrences(of: "\"", with: "\"\"")
//            let sanitizedEmail = email.replacingOccurrences(of: "\"", with: "\"\"")
//            
//            csvString += "\(serialNumber),\"\(sanitizedName)\",\"\(sanitizedEmail)\",\"\(year)\"\n"
//        }
//        
//        return csvString
//    }
//    
//    private func generateDetailedCSVData() -> String {
//        // Get all possible keys from the first registration
//        let possibleKeys = ["Name", "email", "Year of Study", "College Email ID", "Contact Number",
//                            "Course", "Department", "FA Number", "Faculty Advisor", "Personal Email ID",
//                            "Registration No.", "Section", "Specialization"]
//        
//        // Create header row
//        var csvString = "S.No," + possibleKeys.map { "\"\($0)\"" }.joined(separator: ",") + "\n"
//        
//        // Add data rows
//        for (index, registration) in filteredRegistrations.enumerated() {
//            let serialNumber = index + 1
//            csvString += "\(serialNumber),"
//            
//            for key in possibleKeys {
//                let value = registration[key] as? String ?? "N/A"
//                let sanitizedValue = value.replacingOccurrences(of: "\"", with: "\"\"")
//                csvString += "\"\(sanitizedValue)\","
//            }
//            
//            // Remove trailing comma and add newline
//            csvString = String(csvString.dropLast()) + "\n"
//        }
//        
//        return csvString
//    }
//    
//    // MARK: - Helper Methods
//    private func showAlert(title: String, message: String) {
//        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        alertController.addAction(UIAlertAction(title: "OK", style: .default))
//        present(alertController, animated: true)
//    }
//}
