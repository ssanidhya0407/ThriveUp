//
//  ViewControllerExtensions.swift
//  ThriveUp
//
//  Created by Sanidhya's MacBook Pro on 05/04/25.
//

import UIKit
import FirebaseAuth

// MARK: - Common Extensions for View Controllers

extension UIViewController {
    // Current user helpers
    var currentUserId: String {
        return Auth.auth().currentUser?.uid ?? ""
    }
    
    var isUserLoggedIn: Bool {
        return Auth.auth().currentUser != nil
    }
    
    // Common alert helper
    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        
        present(alert, animated: true)
    }
    
    // Loading indicator helper
    func showLoadingIndicator(message: String) -> UIAlertController {
        let alert = UIAlertController(
            title: nil,
            message: message,
            preferredStyle: .alert
        )
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        
        alert.view.addSubview(loadingIndicator)
        
        present(alert, animated: true)
        return alert
    }
    
    // Hide loading indicator
    func hideLoadingIndicator(alert: UIAlertController) {
        alert.dismiss(animated: true)
    }
}
