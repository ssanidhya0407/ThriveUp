import UIKit

class FriendCell: UITableViewCell {
    static let identifier = "FriendCell"

//    private let profileImageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.contentMode = .scaleAspectFill
//        imageView.layer.cornerRadius = 25
//        imageView.clipsToBounds = true
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        return imageView
//    }()
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 25 // Set the radius immediately (half of your 50x50 size)
        imageView.layer.masksToBounds = true // Ensure this is true
        imageView.layer.borderWidth = 1 // Optional: add a border
        imageView.layer.borderColor = UIColor.lightGray.cgColor // Optional: border color
        return imageView
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let messageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Message", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemOrange // ✅ Changed to orange
        button.layer.cornerRadius = 10
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .white
        contentView.backgroundColor = .white

        contentView.addSubview(profileImageView)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(messageButton)

        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 50),
            profileImageView.heightAnchor.constraint(equalToConstant: 50),

            usernameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            usernameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            usernameLabel.trailingAnchor.constraint(lessThanOrEqualTo: messageButton.leadingAnchor, constant: -8),

            messageButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            messageButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            messageButton.widthAnchor.constraint(equalToConstant: 100),
            messageButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    func configure(with user: User) {
//        usernameLabel.text = user.name
//
//        if let profileImageUrl = user.profileImageURL, !profileImageUrl.isEmpty {
//            loadImage(from: profileImageUrl)
//        } else {
//            profileImageView.image = UIImage(named: "default_profile") // ✅ Placeholder for missing images
//        }
//    }
    
    func configure(with user: User) {
        usernameLabel.text = user.name

        if let profileImageUrl = user.profileImageURL, !profileImageUrl.isEmpty {
            loadImage(from: profileImageUrl)
        } else {
            profileImageView.image = UIImage(named: "default_profile")?.withRenderingMode(.alwaysOriginal)
            // Ensure these properties are set for the default image too
            profileImageView.layer.cornerRadius = 25
            profileImageView.layer.borderWidth = 1
            profileImageView.layer.borderColor = UIColor.lightGray.cgColor
        }
    }

//    override func layoutSubviews() {
//        super.layoutSubviews()
//        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
//    }

//    private func loadImage(from url: String) {
//        guard let imageURL = URL(string: url) else { return }
//        DispatchQueue.global().async {
//            if let data = try? Data(contentsOf: imageURL), let image = UIImage(data: data) {
//                DispatchQueue.main.async {
//                    self.profileImageView.image = image
//                }
//            }
//        }
//    }
    private func loadImage(from url: String) {
        guard let imageURL = URL(string: url) else { return }
        
        // Better approach using URLSession
        URLSession.shared.dataTask(with: imageURL) { [weak self] data, _, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error loading image: \(error.localizedDescription)")
                return
            }
            
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImageView.image = image
                    // Ensure these properties are maintained
                    self.profileImageView.layer.cornerRadius = 25
                    self.profileImageView.layer.borderWidth = 1
                    self.profileImageView.layer.borderColor = UIColor.lightGray.cgColor
                }
            }
        }.resume()
    }
}


