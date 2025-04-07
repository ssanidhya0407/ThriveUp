import UIKit
import Kingfisher

class NotificationTableViewCell: UITableViewCell {
    static let identifier = "NotificationTableViewCell"
    
    // UI Components
    private let containerView = UIView()
    private let profileImageView = UIImageView()
    private let contentStackView = UIStackView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let dateLabel = UILabel()
    private let iconContainerView = UIView()
    private let notificationIconView = UIImageView()
    private let unreadIndicator = UIView()
    private let eventInfoView = UIView()
    private let eventImageView = UIImageView()
    private let eventNameLabel = UILabel()
    
    // For animation
    private var hasAppeared = false
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear
        
        // Container view setup
        containerView.backgroundColor = .secondarySystemBackground
        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // Add subtle shadow to container
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 5
        contentView.layer.shadowOpacity = 0.1
        contentView.layer.masksToBounds = false
        
        // Profile image setup
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 22
        profileImageView.backgroundColor = .systemGray6
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(profileImageView)
        
        // Unread indicator
        unreadIndicator.backgroundColor = .systemBlue
        unreadIndicator.layer.cornerRadius = 4
        unreadIndicator.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(unreadIndicator)
        
        // Content stack view
        contentStackView.axis = .vertical
        contentStackView.spacing = 4
        contentStackView.alignment = .leading
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentStackView)
        
        // Title label
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0
        contentStackView.addArrangedSubview(titleLabel)
        
        // Message label
        messageLabel.font = UIFont.systemFont(ofSize: 14)
        messageLabel.textColor = .secondaryLabel
        messageLabel.numberOfLines = 2
        contentStackView.addArrangedSubview(messageLabel)
        
        // Date label
        dateLabel.font = UIFont.systemFont(ofSize: 12)
        dateLabel.textColor = .tertiaryLabel
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(dateLabel)
        
        // Icon container
        iconContainerView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        iconContainerView.layer.cornerRadius = 16
        iconContainerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconContainerView)
        
        // Notification icon
        notificationIconView.contentMode = .scaleAspectFit
        notificationIconView.tintColor = .systemBlue
        notificationIconView.translatesAutoresizingMaskIntoConstraints = false
        iconContainerView.addSubview(notificationIconView)
        
        // Event info view - only shown for event notifications
        eventInfoView.backgroundColor = UIColor.systemGray6
        eventInfoView.layer.cornerRadius = 8
        eventInfoView.isHidden = true
        eventInfoView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(eventInfoView)
        
        // Event image
        eventImageView.contentMode = .scaleAspectFill
        eventImageView.clipsToBounds = true
        eventImageView.layer.cornerRadius = 6
        eventImageView.backgroundColor = .systemGray5
        eventImageView.translatesAutoresizingMaskIntoConstraints = false
        eventInfoView.addSubview(eventImageView)
        
        // Event name
        eventNameLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        eventNameLabel.textColor = .secondaryLabel
        eventNameLabel.numberOfLines = 1
        eventNameLabel.translatesAutoresizingMaskIntoConstraints = false
        eventInfoView.addSubview(eventNameLabel)
        
        NSLayoutConstraint.activate([
            // Container constraints
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            // Profile image constraints
            profileImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 14),
            profileImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 14),
            profileImageView.widthAnchor.constraint(equalToConstant: 44),
            profileImageView.heightAnchor.constraint(equalToConstant: 44),
            
            // Unread indicator
            unreadIndicator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 5),
            unreadIndicator.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 14),
            unreadIndicator.widthAnchor.constraint(equalToConstant: 8),
            unreadIndicator.heightAnchor.constraint(equalToConstant: 8),
            
            // Content stack view constraints
            contentStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 14),
            contentStackView.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 14),
            contentStackView.trailingAnchor.constraint(lessThanOrEqualTo: iconContainerView.leadingAnchor, constant: -8),
            
            // Date label constraints
            dateLabel.topAnchor.constraint(equalTo: contentStackView.bottomAnchor, constant: 6),
            dateLabel.leadingAnchor.constraint(equalTo: contentStackView.leadingAnchor),
            
            // Icon container constraints
            iconContainerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 14),
            iconContainerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),
            iconContainerView.widthAnchor.constraint(equalToConstant: 32),
            iconContainerView.heightAnchor.constraint(equalToConstant: 32),
            
            // Notification icon constraints
            notificationIconView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            notificationIconView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            notificationIconView.widthAnchor.constraint(equalToConstant: 16),
            notificationIconView.heightAnchor.constraint(equalToConstant: 16),
            
            // Event info view constraints
            eventInfoView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8),
            eventInfoView.leadingAnchor.constraint(equalTo: contentStackView.leadingAnchor),
            eventInfoView.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -14),
            eventInfoView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -14),
            eventInfoView.heightAnchor.constraint(equalToConstant: 36),
            
            // Event image constraints
            eventImageView.leadingAnchor.constraint(equalTo: eventInfoView.leadingAnchor, constant: 6),
            eventImageView.centerYAnchor.constraint(equalTo: eventInfoView.centerYAnchor),
            eventImageView.widthAnchor.constraint(equalToConstant: 24),
            eventImageView.heightAnchor.constraint(equalToConstant: 24),
            
            // Event name constraints
            eventNameLabel.leadingAnchor.constraint(equalTo: eventImageView.trailingAnchor, constant: 8),
            eventNameLabel.trailingAnchor.constraint(equalTo: eventInfoView.trailingAnchor, constant: -8),
            eventNameLabel.centerYAnchor.constraint(equalTo: eventInfoView.centerYAnchor),
        ])
    }
    
    func configure(with notification: NotificationModel) {
        titleLabel.text = notification.title
        messageLabel.text = notification.message
        dateLabel.text = formatDate(notification.date)
        
        // Show unread indicator and appearance if notification is unread
        unreadIndicator.isHidden = notification.isRead
        
        // Bold title for unread notifications
        titleLabel.font = notification.isRead ?
            UIFont.systemFont(ofSize: 16, weight: .medium) :
            UIFont.systemFont(ofSize: 16, weight: .bold)
        
        // Subtle visual distinction for read/unread
        containerView.backgroundColor = notification.isRead ?
            .secondarySystemBackground :
            UIColor.systemGray6.withAlphaComponent(0.8)
            
        // Load profile image
        if let imageUrlString = notification.imageUrl, let url = URL(string: imageUrlString) {
            profileImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "person.circle.fill"),
                options: [.transition(.fade(0.2))]
            )
        } else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
            profileImageView.tintColor = .systemGray3
        }
        
        // Set appropriate icon and event info based on notification type
        switch notification.type {
        case "event":
            notificationIconView.image = UIImage(systemName: "calendar")
            notificationIconView.tintColor = .systemBlue
            iconContainerView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
            
            // Show event info if available
            if let eventId = notification.eventId, let eventName = notification.title.components(separatedBy: " is going to an event!").first {
                eventInfoView.isHidden = false
                eventNameLabel.text = eventName
                
                // Load event image if available
                if let eventImageUrl = notification.eventImageName, let url = URL(string: eventImageUrl) {
                    eventImageView.kf.setImage(
                        with: url,
                        placeholder: UIImage(systemName: "calendar"),
                        options: [.transition(.fade(0.2))]
                    )
                } else {
                    eventImageView.image = UIImage(systemName: "calendar")
                    eventImageView.tintColor = .systemBlue
                }
            } else {
                eventInfoView.isHidden = true
            }
            
        case "chat":
            notificationIconView.image = UIImage(systemName: "bubble.left.fill")
            notificationIconView.tintColor = .systemGreen
            iconContainerView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
            eventInfoView.isHidden = true
            
        case "friend_request":
            notificationIconView.image = UIImage(systemName: "person.badge.plus")
            notificationIconView.tintColor = .systemIndigo
            iconContainerView.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.1)
            eventInfoView.isHidden = true
            
        case "group_invite":
            notificationIconView.image = UIImage(systemName: "person.3.fill")
            notificationIconView.tintColor = .systemOrange
            iconContainerView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.1)
            eventInfoView.isHidden = true
            
        default:
            notificationIconView.image = UIImage(systemName: "bell.fill")
            notificationIconView.tintColor = .systemGray
            iconContainerView.backgroundColor = UIColor.systemGray.withAlphaComponent(0.1)
            eventInfoView.isHidden = true
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        // Format as "10 January 2025" as requested
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMMM yyyy" // This will show as "10 January 2025"
        
        // If the notification is from today, show "Today" and time
        if calendar.isDateInToday(date) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            return "Today at " + timeFormatter.string(from: date)
        }
        
        // If the notification is from yesterday, show "Yesterday" and time
        if calendar.isDateInYesterday(date) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            return "Yesterday at " + timeFormatter.string(from: date)
        }
        
        // Otherwise show date in the requested format
        return dateFormatter.string(from: date)
    }
    
    // Add a nice press animation
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        UIView.animate(withDuration: 0.2) {
            self.containerView.transform = highlighted ?
                CGAffineTransform(scaleX: 0.98, y: 0.98) :
                .identity
            self.containerView.alpha = highlighted ? 0.9 : 1.0
        }
    }
    
    // Animate when cell appears
    func animateAppearance(at indexPath: IndexPath) {
        if !hasAppeared {
            // Initial state
            self.alpha = 0
            self.transform = CGAffineTransform(translationX: 20, y: 0)
            
            // Animate with a delay based on index path
            UIView.animate(withDuration: 0.5, delay: Double(indexPath.row) * 0.1, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.7, options: .curveEaseOut) {
                self.alpha = 1
                self.transform = .identity
            }
            
            hasAppeared = true
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        profileImageView.image = nil
        eventImageView.image = nil
        titleLabel.text = nil
        messageLabel.text = nil
        dateLabel.text = nil
        eventNameLabel.text = nil
        unreadIndicator.isHidden = true
        eventInfoView.isHidden = true
        hasAppeared = false
    }
}

// Extension to handle the animated appearance in the table view
extension UITableView {
    func animateCells() {
        self.reloadData()
        
        let cells = self.visibleCells as! [NotificationTableViewCell]
        let tableViewHeight = self.bounds.size.height
        
        for (index, cell) in cells.enumerated() {
            cell.animateAppearance(at: IndexPath(row: index, section: 0))
        }
    }
}
