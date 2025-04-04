
import UIKit
import Instructions
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class SwipeViewController: UIViewController, CoachMarksControllerDataSource, CoachMarksControllerDelegate {
    private var eventStack: [EventModel] = []
    private var userStack: [UserDetails] = []
    private var acceptRequests: [AcceptRequest] = []
    
    private var bookmarkedEvents: [EventModel] = []
    private var bookmarkedUsers: [UserDetails] = []
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

        // Observe for notification to show the instructions
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

        // Stack for buttons above "HackMate"
//        let buttonStackView = UIStackView()
//        buttonStackView.axis = .horizontal
//        buttonStackView.alignment = .center
//        buttonStackView.distribution = .equalSpacing
//        buttonStackView.spacing = 16

        // Configure filterButton (use existing class variable, not a new one)
        filterButton.setImage(UIImage(systemName: "line.horizontal.3.decrease.circle"), for: .normal)
        filterButton.tintColor = .black
        filterButton.translatesAutoresizingMaskIntoConstraints = false
        filterButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
        filterButton.heightAnchor.constraint(equalToConstant: 32).isActive = true

//
//        // Add buttons to stack
//        buttonStackView.addArrangedSubview(filterButton)
     

        // Ensure buttons are properly linked to actions
        filterButton.addTarget(self, action: #selector(handleFilterButtonTapped), for: .touchUpInside)
     

        // Configure titleStackView
        // Add titleStackView to the view
        view.addSubview(swipeButton)
        view.addSubview(filterButton)
        swipeButton.translatesAutoresizingMaskIntoConstraints = false
        filterButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            swipeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            swipeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
           
            swipeButton.heightAnchor.constraint(equalToConstant: 40),

            filterButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            filterButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
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

                var fetchedEvents: [EventModel] = []

                snapshot?.documents.forEach { document in
                    let data = document.data()
                    if let category = data["category"] as? String, category != "Hackathons" {
                        var modifiedData = data
                        if let timestamp = data["timestamp"] as? Timestamp {
                            modifiedData["timestamp"] = timestamp.dateValue()
                        }
                        
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: modifiedData)
                            let event = try JSONDecoder().decode(EventModel.self, from: jsonData)
                            fetchedEvents.append(event)
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

    private func createCard(for event: EventModel) -> UIView {
        let cardView = FlippableCardView(event: event)
        cardView.translatesAutoresizingMaskIntoConstraints = false

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        cardView.addGestureRecognizer(panGesture)

        let bookmarkButton = createButton(imageName: "bookmark.fill", tintColor: .systemOrange)
        let discardButton = createButton(imageName: "xmark", tintColor: .systemRed)

        bookmarkButton.alpha = 0 // Initially hide the bookmark button
        discardButton.alpha = 0 // Initially hide the discard button

        cardView.addSubview(bookmarkButton)
        cardView.addSubview(discardButton)

        NSLayoutConstraint.activate([
            bookmarkButton.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            bookmarkButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            bookmarkButton.widthAnchor.constraint(equalToConstant: 60),
            bookmarkButton.heightAnchor.constraint(equalToConstant: 60),

            discardButton.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            discardButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            discardButton.widthAnchor.constraint(equalToConstant: 60),
            discardButton.heightAnchor.constraint(equalToConstant: 60)
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

    private func createButton(imageName: String, tintColor: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: imageName), for: .normal)
        button.tintColor = tintColor
        button.backgroundColor = UIColor(white: 1, alpha: 0.75)
        button.layer.cornerRadius = 30
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    private func bookmarkEvent(for event: EventModel) {
        bookmarkedEvents.append(event)
        
        // Save the bookmarked event to Firestore
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: User not authenticated")
            return
        }
        
        let swipedEventRef = db.collection("swipedeventsdb").document()
        let swipedEventData: [String: Any] = [
            "eventId": event.eventId,
            "userId": userId,
            "timestamp": Timestamp(),
            "eventName": event.title ?? "Unknown Event"
        ]
        
        swipedEventRef.setData(swipedEventData) { error in
            if let error = error {
                print("Error saving swiped event to Firestore: \(error.localizedDescription)")
            } else {
                print("Successfully saved swiped event to Firestore")
            }
        }
    }

    private func discardEvent(for event: EventModel) {
        eventStack.removeAll { $0.eventId == event.eventId }
        displayTopCards(for: .swipe)
    }



    private func animateCardOffScreen(_ cardView: FlippableCardView, toRight: Bool) {
        UIView.animate(withDuration: 0.5, animations: {
            cardView.transform = CGAffineTransform(translationX: toRight ? self.view.frame.width : -self.view.frame.width, y: 0)
            cardView.alpha = 0
        }) { _ in
            cardView.removeFromSuperview()
            if let index = self.eventStack.firstIndex(of: cardView.event) {
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
            // Hide both buttons initially
            cardView.bookmarkButton?.alpha = 0
            cardView.discardButton?.alpha = 0
        case .changed:
            cardView.transform = CGAffineTransform(translationX: xFromCenter, y: 0)
                .rotated(by: xFromCenter / 200)
            cardView.alpha = 1 - abs(xFromCenter) / view.frame.width

            // Show the appropriate button based on swipe direction
            if xFromCenter > 0 {
                cardView.bookmarkButton?.alpha = 1
                cardView.discardButton?.alpha = 0
            } else {
                cardView.bookmarkButton?.alpha = 0
                cardView.discardButton?.alpha = 1
            }

        case .ended:
            if xFromCenter > 100 {
                bookmarkEvent(for: cardView.event)
                animateCardOffScreen(cardView, toRight: true)
            } else if xFromCenter < -100 {
                discardEvent(for: cardView.event)
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
        // Implement logic to check if it's the first time user
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

#Preview{
    SwipeViewController()
}
