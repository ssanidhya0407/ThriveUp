import UIKit
import FirebaseStorage

class EventCell: UICollectionViewCell {
    static let identifier = "EventCell"
    
    // Image cache to prevent repeated downloads
    private static let imageCache = NSCache<NSString, UIImage>()
    
    private let eventImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = UIColor(white: 0.95, alpha: 1.0) // Light gray placeholder
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .gray
        return label
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.color = .darkGray
        return indicator
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(eventImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(activityIndicator)
        
        // Set up constraints
        eventImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            eventImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            eventImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            eventImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            eventImageView.heightAnchor.constraint(equalToConstant: 120),
            
            titleLabel.topAnchor.constraint(equalTo: eventImageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            
            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            dateLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            activityIndicator.centerXAnchor.constraint(equalTo: eventImageView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: eventImageView.centerYAnchor)
        ])
        
        contentView.layer.cornerRadius = 10
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.1
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 4
        contentView.layer.masksToBounds = false
        contentView.backgroundColor = .white
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        eventImageView.image = nil
        titleLabel.text = nil
        dateLabel.text = nil
        activityIndicator.startAnimating()
    }
    
    func configure(with event: EventModel) {
        // Set title and date first
        titleLabel.text = event.title
        dateLabel.text = event.date
        
        // Handle image loading
        loadImage(from: event.imageName)
    }
    
    private func loadImage(from imageUrlString: String) {
        // Show activity indicator while loading
        activityIndicator.startAnimating()
        
        // Check if image is empty or doesn't have a valid URL
        if imageUrlString.isEmpty || !imageUrlString.hasPrefix("http") {
            // Use placeholder image
            eventImageView.image = UIImage(named: "placeholder")
            activityIndicator.stopAnimating()
            return
        }
        
        // Check if image is in cache
        if let cachedImage = EventCell.imageCache.object(forKey: imageUrlString as NSString) {
            eventImageView.image = cachedImage
            activityIndicator.stopAnimating()
            return
        }
        
        // If URL is Firebase Storage URL, use Firebase Storage
        if imageUrlString.contains("firebasestorage.googleapis.com") {
            let storageRef = Storage.storage().reference(forURL: imageUrlString)
            
            storageRef.getData(maxSize: 5 * 1024 * 1024) { [weak self] data, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error downloading image: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.eventImageView.image = UIImage(named: "placeholder")
                        self.activityIndicator.stopAnimating()
                    }
                    return
                }
                
                guard let data = data, let image = UIImage(data: data) else {
                    DispatchQueue.main.async {
                        self.eventImageView.image = UIImage(named: "placeholder")
                        self.activityIndicator.stopAnimating()
                    }
                    return
                }
                
                // Cache the image
                EventCell.imageCache.setObject(image, forKey: imageUrlString as NSString)
                
                DispatchQueue.main.async {
                    // Fade in the image
                    UIView.transition(with: self.eventImageView, duration: 0.3, options: .transitionCrossDissolve, animations: {
                        self.eventImageView.image = image
                    }, completion: nil)
                    self.activityIndicator.stopAnimating()
                }
            }
        } else {
            // For regular URLs, use URLSession
            guard let url = URL(string: imageUrlString) else {
                eventImageView.image = UIImage(named: "placeholder")
                activityIndicator.stopAnimating()
                return
            }
            
            URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error downloading image: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.eventImageView.image = UIImage(named: "placeholder")
                        self.activityIndicator.stopAnimating()
                    }
                    return
                }
                
                guard let data = data, let image = UIImage(data: data) else {
                    DispatchQueue.main.async {
                        self.eventImageView.image = UIImage(named: "placeholder")
                        self.activityIndicator.stopAnimating()
                    }
                    return
                }
                
                // Cache the image
                EventCell.imageCache.setObject(image, forKey: imageUrlString as NSString)
                
                DispatchQueue.main.async {
                    // Fade in the image
                    UIView.transition(with: self.eventImageView, duration: 0.3, options: .transitionCrossDissolve, animations: {
                        self.eventImageView.image = image
                    }, completion: nil)
                    self.activityIndicator.stopAnimating()
                }
            }.resume()
        }
    }
}
