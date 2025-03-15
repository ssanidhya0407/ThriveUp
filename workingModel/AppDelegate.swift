import UIKit
import Firebase
import FirebaseFirestore
import UserNotifications
import FirebaseAuth

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        clearBookmarkedEvents()
        
        // Set up message notification service
        setupMessageNotifications(application)
        
        let userDefaults = UserDefaults.standard
        let hasLoggedInBefore = userDefaults.bool(forKey: "hasLoggedInBefore")
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        if !hasLoggedInBefore {
            // Set the flag to indicate the user has logged in before
            userDefaults.set(true, forKey: "hasLoggedInBefore")
            
            // Show the InterestsViewController
            let interestsViewController = InterestsViewController()
            let navigationController = UINavigationController(rootViewController: interestsViewController)
            window?.rootViewController = navigationController
        } else {
            // Show the main view controller
            let mainViewController = SwipeViewController()
            let navigationController = UINavigationController(rootViewController: mainViewController)
            window?.rootViewController = navigationController
        }
        
        window?.makeKeyAndVisible()
        
        // Set the global appearance for back button text color to orange
        let backButtonAppearance = UIBarButtonItem.appearance()
        backButtonAppearance.setTitleTextAttributes([.foregroundColor: UIColor.orange], for: .normal)

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}

    func clearBookmarkedEvents() {
        UserDefaults.standard.removeObject(forKey: "bookmarkedEvents1")
    }
    
    // MARK: - Notification Setup
    
    func setupMessageNotifications(_ application: UIApplication) {
        // Request notification permission
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
            
            if let error = error {
                print("Error requesting notification authorization: \(error.localizedDescription)")
            }
        }
        
        // Set notification delegate
        center.delegate = self
        
        // Start the message notification service
        // This will only start monitoring messages after user authentication
        NotificationCenter.default.addObserver(self, selector: #selector(userDidAuthenticate), name: .userDidLogin, object: nil)
    }
    
    @objc private func userDidAuthenticate() {
        // Start listening for new messages
        MessageNotificationService.shared.startListeningForNewMessages()
    }
    
    // Handle new device token for push notifications (if using push notifications)
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Convert token to string
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        
        // Save token to Firestore for this user
        if let userId = Auth.auth().currentUser?.uid {
            let db = Firestore.firestore()
            db.collection("users").document(userId).updateData([
                "deviceToken": tokenString,
                "deviceTokenUpdatedAt": FieldValue.serverTimestamp()
            ]) { error in
                if let error = error {
                    print("Error updating device token: \(error.localizedDescription)")
                } else {
                    print("Device token updated successfully")
                }
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification banner even when app is in foreground
        completionHandler([.alert, .sound, .badge])
    }
    
    // Handle user tapping on notification
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Check if this is a chat message notification
        if let chatId = userInfo["chatId"] as? String {
            // Handle navigation to the chat
            handleChatNotificationTap(chatId: chatId)
        }
        
        completionHandler()
    }
    
    private func handleChatNotificationTap(chatId: String) {
        // Find the appropriate view controller and navigate to the chat
        // This depends on your app's navigation structure
        // For example:
        /*
        if let rootViewController = window?.rootViewController as? UINavigationController,
           let tabBarController = rootViewController.viewControllers.first as? UITabBarController {
            // Switch to the messages tab
            tabBarController.selectedIndex = 2 // Assuming Messages tab is index 2
            
            // Push the specific chat view controller
            if let navigationController = tabBarController.selectedViewController as? UINavigationController {
                let chatViewController = ChatViewController(chatId: chatId)
                navigationController.pushViewController(chatViewController, animated: true)
            }
        }
        */
    }
}

// Create this notification name for user login events
extension Notification.Name {
    static let userDidLogin = Notification.Name("userDidLogin")
}
