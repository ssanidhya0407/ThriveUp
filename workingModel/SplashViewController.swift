import UIKit
import FirebaseStorage

class SplashViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let appNameLabel: UILabel = {
        let label = UILabel()
        label.text = "ThriveUp"
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 46)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let blurEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .regular)
        let view = UIVisualEffectView(effect: nil) // Start with no effect
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0
        return view
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialUI()
        loadLogoFromFirebase()
    }
    
    // MARK: - UI Setup
    
    private func setupInitialUI() {
        // Set background color
        view.backgroundColor = UIColor(hex: "#FF5900") // Darker Orange
        
        // Add logo and label directly to the view for more control
        view.addSubview(logoImageView)
        view.addSubview(appNameLabel)
        
        // Set constraints for logo and label to be precisely centered
        NSLayoutConstraint.activate([
            // Logo constraints - centered horizontally and vertically with a slight offset up
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40), // Offset up by 40 points
            logoImageView.widthAnchor.constraint(equalToConstant: 120),
            logoImageView.heightAnchor.constraint(equalToConstant: 120),
            
            // App name label constraints - centered horizontally and positioned below the logo
            appNameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            appNameLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 20)
        ])
        
        // Add blur effect view (for transition)
        view.addSubview(blurEffectView)
        NSLayoutConstraint.activate([
            blurEffectView.topAnchor.constraint(equalTo: view.topAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Firebase Image Loading
    
    private func loadLogoFromFirebase() {
        // Get a reference to the storage service
        let storage = Storage.storage()
        
        // Create a reference to the specific image path
        let logoRef = storage.reference().child("logo_images/appicon.png")
        
        // Download the image
        logoRef.getData(maxSize: 5 * 1024 * 1024) { [weak self] (data, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error downloading logo: \(error.localizedDescription)")
                // Use a placeholder or fallback image in case of error
                self.logoImageView.image = UIImage(systemName: "app.fill")
                // Continue with splash timing
                self.performSplashDelay()
                return
            }
            
            if let data = data, let image = UIImage(data: data) {
                // Set the image
                self.logoImageView.image = image
                self.performSplashDelay()
            } else {
                // Use a placeholder if the image data couldn't be converted
                self.logoImageView.image = UIImage(systemName: "app.fill")
                self.performSplashDelay()
            }
        }
    }
    
    // MARK: - Splash Delay and Transition
    
    private func performSplashDelay() {
        // Simple delay of 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.addBlurAndTransition()
        }
    }
    
    private func addBlurAndTransition() {
        // Create and apply blur effect
        let blurEffect = UIBlurEffect(style: .regular)
        
        // Animate blur effect
        UIView.animate(withDuration: 0.5, animations: {
            self.blurEffectView.effect = blurEffect
            self.blurEffectView.alpha = 1.0
        }) { _ in
            self.transitionToOnboarding()
        }
    }
    
    // MARK: - Transition
    
    private func transitionToOnboarding() {
        // Initialize the iOSOnboardingViewController
        let onboardingPageViewController = iOSOnboardingViewController()
        
        // Get the key window using modern scene-based approach
        if let windowScene = UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .compactMap({$0 as? UIWindowScene})
            .first, let window = windowScene.windows.first {
            
            // Transition to the onboarding page
            UIView.transition(with: window,
                              duration: 0.3,
                              options: .transitionCrossDissolve,
                              animations: {
                window.rootViewController = onboardingPageViewController
            }, completion: nil)
        }
    }
}

// MARK: - UIColor Extension for Hex

extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
