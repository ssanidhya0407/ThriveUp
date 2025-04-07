import UIKit
import Instructions
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class SwipeViewController: UIViewController, CoachMarksControllerDataSource, CoachMarksControllerDelegate {
    private var eventStack: [EventWithDeadline] = []
    private var userStack: [UserDetails] = []
    private var acceptRequests: [AcceptRequest] = []
    
    private var bookmarkedEvents: [EventWithDeadline] = []
    private let db = Firestore.firestore()

    private let cardContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // CoachMarksController instance for the guided tour
    let coachMarksController = CoachMarksController()
    let swipeButton = UIButton(type: .system)
    let filterButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemGray6

        setupTitleStackView()
        setupViews()
        setupConstraints()
        fetchEventsFromDatabase()
        fetchUsersFromDatabase()
        displayTopCards(for: .swipe)

        // Configure CoachMarksController
        coachMarksController.dataSource = self
        coachMarksController.delegate = self

        // Check if it's the user's first time logging in
        if isFirstTimeUser() {
            askForTutorial()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(showInstructions), name: NSNotification.Name("ShowInstructions"), object: nil)
    }

    @objc private func showInstructions() {
        askForTutorial()
    }

    private func setupTitleStackView() {
        // Configure swipeButton
        swipeButton.setTitle("Flick", for: .normal)
        swipeButton.setTitleColor(.orange, for: .normal)
        swipeButton.titleLabel?.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        swipeButton.addTarget(self, action: #selector(handleSwipeButtonTapped), for: .touchUpInside)
        
        // Configure filterButton
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .bold)
        filterButton.setImage(UIImage(systemName: "line.horizontal.3.decrease.circle", withConfiguration: config), for: .normal)
        filterButton.tintColor = .orange
        filterButton.addTarget(self, action: #selector(handleFilterButtonTapped), for: .touchUpInside)
        
        view.addSubview(swipeButton)
        view.addSubview(filterButton)
        
        swipeButton.translatesAutoresizingMaskIntoConstraints = false
        filterButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            swipeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            swipeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            swipeButton.heightAnchor.constraint(equalToConstant: 44),
            
            filterButton.centerYAnchor.constraint(equalTo: swipeButton.centerYAnchor),
            filterButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            filterButton.widthAnchor.constraint(equalToConstant: 44),
            filterButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func handleSwipeButtonTapped() {
        swipeButton.setTitleColor(.orange, for: .normal)
        displayTopCards(for: .swipe)
    }

    @objc private func handleFilterButtonTapped() {
        guard let userId = Auth.auth().currentUser?.uid else {
            promptUserToSignIn()
            return
        }

        let interestViewController = InterestsViewController()
        interestViewController.userID = userId
        navigationController?.pushViewController(interestViewController, animated: true)
    }

    private func promptUserToSignIn() {
        let alert = UIAlertController(title: "Sign In Required", message: "Please sign in to access your interests", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Sign In", style: .default, handler: { _ in
            // Navigate to sign-in view controller
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    private func setupViews() {
        view.addSubview(cardContainerView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            cardContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 56),
            cardContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            cardContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            cardContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
    }

    private func fetchEventsFromDatabase() {
        db.collection("events")
            .whereField("status", isEqualTo: "accepted")
            .getDocuments { [weak self] (snapshot, error) in
                if let error = error {
                    print("Error fetching events: \(error.localizedDescription)")
                    return
                }

                var fetchedEvents: [EventWithDeadline] = []

                snapshot?.documents.forEach { document in
                    let data = document.data()
                    if let category = data["category"] as? String, category != "Hackathons" {
                        do {
                            let event = try document.data(as: EventModel.self)
                            let deadlineDate = data["deadlineDate"] as? Timestamp
                            let eventWithDeadline = EventWithDeadline(
                                event: event,
                                deadlineDate: deadlineDate?.dateValue()
                            )
                            fetchedEvents.append(eventWithDeadline)
                        } catch {
                            print("Error decoding event: \(error.localizedDescription)")
                        }
                    }
                }

                self?.eventStack = fetchedEvents.reversed()
                DispatchQueue.main.async {
                    self?.displayTopCards(for: .swipe)
                }
            }
    }

    private func fetchUsersFromDatabase() {
        db.collection("users").getDocuments { [weak self] (snapshot, error) in
            if let error = error {
                print("Error fetching users: \(error.localizedDescription)")
                return
            }

            var fetchedUsers: [UserDetails] = []

            snapshot?.documents.forEach { document in
                let data = document.data()
                let id = document.documentID
                let name = data["name"] as? String ?? ""
                let description = data["Description"] as? String ?? "No Description Available"
                let imageUrl = data["profileImageURL"] as? String ?? ""
                let githubUrl = data["githubUrl"] as? String ?? "Not Available"
                let linkedinUrl = data["linkedinUrl"] as? String ?? "Not Available"
                let techStack = data["techStack"] as? String ?? "Unknown"
                let contact = data["ContactDetails"] as? String ?? "Not Available"

                let user = UserDetails(
                    id: id,
                    name: name,
                    description: description,
                    imageUrl: imageUrl,
                    contact: contact, githubUrl: githubUrl,
                    linkedinUrl: linkedinUrl,
                    techStack: techStack
                )
                
                fetchedUsers.append(user)
            }

            self?.userStack = fetchedUsers.reversed()
        }
    }

    private func displayTopCards(for category: Category) {
        cardContainerView.subviews.forEach { $0.removeFromSuperview() }

        let cards: [UIView]
        switch category {
        case .swipe:
            cards = eventStack.suffix(3).map { createCard(for: $0) }
        case .acceptRequests:
            cards = acceptRequests.suffix(3).map { createCard(for: $0) }
        }

        for cardView in cards {
            cardContainerView.addSubview(cardView)
            cardView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                cardView.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor),
                cardView.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor),
                cardView.topAnchor.constraint(equalTo: cardContainerView.topAnchor),
                cardView.bottomAnchor.constraint(equalTo: cardContainerView.bottomAnchor)
            ])

            cardContainerView.sendSubviewToBack(cardView)
        }
    }
    
    private func createCard(for eventWithDeadline: EventWithDeadline) -> UIView {
        let cardView = FlippableCardView(event: eventWithDeadline.event)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add shadow and rounded corners
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.2
        cardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        cardView.layer.shadowRadius = 8
        cardView.layer.cornerRadius = 12
        cardView.clipsToBounds = false
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        cardView.addGestureRecognizer(panGesture)

        let bookmarkButton = createButton(imageName: "bookmark.fill", tintColor: .systemOrange)
        let discardButton = createButton(imageName: "xmark", tintColor: .systemRed)

        bookmarkButton.alpha = 0
        discardButton.alpha = 0

        cardView.addSubview(bookmarkButton)
        cardView.addSubview(discardButton)

        NSLayoutConstraint.activate([
            bookmarkButton.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            bookmarkButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -40),
            bookmarkButton.widthAnchor.constraint(equalToConstant: 80),
            bookmarkButton.heightAnchor.constraint(equalToConstant: 80),

            discardButton.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            discardButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 40),
            discardButton.widthAnchor.constraint(equalToConstant: 80),
            discardButton.heightAnchor.constraint(equalToConstant: 80)
        ])

        cardView.bookmarkButton = bookmarkButton
        cardView.discardButton = discardButton

        return cardView
    }
    
    private func createCard(for request: AcceptRequest) -> UIView {
        let cardView = AcceptRequestCardView(request: request)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        return cardView
    }
        
    private func bookmarkEvent(for eventWithDeadline: EventWithDeadline) {
        bookmarkedEvents.append(eventWithDeadline)
        
        // Show confirmation popup
        let confirmationView = UIView()
        confirmationView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.9)
        confirmationView.layer.cornerRadius = 12
        confirmationView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "Event Bookmarked!"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let icon = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        icon.tintColor = .white
        icon.translatesAutoresizingMaskIntoConstraints = false
        
        confirmationView.addSubview(label)
        confirmationView.addSubview(icon)
        
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: confirmationView.leadingAnchor, constant: 16),
            icon.centerYAnchor.constraint(equalTo: confirmationView.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24),
            
            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: confirmationView.trailingAnchor, constant: -16),
            label.centerYAnchor.constraint(equalTo: confirmationView.centerYAnchor)
        ])
        
        view.addSubview(confirmationView)
        
        NSLayoutConstraint.activate([
            confirmationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            confirmationView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            confirmationView.heightAnchor.constraint(equalToConstant: 50),
            confirmationView.widthAnchor.constraint(equalToConstant: 250)
        ])
        
        // Animate in
        confirmationView.alpha = 0
        confirmationView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        UIView.animate(withDuration: 0.3) {
            confirmationView.alpha = 1
            confirmationView.transform = .identity
        }
        
        // Auto-dismiss after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            UIView.animate(withDuration: 0.3, animations: {
                confirmationView.alpha = 0
            }) { _ in
                confirmationView.removeFromSuperview()
            }
        }
        
        // Save the bookmarked event to Firestore
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: User not authenticated")
            return
        }
        
        let swipedEventRef = db.collection("swipedeventsdb").document()
        let swipedEventData: [String: Any] = [
            "eventId": eventWithDeadline.event.eventId,
            "userId": userId,
            "timestamp": Timestamp(),
            "eventName": eventWithDeadline.event.title ?? "Unknown Event",
            "deadlineDate": eventWithDeadline.deadlineDate ?? FieldValue.delete()
        ]
        
        swipedEventRef.setData(swipedEventData) { error in
            if let error = error {
                print("Error saving swiped event to Firestore: \(error.localizedDescription)")
            } else {
                print("Successfully saved swiped event to Firestore")
            }
        }
    }

    private func createButton(imageName: String, tintColor: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: imageName), for: .normal)
        button.tintColor = .white
        button.backgroundColor = tintColor
        button.layer.cornerRadius = 30
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.translatesAutoresizingMaskIntoConstraints = false
        button.alpha = 0
        return button
    }

    private func discardEvent(for eventWithDeadline: EventWithDeadline) {
        eventStack.removeAll { $0.event.eventId == eventWithDeadline.event.eventId }
        displayTopCards(for: .swipe)
    }

    private func animateCardOffScreen(_ cardView: FlippableCardView, toRight: Bool) {
        UIView.animate(withDuration: 0.5, animations: {
            cardView.transform = CGAffineTransform(translationX: toRight ? self.view.frame.width : -self.view.frame.width, y: 0)
            cardView.alpha = 0
        }) { _ in
            cardView.removeFromSuperview()
            if let index = self.eventStack.firstIndex(where: { $0.event.eventId == cardView.event.eventId }) {
                self.eventStack.remove(at: index)
            }
            self.displayTopCards(for: .swipe)
        }
    }

    @objc private func handleSwipe(_ gesture: UIPanGestureRecognizer) {
        guard let cardView = gesture.view as? FlippableCardView else { return }
        let translation = gesture.translation(in: view)
        let xFromCenter = translation.x

        switch gesture.state {
        case .began:
            cardView.bookmarkButton?.alpha = 0
            cardView.discardButton?.alpha = 0
        case .changed:
            cardView.transform = CGAffineTransform(translationX: xFromCenter, y: 0)
                .rotated(by: xFromCenter / 200)
            cardView.alpha = 1 - abs(xFromCenter) / view.frame.width

            if xFromCenter > 0 {
                cardView.bookmarkButton?.alpha = 1
                cardView.discardButton?.alpha = 0
            } else {
                cardView.bookmarkButton?.alpha = 0
                cardView.discardButton?.alpha = 1
            }

        case .ended:
            guard let eventWithDeadline = eventStack.first(where: { $0.event.eventId == cardView.event.eventId }) else { return }
            
            if xFromCenter > 100 {
                bookmarkEvent(for: eventWithDeadline)
                animateCardOffScreen(cardView, toRight: true)
            } else if xFromCenter < -100 {
                discardEvent(for: eventWithDeadline)
                animateCardOffScreen(cardView, toRight: false)
            } else {
                UIView.animate(withDuration: 0.3) {
                    cardView.transform = CGAffineTransform.identity
                    cardView.alpha = 1
                    cardView.bookmarkButton?.alpha = 0
                    cardView.discardButton?.alpha = 0
                }
            }
        default:
            UIView.animate(withDuration: 0.3) {
                cardView.transform = CGAffineTransform.identity
                cardView.alpha = 1
                cardView.bookmarkButton?.alpha = 0
                cardView.discardButton?.alpha = 0
            }
        }
    }

    private func isFirstTimeUser() -> Bool {
        return false
    }

    private func askForTutorial() {
        let alert = UIAlertController(title: "Welcome!", message: "Would you like to take a quick tour of the app?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
            self.startGuidedTour()
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func startGuidedTour() {
        coachMarksController.start(in: .window(over: self))
    }

    // MARK: - CoachMarksControllerDataSource

    func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
        return 3
    }

    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkAt index: Int) -> CoachMark {
        switch index {
        case 0:
            return coachMarksController.helper.makeCoachMark(for: swipeButton)
        case 1:
            return coachMarksController.helper.makeCoachMark(for: filterButton)
        default:
            return coachMarksController.helper.makeCoachMark()
        }
    }

    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkViewsAt index: Int, madeFrom coachMark: CoachMark) -> (bodyView: UIView & CoachMarkBodyView, arrowView: (UIView & CoachMarkArrowView)?) {
        let hintText: String
        switch index {
        case 0:
            hintText = "Tap here to swipe through events."
        case 1:
            hintText = "Tap here to filter your interests."
        default:
            hintText = ""
        }

        let coachViews = coachMarksController.helper.makeDefaultCoachViews(withArrow: true, arrowOrientation: coachMark.arrowOrientation)
        coachViews.bodyView.hintLabel.text = hintText
        coachViews.bodyView.nextLabel.text = "Next"

        return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
    }
}

enum Category {
    case swipe
    case acceptRequests
}

struct EventWithDeadline {
    let event: EventModel
    let deadlineDate: Date?
}

#Preview {
    SwipeViewController()
}
