//import UIKit
//import FirebaseAuth
//import FirebaseFirestore
//
//class LoginViewController: UIViewController {
//    
//    // MARK: - UI Elements
//    private let segmentedControl: UISegmentedControl = {
//        let control = UISegmentedControl(items: ["User", "Organiser"])
//        control.selectedSegmentIndex = 0
//        control.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.1)
//        control.selectedSegmentTintColor = .white
//        control.layer.cornerRadius = 15
//        control.layer.masksToBounds = true
//        control.translatesAutoresizingMaskIntoConstraints = false
//        return control
//    }()
//    
//    
//    private let profileImageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.image = UIImage(systemName: "person.circle.fill")
//        imageView.tintColor = .systemOrange
//        imageView.contentMode = .scaleAspectFit
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        return imageView
//    }()
//    
//    private let loginTitleLabel: UILabel = {
//        let label = UILabel()
//        label.text = "User Login"
//        label.font = UIFont.boldSystemFont(ofSize: 28)
//        label.textAlignment = .center
//        label.textColor = .black
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//    
//    private let loginSubtitleLabel: UILabel = {
//        let label = UILabel()
//        label.text = "Enter with your SRM credentials"
//        label.font = UIFont.systemFont(ofSize: 16)
//        label.textColor = .gray
//        label.textAlignment = .center
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//    
//    private let userIDTextField: UITextField = {
//        let textField = UITextField()
//        textField.placeholder = "Email"
//        textField.borderStyle = .roundedRect
//        textField.layer.cornerRadius = 10
//        textField.layer.borderWidth = 1
//        textField.layer.borderColor = UIColor.systemOrange.cgColor
//        textField.translatesAutoresizingMaskIntoConstraints = false
//        return textField
//    }()
//    
//    private let passwordTextField: UITextField = {
//        let textField = UITextField()
//        textField.placeholder = "Password"
//        textField.isSecureTextEntry = true
//        textField.borderStyle = .roundedRect
//        textField.layer.cornerRadius = 10
//        textField.layer.borderWidth = 1
//        textField.layer.borderColor = UIColor.systemOrange.cgColor
//        textField.translatesAutoresizingMaskIntoConstraints = false
//        return textField
//    }()
//    
//    private let loginButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("Login", for: .normal)
//        button.backgroundColor = .systemOrange
//        button.setTitleColor(.white, for: .normal)
//        button.layer.cornerRadius = 8
//        button.translatesAutoresizingMaskIntoConstraints = false
//        return button
//    }()
//    
//    // Card View for the loading spinner
//    private let cardView: UIView = {
//        let view = UIView()
//        view.backgroundColor = .white
//        view.layer.cornerRadius = 16
//        view.layer.shadowColor = UIColor.black.cgColor
//        view.layer.shadowOpacity = 0.2
//        view.layer.shadowOffset = CGSize(width: 0, height: 4)
//        view.layer.shadowRadius = 8
//        view.translatesAutoresizingMaskIntoConstraints = false
//        view.isHidden = true // Initially hidden
//        return view
//    }()
//    
//    private let activityIndicator: UIActivityIndicatorView = {
//        let spinner = UIActivityIndicatorView(style: .large)
//        spinner.color = .systemOrange
//        spinner.translatesAutoresizingMaskIntoConstraints = false
//        spinner.hidesWhenStopped = true
//        return spinner
//    }()
//    
//    private var isUserSelected = true // Track whether "User" or "Host" is selected
//    
//    // MARK: - View Lifecycle
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .white
//        setupViews()
//        setupConstraints()
//        setupActions()
//    }
//    
//    // MARK: - Setup Methods
//    private func setupViews() {
//        view.addSubview(segmentedControl)
//        view.addSubview(profileImageView)
//        view.addSubview(loginTitleLabel)
//        view.addSubview(loginSubtitleLabel)
//        view.addSubview(userIDTextField)
//        view.addSubview(passwordTextField)
//        view.addSubview(loginButton)
//        view.addSubview(cardView) // Add the card view behind the spinner
//        cardView.addSubview(activityIndicator) // Add activity indicator inside the card view
//    }
//    
//    private func setupConstraints() {
//        NSLayoutConstraint.activate([
//            
//            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
//            segmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            segmentedControl.widthAnchor.constraint(equalToConstant: 250),
//            
//            profileImageView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 32),
//            profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            profileImageView.widthAnchor.constraint(equalToConstant: 100),
//            profileImageView.heightAnchor.constraint(equalToConstant: 100),
//            
//            loginTitleLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
//            loginTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            
//            loginSubtitleLabel.topAnchor.constraint(equalTo: loginTitleLabel.bottomAnchor, constant: 8),
//            loginSubtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            
//            userIDTextField.topAnchor.constraint(equalTo: loginSubtitleLabel.bottomAnchor, constant: 32),
//            userIDTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
//            userIDTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
//            
//            passwordTextField.topAnchor.constraint(equalTo: userIDTextField.bottomAnchor, constant: 16),
//            passwordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
//            passwordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
//            
//            loginButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 32),
//            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
//            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
//            loginButton.heightAnchor.constraint(equalToConstant: 50),
//            
//            // Card View (Loading Spinner Background) Constraints
//            cardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//            cardView.widthAnchor.constraint(equalToConstant: 200),
//            cardView.heightAnchor.constraint(equalToConstant: 150),
//            
//            // Activity Indicator inside Card
//            activityIndicator.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
//            activityIndicator.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
//        ])
//    }
//    
//    private func setupActions() {
//        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
//        loginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
//    }
//    
//    // MARK: - Actions
//    @objc private func segmentChanged() {
//        isUserSelected = segmentedControl.selectedSegmentIndex == 0
//        updateLoginPrompt()
//    }
//    
//    
//    private func updateLoginPrompt() {
//        loginTitleLabel.text = isUserSelected ? "User Login" : "Organiser Login"
//        
//        // Change profile image based on selection
//        if isUserSelected {
//            profileImageView.image = UIImage(systemName: "person.circle.fill")
//        } else {
//            profileImageView.image = UIImage(systemName: "person.3.fill")
//        }
//    }
//    
//    @objc private func handleLogin() {
//        guard let email = userIDTextField.text, !email.isEmpty,
//              let password = passwordTextField.text, !password.isEmpty else {
//            showAlert(title: "Error", message: "Please enter a valid email and password.")
//            return
//        }
//        
//        // Show the card with the activity indicator when login starts
//        cardView.isHidden = false
//        activityIndicator.startAnimating()
//        
//        let alert = UIAlertController(title: "Confirm Login", message: "You are logging in as \(isUserSelected ? "User" : "Organiser")", preferredStyle: .alert)
//        
//        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
//        
//        alert.addAction(UIAlertAction(title: "Proceed", style: .default, handler: { [weak self] _ in
//            self?.performLogin(email: email, password: password)
//        }))
//        
//        present(alert, animated: true, completion: nil)
//    }
//    
//    private func performLogin(email: String, password: String) {
//        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
//            // Stop the activity indicator once login finishes
//            self?.cardView.isHidden = true
//            self?.activityIndicator.stopAnimating()
//            
//            if let error = error {
//                self?.showAlert(title: "Login Failed", message: error.localizedDescription)
//                return
//            }
//            
//            if let user = result?.user {
//                // Add user to Firestore Users collection
//                self?.addUserToFirestore(uid: user.uid, email: email)
//                
//                if self?.isUserSelected == true {
//                    self?.navigateToUserTabBar()
//                } else {
//                    self?.navigateToOrganizerTabBar()
//                }
//            }
//        }
//    }
//    
//    // MARK: - Firestore Methods
//    private func addUserToFirestore(uid: String, email: String) {
//        let db = Firestore.firestore()
//        let userRef = db.collection("users").document(uid)
//        
//        userRef.getDocument { [weak self] document, error in
//            if let document = document, document.exists {
//                // User document already exists, no need to create it
//                return
//            } else {
//                // Create user document with email, uid, and userType
//                let userType = self?.isUserSelected == true ? "user" : "host"
//                userRef.setData([
//                    "email": email,
//                    "uid": uid,
//                    "userType": userType,
//                    "Description": "Enter Description",
//                    "profileImageURL": "",
//                    "ContactDetails": "Enter Contact",
//                    "name": "Enter Name"
//                ]) { error in
//                    if let error = error {
//                        self?.showAlert(title: "Error", message: "Failed to create user document: \(error.localizedDescription)")
//                    }
//                }
//            }
//        }
//    }
//    
//    // MARK: - Navigation Methods
//    private func navigateToUserTabBar() {
//        NotificationCenter.default.post(name: .userDidLogin, object: nil)
//        MessageNotificationService.shared.startListeningForNewMessages()
//        let userTabBar = UserTabBarController()
//        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate {
//            sceneDelegate.window?.rootViewController = userTabBar
//            sceneDelegate.window?.makeKeyAndVisible()
//        
//        }
//    }
//    
//    private func navigateToOrganizerTabBar() {
//        NotificationCenter.default.post(name: .userDidLogin, object: nil)
//        MessageNotificationService.shared.startListeningForNewMessages()
//        let organizerTabBar = OrganizerTabBar()
//        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate {
//            sceneDelegate.window?.rootViewController = organizerTabBar
//            sceneDelegate.window?.makeKeyAndVisible()
//        }
//    }
//    
//    // MARK: - Helper Methods
//    private func showAlert(title: String, message: String) {
//        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//        present(alert, animated: true, completion: nil)
//    }
//}
//
//
//#Preview{
//    LoginViewController()
//}


