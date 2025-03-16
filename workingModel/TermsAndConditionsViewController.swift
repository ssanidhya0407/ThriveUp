//
//  TermsAndConditionsViewController.swift
//  ThriveUp
//
//  Created by Sanidhya's MacBook Pro on 13/03/25.
//

import UIKit

class TermsAndConditionsViewController: UIViewController {
    
    private let userDefaultsKey = "TermsAccepted"
    private func hasAcceptedTerms() -> Bool {
        return UserDefaults.standard.bool(forKey: userDefaultsKey)
    }
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Terms of Service"
        label.font = UIFont.boldSystemFont(ofSize: 32)
        label.textAlignment = .left
        label.textColor = .darkGray
        return label
    }()
    
    private let lastUpdatedLabel: UILabel = {
        let label = UILabel()
        label.text = "Last updated on 13/03/25"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .left
        label.textColor = .gray
        return label
    }()
    
    private let textView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.font = UIFont.systemFont(ofSize: 15)
        textView.backgroundColor = .white
        textView.textColor = .darkGray
        textView.showsVerticalScrollIndicator = true
        return textView
    }()
    
    private let buttonContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    private let scrollToBottomButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Scroll to Bottom", for: .normal)
        button.backgroundColor = .white
        button.setTitleColor(.systemOrange, for: .normal)
        button.layer.cornerRadius = 15
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        return button
    }()
    
    // Add this below scrollToBottomButton in UI Components
    private let scrollToTopButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Scroll to Top", for: .normal)
        button.backgroundColor = .white
        button.setTitleColor(.systemOrange, for: .normal)
        button.layer.cornerRadius = 15
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.isHidden = true // Initially hidden
        return button
    }()
    
    private let acceptButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Accept & Continue", for: .normal)
        button.backgroundColor = .systemOrange
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 20
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.isHidden = true
        return button
    }()
    
    // MARK: - Properties
    var termsAccepted: Bool = false
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Terms and Conditions"
        
        // Check if terms have been accepted before
        if hasAcceptedTerms() {
            // Terms already accepted, navigate to main screen
            DispatchQueue.main.async {
                self.transitionToGeneralTabBarController()
            }
            return
        }
        
        setupViews()
        setupConstraints()
        loadTermsAndConditions()
        setupActions()
    }
    
    // MARK: - Setup Methods
    private func setupViews() {
        
        buttonContainerView.addSubview(scrollToTopButton)
        
        view.addSubview(containerView)
        containerView.addSubview(headerLabel)
        containerView.addSubview(lastUpdatedLabel)
        containerView.addSubview(textView)
        
        view.addSubview(buttonContainerView)
        buttonContainerView.addSubview(scrollToBottomButton)
        buttonContainerView.addSubview(acceptButton)
        
        // Add shadow to button container
        buttonContainerView.layer.shadowColor = UIColor.black.cgColor
        buttonContainerView.layer.shadowOffset = CGSize(width: 0, height: -3)
        buttonContainerView.layer.shadowOpacity = 0.1
        buttonContainerView.layer.shadowRadius = 3
    }
    
    private func setupConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        lastUpdatedLabel.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        buttonContainerView.translatesAutoresizingMaskIntoConstraints = false
        scrollToBottomButton.translatesAutoresizingMaskIntoConstraints = false
        acceptButton.translatesAutoresizingMaskIntoConstraints = false
        scrollToTopButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Container View
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: buttonContainerView.topAnchor),
            
            // Header Label
            headerLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            headerLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            headerLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Last Updated Label
            lastUpdatedLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8),
            lastUpdatedLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            lastUpdatedLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // TextView
            textView.topAnchor.constraint(equalTo: lastUpdatedLabel.bottomAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            textView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            
            // In setupConstraints(), modify the button constraints:

            // Button Container
            buttonContainerView.heightAnchor.constraint(equalToConstant: 120), // Make this taller to fit both buttons
            buttonContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            buttonContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            // Scroll To Bottom Button - position it in the center initially
            scrollToBottomButton.centerXAnchor.constraint(equalTo: buttonContainerView.centerXAnchor),
            scrollToBottomButton.centerYAnchor.constraint(equalTo: buttonContainerView.centerYAnchor),
            scrollToBottomButton.widthAnchor.constraint(equalToConstant: 150),
            scrollToBottomButton.heightAnchor.constraint(equalToConstant: 40),

            // Scroll to Top Button - position it at the top of the button container
            scrollToTopButton.centerXAnchor.constraint(equalTo: buttonContainerView.centerXAnchor),
            scrollToTopButton.topAnchor.constraint(equalTo: buttonContainerView.topAnchor, constant: 5),
            scrollToTopButton.widthAnchor.constraint(equalToConstant: 150),
            scrollToTopButton.heightAnchor.constraint(equalToConstant: 40),

            // Accept Button - position it at the bottom of the button container
            acceptButton.centerXAnchor.constraint(equalTo: buttonContainerView.centerXAnchor),
            acceptButton.bottomAnchor.constraint(equalTo: buttonContainerView.bottomAnchor, constant: -10),
            acceptButton.widthAnchor.constraint(equalToConstant: 200),
            acceptButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func loadTermsAndConditions() {
        // Load the terms and conditions content
        let termsAndConditions = """
        1.Introduction
        Welcome to our application. These terms and conditions outline the rules and regulations for the use of our application.
        
        2.Intellectual Property Rights
        Other than the content you own, under these terms, we own all the intellectual property rights and materials contained in this application.
        
        3.Restrictions
        You are specifically restricted from all of the following:
        - Publishing any material in any other media without our consent.
        - Using this application in any way that is or may be damaging to this application.
        
        4.Your Content
        In these terms and conditions, "Your Content" shall mean any audio, video text, images or other material you choose to display in this application. By displaying Your Content, you grant us a non-exclusive, worldwide irrevocable, sub-licensable license to use, reproduce, adapt, publish, translate and distribute it in any and all media.
        
        5.No Warranties
        This application is provided "as is," with all faults, and we express no representations or warranties, of any kind related to this application or the materials contained on this application.
        
        6.Limitation of Liability
        In no event shall we, nor any of our officers, directors and employees, be held liable for anything arising out of or in any way connected with your use of this application.
        
        7.Indemnification
        You hereby indemnify to the fullest extent us from and against any and all liabilities, costs, demands, causes of action, damages and expenses arising in any way related to your breach of any of the provisions of these terms.
        
        8.Severability
        If any provision of these terms is found to be invalid under any applicable law, such provisions shall be deleted without affecting the remaining provisions herein.
        
        9.Variation of Terms
        We are permitted to revise these terms at any time as we see fit, and by using this application you are expected to review these terms on a regular basis.
        
        10.Assignment
        We are allowed to assign, transfer, and subcontract its rights and/or obligations under these terms without any notification. However, you are not allowed to assign, transfer, or subcontract any of your rights and/or obligations under these terms.
        
        11.Entire Agreement
        These terms constitute the entire agreement between us and you in relation to your use of this application and supersede all prior agreements and understandings.
        
        12.Governing Law & Jurisdiction
        These terms will be governed by and interpreted in accordance with the laws of the State, and you submit to the non-exclusive jurisdiction of the state and federal courts located in the State for the resolution of any disputes.
        """
        textView.text = termsAndConditions
    }
    
    private func setupActions() {
        scrollToTopButton.addTarget(self, action: #selector(handleScrollToTop), for: .touchUpInside)
        scrollToBottomButton.addTarget(self, action: #selector(handleScrollToBottom), for: .touchUpInside)
        acceptButton.addTarget(self, action: #selector(handleAcceptTerms), for: .touchUpInside)
        textView.delegate = self
        
        
    }
    
    // MARK: - Navigation
    private func transitionToGeneralTabBarController() {
        let window = UIApplication.shared.windows.first { $0.isKeyWindow }
        window?.rootViewController = GeneralTabbarController()
        UIView.transition(with: window!, duration: 0.5, options: .transitionCrossDissolve, animations: {}, completion: nil)
    }
    
    // MARK: - Actions
    @objc private func handleScrollToBottom() {
        // Calculate the bottom offset more precisely
        DispatchQueue.main.async {
            let bottomOffset = CGPoint(x: 0, y: max(0, self.textView.contentSize.height - self.textView.bounds.height + self.textView.contentInset.bottom))
            self.textView.setContentOffset(bottomOffset, animated: true)
            
            // Set a delay to ensure we've reached the bottom before showing buttons
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // Show both accept button and scroll to top button, hide scroll to bottom
                self.scrollToBottomButton.isHidden = true
                self.acceptButton.isHidden = false
                self.scrollToTopButton.isHidden = false
            }
        }
    }
    
    //    @objc private func handleScrollToTop() {
    //        textView.setContentOffset(.zero, animated: true)
    //
    //        // Hide scroll to top and show scroll to bottom
    //        scrollToTopButton.isHidden = true
    //        scrollToBottomButton.isHidden = false
    //    }
    //    @objc private func handleScrollToTop() {
    //        textView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    //
    //        // Hide scroll to top and show scroll to bottom
    //        scrollToTopButton.isHidden = true
    //        scrollToBottomButton.isHidden = false
    //    }
    @objc private func handleScrollToTop() {
        DispatchQueue.main.async {
            let topOffset = CGPoint(x: 0, y: -self.textView.contentInset.top)
            self.textView.setContentOffset(topOffset, animated: true)
            
            // After scrolling to top, revert to initial state
            self.scrollToBottomButton.isHidden = false
            self.acceptButton.isHidden = true
            self.scrollToTopButton.isHidden = true
        }
    }
    
    
    // Modify the handleAcceptTerms method
    @objc private func handleAcceptTerms() {
        // Save that terms have been accepted
        UserDefaults.standard.set(true, forKey: userDefaultsKey)
        
        // Navigate to the GeneralTabBarController
        transitionToGeneralTabBarController()
    }
}

// MARK: - UITextViewDelegate
extension TermsAndConditionsViewController: UITextViewDelegate {
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        let bottomOffset = scrollView.contentSize.height - scrollView.bounds.height
//        let currentOffset = scrollView.contentOffset.y
//
//        // If user has scrolled to near bottom
//        if currentOffset >= bottomOffset - 20 {
//            scrollToBottomButton.isHidden = true
//            acceptButton.isHidden = false
//        } else if acceptButton.isHidden == false && (scrollToBottomButton.isHidden == true) {
//            // Only show scroll to bottom if user hasn't already seen the end
//            // Once they've seen the end, keep showing the accept button
//        } else {
//            scrollToBottomButton.isHidden = false
//            acceptButton.isHidden = true
//        }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let bottomOffset = scrollView.contentSize.height - scrollView.bounds.height
        let currentOffset = scrollView.contentOffset.y
        
        // If user has scrolled to the bottom
        if currentOffset >= bottomOffset - 20 {
            // If we're at the bottom and the scroll to bottom button is visible, hide it and show the others
            if !scrollToBottomButton.isHidden {
                scrollToBottomButton.isHidden = true
                acceptButton.isHidden = false
                scrollToTopButton.isHidden = false
            }
        }
        // If user has manually scrolled away from the bottom, show scroll to bottom and hide others
        else if currentOffset < bottomOffset - 50 && scrollToBottomButton.isHidden {
            scrollToBottomButton.isHidden = false
            acceptButton.isHidden = true
            scrollToTopButton.isHidden = true
        }
    }
    
}



#Preview {
    TermsAndConditionsViewController()
}
