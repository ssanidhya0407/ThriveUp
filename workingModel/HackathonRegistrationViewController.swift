//
//  HackathonRegistrationViewController.swift
//  ThriveUp
//
//  Created by Sanidhya's MacBook Pro on 18/03/25.
//


import UIKit
import FirebaseFirestore
import FirebaseAuth

class HackathonRegistrationViewController: UIViewController {
    
    // MARK: - Properties
    private let formFields: [FormField]
    private let event: EventModel
    private let db = Firestore.firestore()
    
    // UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let formStackView = UIStackView()
    private let registerButton = UIButton(type: .system)
    private var textFields: [UITextField] = []
    
    // MARK: - Initialization
    init(formFields: [FormField], event: EventModel) {
        self.formFields = formFields
        self.event = event
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
        title = "Event Registration"
        
        // Setup ScrollView
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup Title Label
        titleLabel.text = "Register for \(event.title)"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup Form Stack View
        formStackView.axis = .vertical
        formStackView.spacing = 20
        formStackView.distribution = .fillEqually
        contentView.addSubview(formStackView)
        formStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup Form Fields
        setupFormFields()
        
        // Setup Register Button
        registerButton.setTitle("Register for Hackathon", for: .normal)
        registerButton.backgroundColor = .orange
        registerButton.setTitleColor(.white, for: .normal)
        registerButton.layer.cornerRadius = 10
        registerButton.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
        contentView.addSubview(registerButton)
        registerButton.translatesAutoresizingMaskIntoConstraints = false
        
        setupConstraints()
    }
    
    private func setupFormFields() {
        for field in formFields {
            let textField = UITextField()
            textField.placeholder = field.placeholder
            textField.text = field.value
            textField.borderStyle = .roundedRect
            textField.autocapitalizationType = .words
            if field.placeholder.lowercased().contains("phone") {
                textField.keyboardType = .phonePad
            }
            formStackView.addArrangedSubview(textField)
            textFields.append(textField)
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView Constraints
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView Constraints
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title Label Constraints
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Form Stack View Constraints
            formStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            formStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            formStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Register Button Constraints
            registerButton.topAnchor.constraint(equalTo: formStackView.bottomAnchor, constant: 30),
            registerButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            registerButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            registerButton.heightAnchor.constraint(equalToConstant: 50),
            registerButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Actions
    @objc private func registerButtonTapped() {
        registerForEvent { [weak self] success in
            guard let self = self else { return }
            
            if success {
                // After successful registration, proceed to team selection screen
                DispatchQueue.main.async {
                    let teamVC = HackathonTeamViewController(event: self.event)
                    self.navigationController?.pushViewController(teamVC, animated: true)
                }
            } else {
                // Show error alert
                let alert = UIAlertController(
                    title: "Registration Failed",
                    message: "Failed to register for the hackathon. Please try again.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
        }
    }
    
    // MARK: - Registration Logic
    private func registerForEvent(completion: @escaping (Bool) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            print("No user is signed in")
            completion(false)
            return
        }
        
        // Create registration data
        var registrationData: [String: Any] = [
            "userId": currentUser.uid,
            "eventId": event.eventId,
            "registrationDate": Date().timeIntervalSince1970,
            "status": "registered"
        ]
        
        // Add form field values to registration data
        for (index, field) in formFields.enumerated() {
            if index < textFields.count {
                registrationData[field.placeholder.lowercased().replacingOccurrences(of: " ", with: "_")] = textFields[index].text ?? ""
            }
        }
        
        // Add registration to Firestore
        db.collection("event_registrations").addDocument(data: registrationData) { error in
            if let error = error {
                print("Error registering for event: \(error)")
                completion(false)
                return
            }
            
            // Update event attendance count
            let eventRef = self.db.collection("events").document(self.event.eventId)
            eventRef.updateData([
                "attendanceCount": FieldValue.increment(Int64(1))
            ])
            
            completion(true)
        }
    }
}