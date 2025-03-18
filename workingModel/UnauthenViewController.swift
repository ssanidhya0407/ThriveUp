////
////  UnauthenViewController.swift
////  ThriveUp
////
////  Created by Yash's Mackbook on 19/11/24.
////
//import UIKit
//
//class UnauthenticatedProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
//
//    // MARK: - Properties
//    private var registeredEvents: [EventModel] = [] // Placeholder for registered events (for demo purposes)
//
//    // UI Elements
//    private let profileImageView: UIImageView = {
//        let imageView = UIImageView()
//        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 80, weight: .regular, scale: .large)
//        imageView.image = UIImage(systemName: "person.circle.fill", withConfiguration: symbolConfig) // Default User Icon in iOS
//        imageView.contentMode = .scaleAspectFit
//        imageView.tintColor = .lightGray
//        return imageView
//    }()
//
//    private let nameLabel: UILabel = {
//        let label = UILabel()
//        label.text = "Guest User"
//        label.font = UIFont.boldSystemFont(ofSize: 22)
//        label.textColor = .darkGray
//        return label
//    }()
//
//    private let emailLabel: UILabel = {
//        let label = UILabel()
//        label.text = "Please log in to view your profile."
//        label.font = UIFont.systemFont(ofSize: 16)
//        label.textColor = .gray
//        label.textAlignment = .center
//        return label
//    }()
//
//    private let loginButton: UIButton = {
//        let button = UIButton()
//        button.setTitle("Log In", for: .normal)
//        button.backgroundColor = UIColor.orange
//        button.setTitleColor(.white, for: .normal)
//        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
//        button.layer.cornerRadius = 8
//        button.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
//        return button
//    }()
//
//    private let placeholderLabel: UILabel = {
//        let label = UILabel()
//        label.text = "Log in to view your registered events."
//        label.font = UIFont.systemFont(ofSize: 16)
//        label.textColor = .darkGray
//        label.textAlignment = .center
//        label.numberOfLines = 0
//        return label
//    }()
//
//    private let eventsTableView: UITableView = {
//        let tableView = UITableView()
//        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "EventCell")
//        tableView.isHidden = true // Initially hidden until there are events to show
//        return tableView
//    }()
//
//    // MARK: - Lifecycle
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        configureNavigationBar()
//        setupUI()
//        setupConstraints()
//        print("UnauthenticatedProfileViewController loaded.")
//    }
//
//    // MARK: - Setup UI
//    private func setupUI() {
//        view.backgroundColor = .white
//        view.addSubview(profileImageView)
//        view.addSubview(nameLabel)
//        view.addSubview(emailLabel)
//        view.addSubview(loginButton)
//        view.addSubview(placeholderLabel)
//        view.addSubview(eventsTableView)
//
//        // Set table view data source and delegate
//        eventsTableView.dataSource = self
//        eventsTableView.delegate = self
//    }
//
//    private func setupConstraints() {
//        profileImageView.translatesAutoresizingMaskIntoConstraints = false
//        nameLabel.translatesAutoresizingMaskIntoConstraints = false
//        emailLabel.translatesAutoresizingMaskIntoConstraints = false
//        loginButton.translatesAutoresizingMaskIntoConstraints = false
//        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
//        eventsTableView.translatesAutoresizingMaskIntoConstraints = false
//
//        NSLayoutConstraint.activate([
//            profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
//            profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            profileImageView.widthAnchor.constraint(equalToConstant: 120),
//            profileImageView.heightAnchor.constraint(equalToConstant: 120),
//
//            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
//            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//
//            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
//            emailLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            emailLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//
//            loginButton.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 24),
//            loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            loginButton.widthAnchor.constraint(equalToConstant: 160),
//            loginButton.heightAnchor.constraint(equalToConstant: 44),
//
//            placeholderLabel.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 40),
//            placeholderLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            placeholderLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//
//            eventsTableView.topAnchor.constraint(equalTo: placeholderLabel.bottomAnchor, constant: 16),
//            eventsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            eventsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            eventsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        ])
//    }
//
//    // MARK: - Configure Navigation Bar
//    private func configureNavigationBar() {
//        navigationItem.title = "Profile"
//        navigationController?.navigationBar.titleTextAttributes = [
//            .font: UIFont.boldSystemFont(ofSize: 24),
//            .foregroundColor: UIColor.black
//        ]
//    }
//
//    // MARK: - Login Button Action
//    @objc private func loginButtonTapped() {
//        let loginVC = LoginViewController() // Replace with your LoginViewController
//        navigationController?.pushViewController(loginVC, animated: true)
//    }
//
//    // MARK: - UITableView DataSource
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return registeredEvents.count
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath)
//        cell.textLabel?.text = "Event \(indexPath.row + 1)" // Replace with actual event data
//        return cell
//    }
//
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        print("Selected Event \(indexPath.row + 1)")
//    }
//}
//
//#Preview{
//    UnauthenticatedProfileViewController()
//}


