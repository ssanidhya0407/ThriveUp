import UIKit
import Firebase

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = KeyWindow(windowScene: windowScene)
        self.window = window

        // Check if this is the first launch
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        
        if !hasSeenOnboarding {
            // First-time user - show onboarding
            window.rootViewController = UINavigationController(rootViewController: iOSOnboardingViewController())
        } else {
            // Returning user - show splash screen
            window.rootViewController = UINavigationController(rootViewController: SplashViewController())
        }
        
        window.makeKeyAndVisible()
        
        // Add global tap gesture recognizer to dismiss keyboard
        addGlobalTapGesture()
    }
    
    private func addGlobalTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        window?.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        window?.endEditing(true)
    }

    // Rest of your SceneDelegate methods remain unchanged
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
    }
}
