import UIKit
import FirebaseFirestore

class FriendRequestsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UISearchBarDelegate, UICollectionViewDelegateFlowLayout {
    
    // MARK: - Properties
    var currentUser: User?
    var friendRequests: [FriendRequest] = []
    var users: [User] = []
    var filteredUsers: [User] = []
    var userCache: [String: User] = [:]
    private var searchTimer: Timer?

    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search users"
        searchBar.backgroundImage = UIImage()
        searchBar.searchBarStyle = .minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        return searchBar
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        tableView.showsVerticalScrollIndicator = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private let firstRowCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 150, height: 200)
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .white
        return collectionView
    }()
    
    private let secondRowCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 150, height: 200)
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .white
        return collectionView
    }()
    
    private let noResultsLabel: UILabel = {
        let label = UILabel()
        label.text = "No users found"
        label.textColor = .gray
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let addedMeLabel: UILabel = {
        let label = UILabel()
        label.text = "Added Me"
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let quickAddLabel: UILabel = {
        let label = UILabel()
        label.text = "Quick Add"
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Add Friends"
        
        // 1. First setup scroll view and content view
        setupScrollView()
        
        // 2. Then add all other components to contentView
        setupSearchBar()
        setupTableView()       // This now adds both label and table view
        setupQuickAddLabel()   // Separate method for quickAddLabel
        setupCollectionViews()
       
        
        fetchFriendRequests()
        fetchUsersExcludingFriendsAndRequests()
    }

    private func setupQuickAddLabel() {
        contentView.addSubview(quickAddLabel)
        NSLayoutConstraint.activate([
            quickAddLabel.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 16),
            quickAddLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        ])
    }
    
    // MARK: - Setup Methods
    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupSearchBar() {
        searchBar.delegate = self
        contentView.addSubview(searchBar)
        
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.systemOrange, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelSearch), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -80),
            searchBar.heightAnchor.constraint(equalToConstant: 40),
            
            cancelButton.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    private func setupLabels() {
        contentView.addSubview(addedMeLabel)
        contentView.addSubview(quickAddLabel)
        contentView.addSubview(noResultsLabel)
        
        NSLayoutConstraint.activate([
            addedMeLabel.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 12),
            addedMeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            quickAddLabel.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 16),
            quickAddLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            noResultsLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            noResultsLabel.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 20)
        ])
    }
    
    private func setupTableView() {
        // First add the label and table view to the contentView
        contentView.addSubview(addedMeLabel)
        contentView.addSubview(tableView)
        
        // Then set up constraints between them
        NSLayoutConstraint.activate([
            addedMeLabel.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 12),
            addedMeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            tableView.topAnchor.constraint(equalTo: addedMeLabel.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableView.heightAnchor.constraint(equalToConstant: 250)
        ])
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(FriendRequestCell.self, forCellReuseIdentifier: "FriendRequestCell")
    }
    
    private func setupCollectionViews() {
        firstRowCollectionView.dataSource = self
        firstRowCollectionView.delegate = self
        firstRowCollectionView.register(QuickAddCell.self, forCellWithReuseIdentifier: QuickAddCell.identifier)
        
        
        secondRowCollectionView.dataSource = self
        secondRowCollectionView.delegate = self
        secondRowCollectionView.register(QuickAddCell.self, forCellWithReuseIdentifier: QuickAddCell.identifier)
        contentView.addSubview(secondRowCollectionView)
        contentView.addSubview(firstRowCollectionView)
        
        let collectionViewHeight: CGFloat = 220
        
        NSLayoutConstraint.activate([
            firstRowCollectionView.topAnchor.constraint(equalTo: secondRowCollectionView.bottomAnchor, constant: 12),
            firstRowCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            firstRowCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            firstRowCollectionView.heightAnchor.constraint(equalToConstant: collectionViewHeight),
            
            secondRowCollectionView.topAnchor.constraint(equalTo: quickAddLabel.bottomAnchor, constant: 20),
            secondRowCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            secondRowCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            secondRowCollectionView.heightAnchor.constraint(equalToConstant: collectionViewHeight),
            
            contentView.bottomAnchor.constraint(equalTo: firstRowCollectionView.bottomAnchor, constant: 20)
        ])
    }
    
    // MARK: - Data Methods
    private func fetchData() {
        fetchFriendRequests()
        fetchUsersExcludingFriendsAndRequests()
    }
    
    private func fetchFriendRequests() {
        guard let currentUser = currentUser else { return }
        FriendsService.shared.fetchFriendRequests(forUserID: currentUser.id) { [weak self] requests, error in
            if let error = error {
                print("Error fetching friend requests: \(error)")
                return
            }
            self?.friendRequests = requests ?? []
            self?.fetchUserDetailsForRequests()
        }
    }
    
    private func fetchUserDetailsForRequests() {
        let dispatchGroup = DispatchGroup()
        for request in friendRequests {
            if userCache[request.fromUserID] == nil {
                dispatchGroup.enter()
                FriendsService.shared.fetchUserDetails(uid: request.fromUserID) { [weak self] user, error in
                    if let user = user {
                        self?.userCache[request.fromUserID] = user
                    }
                    dispatchGroup.leave()
                }
            }
        }
        dispatchGroup.notify(queue: .main) {
            self.tableView.reloadData()
        }
    }
    
    private func fetchUsersExcludingFriendsAndRequests() {
        guard let currentUser = currentUser else { return }
        FriendsService.shared.fetchUsersExcludingFriendsAndRequests(currentUserID: currentUser.id) { [weak self] users, error in
            if let error = error {
                print("Error fetching users: \(error)")
                return
            }
            DispatchQueue.main.async {
                self?.users = users ?? []
                self?.filteredUsers = self?.users ?? []
                self?.firstRowCollectionView.reloadData()
                self?.secondRowCollectionView.reloadData()
            }
        }
    }
    
    // MARK: - Action Methods
    private func acceptFriendRequest(_ request: FriendRequest) {
        FriendsService.shared.acceptFriendRequest(requestID: request.id) { [weak self] success, error in
            if let error = error {
                print("Error accepting friend request: \(error)")
                return
            }
            
            self?.friendRequests.removeAll { $0.id == request.id }
            self?.tableView.reloadData()
            self?.fetchUsersExcludingFriendsAndRequests()
            
            NotificationCenter.default.post(name: NSNotification.Name("FriendAddedToChat"), object: nil)
            NotificationCenter.default.post(name: NSNotification.Name("FriendListUpdated"), object: nil)
            NotificationCenter.default.post(name: NSNotification.Name("FriendRequestUpdated"), object: nil)
        }
    }
    
    private func rejectFriendRequest(_ request: FriendRequest) {
        FriendsService.shared.removeFriendRequest(requestID: request.id) { [weak self] success, error in
            if let error = error {
                print("Error rejecting friend request: \(error)")
                return
            }
            self?.friendRequests.removeAll { $0.id == request.id }
            self?.tableView.reloadData()
        }
    }
    
    private func sendFriendRequest(to user: User) {
        guard let currentUser = currentUser else { return }
        FriendsService.shared.sendFriendRequest(fromUserID: currentUser.id, toUserID: user.id) { [weak self] success, error in
            if let error = error {
                print("Error sending friend request: \(error)")
                return
            }
            
            DispatchQueue.main.async {
                if let index = self?.filteredUsers.firstIndex(where: { $0.id == user.id }) {
                    let indexPath = IndexPath(item: index, section: 0)
                    if let cell = self?.firstRowCollectionView.cellForItem(at: indexPath) as? QuickAddCell {
                        self?.updateCellAfterRequestSent(cell: cell)
                    }
                    if let cell = self?.secondRowCollectionView.cellForItem(at: indexPath) as? QuickAddCell {
                        self?.updateCellAfterRequestSent(cell: cell)
                    }
                }
            }
        }
    }
    
    private func updateCellAfterRequestSent(cell: QuickAddCell) {
        cell.addButton.setTitle("Added", for: .normal)
        cell.addButton.backgroundColor = .lightGray
        cell.addButton.setTitleColor(.darkGray, for: .normal)
        cell.addButton.isUserInteractionEnabled = false
    }
    
    @objc private func cancelSearch() {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        filteredUsers = users
        firstRowCollectionView.reloadData()
        secondRowCollectionView.reloadData()
        noResultsLabel.isHidden = true
    }
    
    // MARK: - SearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchTimer?.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            if searchText.isEmpty {
                self.filteredUsers = self.users
            } else {
                let searchLower = searchText.lowercased()
                self.filteredUsers = self.users.filter { user in
                    return user.name.lowercased().contains(searchLower) ||
                           user.id.lowercased().contains(searchLower)
                }
            }
            
            self.firstRowCollectionView.reloadData()
            self.secondRowCollectionView.reloadData()
            self.noResultsLabel.isHidden = !self.filteredUsers.isEmpty || searchText.isEmpty
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // MARK: - TableView DataSource & Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendRequests.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FriendRequestCell", for: indexPath) as! FriendRequestCell
        let request = friendRequests[indexPath.row]
        
        if let user = userCache[request.fromUserID] {
            cell.configure(
                with: user,
                acceptAction: { [weak self] in
                    self?.acceptFriendRequest(request)
                },
                rejectAction: { [weak self] in
                    self?.rejectFriendRequest(request)
                }
            )
        }
        
        return cell
    }
    
    // MARK: - CollectionView DataSource & Delegate
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let halfCount = max(filteredUsers.count / 2, 0)
        if collectionView == firstRowCollectionView {
            return halfCount
        } else {
            return max(filteredUsers.count - halfCount, 0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: QuickAddCell.identifier, for: indexPath) as! QuickAddCell
        
        let halfCount = filteredUsers.count / 2
        guard !filteredUsers.isEmpty else { return cell }
        
        let user: User
        
        if collectionView == firstRowCollectionView, indexPath.row < halfCount {
            user = filteredUsers[indexPath.row]
        } else if collectionView == secondRowCollectionView, indexPath.row < filteredUsers.count - halfCount {
            user = filteredUsers[halfCount + indexPath.row]
        } else {
            return cell
        }
        
        cell.configure(with: user, addAction: {
            self.sendFriendRequest(to: user)
        })
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfColumns: CGFloat = 2
        let spacing: CGFloat = 12
        let totalSpacing = (numberOfColumns - 1) * spacing
        let availableWidth = collectionView.frame.width - totalSpacing
        let width = availableWidth / numberOfColumns
        let height: CGFloat = 180
        
        return CGSize(width: width, height: height)
    }
}