import UIKit

class UnauthenticatedProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properties
    private var registeredEvents: [EventModel] = [] // Placeholder for registered events
    
    // Gradient Background
    private let gradientView: UIView = {
        let view = UIView()
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 1.0, green: 0.7, blue: 0.4, alpha: 1.0).cgColor, // Soft Orange
            UIColor.white.cgColor // Fade to White
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.frame = UIScreen.main.bounds
        view.layer.addSublayer(gradientLayer)
        return view
    }()
    
    // Profile Image
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 80, weight: .regular, scale: .large)
        imageView.image = UIImage(systemName: "person.circle.fill", withConfiguration: symbolConfig)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white // Stand out in gradient
        return imageView
    }()
    
    
    // Email Label
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .systemOrange
        label.textAlignment = .center
        return label
    }()
    
    // Log In Button
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = UIColor.systemOrange
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.layer.cornerRadius = 10
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 0, height: 3)
        button.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // Placeholder for No Events
    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "Login in to access your registered events"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .darkGray
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    // Events Table View
    private let eventsTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "EventCell")
        tableView.isHidden = true // Initially hidden until events are available
        tableView.backgroundColor = .clear
        return tableView
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        setupUI()
        setupConstraints()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.addSubview(gradientView) // Add gradient first
        view.sendSubviewToBack(gradientView)
        
        view.addSubview(profileImageView)
        view.addSubview(emailLabel)
        view.addSubview(loginButton)
        view.addSubview(placeholderLabel)
        view.addSubview(eventsTableView)
        
        eventsTableView.dataSource = self
        eventsTableView.delegate = self
    }
    
    private func setupGradientBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0).cgColor, // Darker Orange
            UIColor(red: 1.0, green: 0.8, blue: 0.5, alpha: 1.0).cgColor, // Lighter Orange
            UIColor.white.cgColor // Fading earlier
        ]
        gradientLayer.locations = [0.0, 0.35, 1.0] // Fade earlier at 35% of screen height
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.frame = view.bounds

        let gradientView = UIView(frame: view.bounds)
        gradientView.layer.insertSublayer(gradientLayer, at: 0)
        view.addSubview(gradientView)
        view.sendSubviewToBack(gradientView)
    }

    
    private func setupConstraints() {
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        eventsTableView.translatesAutoresizingMaskIntoConstraints = false
        
//        NSLayoutConstraint.activate([
//            profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
//            profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            profileImageView.widthAnchor.constraint(equalToConstant: 120),
//            profileImageView.heightAnchor.constraint(equalToConstant: 120),
//
//            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 12),
//            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//
//            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
//            emailLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            emailLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//
//            loginButton.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 24),
//            loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            loginButton.widthAnchor.constraint(equalToConstant: 180),
//            loginButton.heightAnchor.constraint(equalToConstant: 48),
//
//            placeholderLabel.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 50),
//            placeholderLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
//            placeholderLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
//
//            eventsTableView.topAnchor.constraint(equalTo: placeholderLabel.bottomAnchor, constant: 16),
//            eventsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            eventsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            eventsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        ])
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 120), // Moved Down
            profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),


            emailLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 10),
            emailLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            emailLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            loginButton.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 30), // More Space
            loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loginButton.widthAnchor.constraint(equalToConstant: 160),
            loginButton.heightAnchor.constraint(equalToConstant: 44),

            placeholderLabel.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 60), // Moved lower
            placeholderLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            placeholderLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            eventsTableView.topAnchor.constraint(equalTo: placeholderLabel.bottomAnchor, constant: 16),
            eventsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            eventsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            eventsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

    }
    
    // MARK: - Configure Navigation Bar
    private func configureNavigationBar() {
        navigationItem.title = ""
        navigationController?.navigationBar.titleTextAttributes = [
            .font: UIFont.boldSystemFont(ofSize: 22),
            .foregroundColor: UIColor.black
        ]
    }
    
    // MARK: - Login Button Action
    @objc private func loginButtonTapped() {
        let loginVC = LoginViewController() // Replace with your actual LoginViewController
        navigationController?.pushViewController(loginVC, animated: true)
    }
    
    // MARK: - UITableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return registeredEvents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath)
        cell.textLabel?.text = "Event \(indexPath.row + 1)" // Replace with actual event data
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cell.backgroundColor = .white
        cell.layer.cornerRadius = 10
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOpacity = 0.1
        cell.layer.shadowOffset = CGSize(width: 0, height: 3)
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Selected Event \(indexPath.row + 1)")
    }
}

#Preview {
    UnauthenticatedProfileViewController()
}