import UIKit
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import FirebaseCore

class LoginViewController: UIViewController {
    
    // MARK: - UI Elements
    public let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.tintColor = .systemOrange
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let loginTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Login"
        label.font = UIFont.boldSystemFont(ofSize: 28)
        label.textAlignment = .center
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let loginSubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Enter with your credentials"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .gray
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let userIDTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Email"
        textField.borderStyle = .roundedRect
        textField.layer.cornerRadius = 10
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.systemOrange.cgColor
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Password"
        textField.isSecureTextEntry = true
        textField.borderStyle = .roundedRect
        textField.layer.cornerRadius = 10
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.systemOrange.cgColor
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.backgroundColor = .systemOrange
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold) // Add this line
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let orLabel: UILabel = {
        let label = UILabel()
        label.text = "or"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let googleLoginButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemGray5
       
       
        button.layer.cornerRadius = 8
        
        // Create a horizontal stack view
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 12
        stackView.isUserInteractionEnabled = false // Important for button tap
        
        // Add Google icon
        let icon = UIImageView(image: UIImage(named: "google_icon"))
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // Add label
        let label = UILabel()
        label.text = "Continue with Google"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        
        // Add to stack
        stackView.addArrangedSubview(icon)
        stackView.addArrangedSubview(label)
        
        // Add stack to button
        button.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: button.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: button.trailingAnchor, constant: -16)
        ])
        
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Card View for the loading spinner
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .systemOrange
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        return spinner
    }()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupViews()
        setupConstraints()
        setupActions()
    }
    
    // MARK: - Setup Methods
    private func setupViews() {
        view.addSubview(profileImageView)
        view.addSubview(loginTitleLabel)
        view.addSubview(loginSubtitleLabel)
        view.addSubview(userIDTextField)
        view.addSubview(passwordTextField)
        view.addSubview(loginButton)
        view.addSubview(orLabel)
        view.addSubview(googleLoginButton)
        view.addSubview(cardView)
        cardView.addSubview(activityIndicator)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),
            
            loginTitleLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            loginTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            loginSubtitleLabel.topAnchor.constraint(equalTo: loginTitleLabel.bottomAnchor, constant: 8),
            loginSubtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            userIDTextField.topAnchor.constraint(equalTo: loginSubtitleLabel.bottomAnchor, constant: 32),
            userIDTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            userIDTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            passwordTextField.topAnchor.constraint(equalTo: userIDTextField.bottomAnchor, constant: 16),
            passwordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            passwordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            loginButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 32),
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            
            orLabel.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 20),
            orLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            googleLoginButton.topAnchor.constraint(equalTo: orLabel.bottomAnchor, constant: 20),
            googleLoginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            googleLoginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            googleLoginButton.heightAnchor.constraint(equalToConstant: 50),
            
            cardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardView.widthAnchor.constraint(equalToConstant: 200),
            cardView.heightAnchor.constraint(equalToConstant: 150),
            
            activityIndicator.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
        ])
    }
    
    private func setupActions() {
        loginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        googleLoginButton.addTarget(self, action: #selector(handleGoogleLogin), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func handleLogin() {
        guard let email = userIDTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Error", message: "Please enter a valid email and password.")
            return
        }
        
        showLoading(true)
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            self?.showLoading(false)
            
            if let error = error {
                self?.showAlert(title: "Login Failed", message: error.localizedDescription)
                return
            }
            
            if let user = result?.user {
                // After successful login, show the user type selection
                self?.showUserTypeSelectionAlert(email: email, uid: user.uid)
            }
        }
    }
    
    @objc private func handleGoogleLogin() {
        showLoading(true)
        
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] result, error in
            self?.showLoading(false)
            
            if let error = error {
                self?.showAlert(title: "Error", message: error.localizedDescription)
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                self?.showAlert(title: "Error", message: "Failed to get user information")
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)
            
            self?.showLoading(true)
            Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                self?.showLoading(false)
                
                if let error = error {
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                    return
                }
                
                if let user = authResult?.user {
                    // Ask if the user is logging in as a regular user or organizer
                    self?.showUserTypeSelectionAlert(email: user.email ?? "", uid: user.uid)
                }
            }
        }
    }
    
    private func showUserTypeSelectionAlert(email: String, uid: String) {
        let alert = UIAlertController(
            title: "Select Account Type",
            message: "Are you logging in as a User or Organizer?",
            preferredStyle: .alert
        )
        
        // Always show User option
        alert.addAction(UIAlertAction(title: "User", style: .default) { [weak self] _ in
            self?.addUserToFirestore(uid: uid, email: email, isUser: true)
            self?.navigateToUserTabBar()
        })
        
        // Show Organizer option but verify approval when selected
        alert.addAction(UIAlertAction(title: "Organizer", style: .default) { [weak self] _ in
            self?.verifyOrganizerApproval(email: email, uid: uid)
        })
        
        present(alert, animated: true)
    }

    private func verifyOrganizerApproval(email: String, uid: String) {
        showLoading(true)
        
        let db = Firestore.firestore()
        db.collection("approvedOrganizers")
          .whereField("email", isEqualTo: email)
          .getDocuments { [weak self] snapshot, error in
              self?.showLoading(false)
              
              if let error = error {
                  self?.showAlert(title: "Error", message: "Failed to verify organizer status: \(error.localizedDescription)")
                  return
              }
              
              if let documents = snapshot?.documents, !documents.isEmpty {
                  // Approved organizer
                  self?.addUserToFirestore(uid: uid, email: email, isUser: false)
                  self?.navigateToOrganizerTabBar()
              } else {
                  // Not approved
                  self?.showAlert(
                      title: "Not Approved",
                      message: "You are not an approved organizer. Please contact admin for access."
                  )
                  self?.addUserToFirestore(uid: uid, email: email, isUser: true)
              }
          }
    }

    private func checkIfApprovedOrganizer(email: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        db.collection("approvedOrganizers")
          .whereField("email", isEqualTo: email)
          .getDocuments { snapshot, error in
              if let error = error {
                  print("Error checking organizer status: \(error)")
                  completion(false)
                  return
              }
              completion(!(snapshot?.documents.isEmpty ?? true))
          }
    }
    private func navigateBasedOnUserType(uid: String) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            guard let data = snapshot?.data() else { return }
            
            if data["userType"] as? String == "host" {
                if data["isApproved"] as? Bool == true {
                    self?.navigateToOrganizerTabBar()
                } else {
                    self?.showAlert(title: "Approval Needed",
                                   message: "Your organizer account is pending approval")
                    self?.navigateToUserTabBar()
                }
            } else {
                self?.navigateToUserTabBar()
            }
        }
    }
    private func showLoading(_ show: Bool) {
        cardView.isHidden = !show
        show ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
    }
    
    // MARK: - Firestore Methods
    private func addUserToFirestore(uid: String, email: String, isUser: Bool) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        
        userRef.getDocument { [weak self] document, error in
            if let document = document, document.exists {
                return // User document already exists
            } else {
                let userType = isUser ? "user" : "host"
                var userData: [String: Any] = [
                    "email": email,
                    "uid": uid,
                    "userType": userType,
                    "isApproved": isUser // Auto-approve users, organizers need approval
                ]
                
                if !isUser {
                    userData["approvalPending"] = true
                }
                
                userRef.setData(userData) { error in
                    if let error = error {
                        self?.showAlert(title: "Error", message: "Failed to create user document: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation Methods
    private func navigateToUserTabBar() {
        NotificationCenter.default.post(name: .userDidLogin, object: nil)
        MessageNotificationService.shared.startListeningForNewMessages()
        let userTabBar = UserTabBarController()
        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate {
            sceneDelegate.window?.rootViewController = userTabBar
            sceneDelegate.window?.makeKeyAndVisible()
        }
    }
    
    private func navigateToOrganizerTabBar() {
        NotificationCenter.default.post(name: .userDidLogin, object: nil)
        MessageNotificationService.shared.startListeningForNewMessages()
        let organizerTabBar = OrganizerTabBar()
        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate {
            sceneDelegate.window?.rootViewController = organizerTabBar
            sceneDelegate.window?.makeKeyAndVisible()
        }
    }
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

#Preview {
    LoginViewController()
}
