//
//  RegistrationViewController.swift
//  ThriveUp
//
//  Created by Yash's Mackbook on 14/11/24.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import CoreImage.CIFilterBuiltins

class RegistrationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    private var formFields: [FormField]
    private var event: EventModel
    private var userId: String?
    
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let headerLabel = UILabel()
    private let submitButton = UIButton(type: .system)
    
    // MARK: - Initializer
    init(formFields: [FormField], event: EventModel) {
        self.formFields = formFields
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
        fetchUserDetails()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white

        
        // Setup Header Label
        headerLabel.text = "Register for \(event.title)"
        headerLabel.font = UIFont.boldSystemFont(ofSize: 24)
        headerLabel.textAlignment = .center
        headerLabel.numberOfLines = 0
        view.addSubview(headerLabel)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup Table View
        tableView.register(RegistrationFormTableViewCell.self, forCellReuseIdentifier: "FormCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup Submit Button
        submitButton.setTitle("Submit", for: .normal)
        submitButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        submitButton.backgroundColor = .orange
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.layer.cornerRadius = 10
        submitButton.addTarget(self, action: #selector(handleSubmit), for: .touchUpInside)
        view.addSubview(submitButton)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup Constraints
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: submitButton.topAnchor, constant: -20),
            
            submitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            submitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            submitButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Fetch User Details
    private func fetchUserDetails() {
        guard let currentUser = Auth.auth().currentUser else {
            print("User not logged in.")
            return
        }
        
        db.collection("users").document(currentUser.uid).getDocument { [weak self] document, error in
            guard let self = self, let data = document?.data(), error == nil else {
                print("Error fetching user details: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // Pre-fill form fields with user details
            if let name = data["name"] as? String, let contact = data["ContactDetails"] as? String {
                for (index, field) in self.formFields.enumerated() {
                    if field.placeholder.lowercased().contains("name") {
                        self.formFields[index].value = name
                    } else if field.placeholder.lowercased().contains("contact") {
                        self.formFields[index].value = contact
                    }
                }
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Table View DataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return formFields.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FormCell", for: indexPath) as! RegistrationFormTableViewCell
        let field = formFields[indexPath.row]
        cell.configure(with: field, index: indexPath.row)
        cell.textField.delegate = self
        cell.textField.tag = indexPath.row
        return cell
    }
    
    // MARK: - Text Field Delegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Update form field value when editing ends
        if textField.tag < formFields.count {
            formFields[textField.tag].value = textField.text ?? ""
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Find next responder
        if let nextField = view.viewWithTag(textField.tag + 1) as? UITextField {
            nextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return false
    }
    
    // MARK: - Actions
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func handleSubmit() {
        // Validate form fields
        for field in formFields {
            if field.value.isEmpty {
                let alert = UIAlertController(title: "Incomplete Form", message: "Please fill in all fields.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                return
            }
        }
        
        // Register for the event
        registerForEvent()
    }
    
    private func registerForEvent() {
        guard let userId = self.userId ?? Auth.auth().currentUser?.uid else {
            let alert = UIAlertController(title: "Authentication Error", message: "You must be logged in to register.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Create registration data
        var data: [String: Any] = [
            "uid": userId,
            "eventId": event.eventId,
            "timestamp": Timestamp(date: Date())
        ]
        
        // Add form field data using original placeholder names
        for field in formFields {
            data[field.placeholder] = field.value
        }
        
        // Generate QR code
        let qrData = [
            "uid": userId,
            "eventId": event.eventId
        ]
        
        if let qrCodeString = try? JSONSerialization.data(withJSONObject: qrData, options: .prettyPrinted),
           let qrCode = generateQRCode(from: String(data: qrCodeString, encoding: .utf8) ?? "") {
            data["qrCode"] = qrCode.pngData()?.base64EncodedString()
        }
        
        // Add to "registrations" collection
        db.collection("registrations").addDocument(data: data) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error registering for event: \(error.localizedDescription)")
                let alert = UIAlertController(title: "Registration Failed", message: "There was an error registering for this event. Please try again.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
                return
            }
            
            // Check if event is already approved and add user to group
            self.db.collection("events").document(self.event.eventId).getDocument { (document, error) in
                if let document = document, let data = document.data(),
                   let status = data["status"] as? String, status == "accepted" {
                    // Event is already approved, add user to group immediately
                    let eventGroupManager = EventGroupManager()
                    eventGroupManager.addUserToEvent(eventId: self.event.eventId, userId: userId, role: "member") { success in
                        print("User added to group: \(success)")
                    }
                }
            }
            
            // Successfully registered
            print("Successfully registered for event")
            
            // 👇 NEW CODE: Send notifications to friends
            EventNotificationService.shared.notifyFriendsAboutEventRegistration(
                eventId: self.event.eventId,
                eventName: self.event.title,
                eventImageURL: self.event.imageName
            ) { success in
                if success {
                    print("Successfully sent notifications to friends about event registration")
                } else {
                    print("Failed to notify some friends about event registration")
                }
            }
            
            // Show success message with QR code info before navigating
            let successVC = EventRegistrationSuccessViewController(event: self.event)
            self.navigationController?.pushViewController(successVC, animated: true)
        }
    }


    // Add this QR code generation method from HackathonRegistrationVC
    private func generateQRCode(from string: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")
        
        guard let outputImage = filter.outputImage else { return nil }
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)
        
        return UIImage(ciImage: scaledImage)
    }
}

// MARK: - Form Cell
class RegistrationFormTableViewCell: UITableViewCell {
    
    let titleLabel = UILabel()
    let textField = UITextField()
    let containerView = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        // Container View
        containerView.layer.cornerRadius = 10
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.lightGray.cgColor
        containerView.backgroundColor = .white
        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title Label
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = .gray
        containerView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Text Field
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.borderStyle = .none
        containerView.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            textField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            textField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            textField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with field: FormField, index: Int) {
        titleLabel.text = field.placeholder
        textField.placeholder = "Enter \(field.placeholder.lowercased())"
        textField.text = field.value
        textField.tag = index
        
        // Setup keyboard type based on field type
        if field.placeholder.contains("Phone") {
            textField.keyboardType = .phonePad
        } else if field.placeholder.contains("Email") {
            textField.keyboardType = .emailAddress
        }
    }
}

class EventRegistrationSuccessViewController: UIViewController {
    
    private let event: EventModel
    
    init(event: EventModel) {
        self.event = event
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationItem.setHidesBackButton(true, animated: false)
        title = "Registration Complete"
        
        // Success icon
        let checkmarkImageView = UIImageView()
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        checkmarkImageView.contentMode = .scaleAspectFit
        checkmarkImageView.tintColor = .systemGreen
        checkmarkImageView.image = UIImage(systemName: "checkmark.circle.fill")
        view.addSubview(checkmarkImageView)
        
        // Congrats label
        let congratsLabel = UILabel()
        congratsLabel.translatesAutoresizingMaskIntoConstraints = false
        congratsLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        congratsLabel.textAlignment = .center
        congratsLabel.text = "Registration Successful!"
        view.addSubview(congratsLabel)
        
        // Event details
        let detailsLabel = UILabel()
        detailsLabel.translatesAutoresizingMaskIntoConstraints = false
        detailsLabel.font = UIFont.systemFont(ofSize: 16)
        detailsLabel.textAlignment = .center
        detailsLabel.numberOfLines = 0
        detailsLabel.text = "You have successfully registered for \(event.title).\nYour friends have been notified!"
        view.addSubview(detailsLabel)
        
        // Close button
        let doneButton = UIButton(type: .system)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        doneButton.backgroundColor = .orange
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.layer.cornerRadius = 10
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        view.addSubview(doneButton)
        
        NSLayoutConstraint.activate([
            checkmarkImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            checkmarkImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 100),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 100),
            
            congratsLabel.topAnchor.constraint(equalTo: checkmarkImageView.bottomAnchor, constant: 24),
            congratsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            congratsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            detailsLabel.topAnchor.constraint(equalTo: congratsLabel.bottomAnchor, constant: 16),
            detailsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            detailsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            doneButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func doneButtonTapped() {
        // Navigate back to the main events screen
        navigationController?.popToRootViewController(animated: true)
    }
}
