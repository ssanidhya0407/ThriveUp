//
//  HackathonRegistrationViewController.swift
//  ThriveUp
//
//  Created by Sanidhya's MacBook Pro on 19/03/25.
//


//
//  HackathonRegistrationViewController.swift
//  workingModel
//
//  Created by ThriveUp on 2025-03-18.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import CoreImage.CIFilterBuiltins

class HackathonRegistrationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    private var formFields: [FormField]
    private var event: EventModel
    private var userId: String?
    
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let headerLabel = UILabel()
    private let registerButton = UIButton(type: .system)
    
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
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
        title = "Hackathon Registration"
        
        // Setup Header Label
        headerLabel.text = "Register for \(event.title)"
        headerLabel.font = UIFont.boldSystemFont(ofSize: 24)
        headerLabel.textAlignment = .center
        headerLabel.numberOfLines = 0
        view.addSubview(headerLabel)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup Table View
        tableView.register(FormTableViewCell.self, forCellReuseIdentifier: "FormCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup Register Button
        registerButton.setTitle("Continue to Team Selection", for: .normal)
        registerButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        registerButton.backgroundColor = .orange
        registerButton.setTitleColor(.white, for: .normal)
        registerButton.layer.cornerRadius = 10
        registerButton.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
        view.addSubview(registerButton)
        registerButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup Constraints
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: registerButton.topAnchor, constant: -20),
            
            registerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            registerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            registerButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            registerButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Table View DataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return formFields.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FormCell", for: indexPath) as! FormTableViewCell
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
    
    @objc private func registerButtonTapped() {
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
            "timestamp": Timestamp(date: Date()) // Consistent with RegistrationVC
        ]
        
        // Add form field data using original placeholder names (like RegistrationVC)
        for field in formFields {
            data[field.placeholder] = field.value
        }
        
        // Generate QR code like in RegistrationVC
        let qrData = [
            "uid": userId,
            "eventId": event.eventId
        ]
        
        if let qrCodeString = try? JSONSerialization.data(withJSONObject: qrData, options: .prettyPrinted),
           let qrCode = generateQRCode(from: String(data: qrCodeString, encoding: .utf8) ?? "") {
            data["qrCode"] = qrCode.pngData()?.base64EncodedString()
        }
        
        // Add to "registrations" collection (consistent with RegistrationVC)
        db.collection("registrations").addDocument(data: data) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error registering for event: \(error.localizedDescription)")
                let alert = UIAlertController(title: "Registration Failed", message: "There was an error registering for this event. Please try again.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
                return
            }
            
            // Check if event is already approved and add user to group (like in RegistrationVC)
            self.db.collection("events").document(self.event.eventId).getDocument { (document, error) in
                if let document = document, let data = document.data(),
                   let status = data["status"] as? String, status == "accepted" {
                    // Event is already approved, add user to group immediately
                    let eventGroupManager = EventGroupManager()
                    eventGroupManager.addUserToEventGroup(eventId: self.event.eventId, userId: userId) { success in
                        print("User added to group: \(success)")
                    }
                }
            }
            
            // Successfully registered
            print("Successfully registered for event")
            
            // Show success message with QR code info before navigating
            let alert = UIAlertController(title: "Success", message: "Registration successful! QR Code generated.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                // Now navigate to the team selection screen
                self.navigateToTeamSelection()
            })
            self.present(alert, animated: true)
        }
    }

    // Add this QR code generation method from RegistrationVC
    private func generateQRCode(from string: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")
        
        guard let outputImage = filter.outputImage else { return nil }
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)
        
        return UIImage(ciImage: scaledImage)
    }
    
    private func navigateToTeamSelection() {
        let teamSelectionVC = HackathonTeamSelectionViewController(event: event)
        navigationController?.pushViewController(teamSelectionVC, animated: true)
    }
}

// MARK: - Form Cell
class FormTableViewCell: UITableViewCell {
    
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
