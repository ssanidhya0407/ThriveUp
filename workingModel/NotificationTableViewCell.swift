import UIKit

class NotificationTableViewCell: UITableViewCell {
    static let identifier = "NotificationTableViewCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .label
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .tertiaryLabel
        return label
    }()
    
    private let unreadIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 5
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, messageLabel, dateLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .leading
        
        contentView.addSubview(stackView)
        contentView.addSubview(unreadIndicator)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            unreadIndicator.heightAnchor.constraint(equalToConstant: 10),
            unreadIndicator.widthAnchor.constraint(equalToConstant: 10),
            unreadIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            unreadIndicator.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with notification: NotificationModel) {
        titleLabel.text = notification.title
        messageLabel.text = notification.message
        dateLabel.text = formatDate(notification.date)
        
        // Show unread indicator and change cell background if notification is unread
        unreadIndicator.isHidden = notification.isRead
        backgroundColor = notification.isRead ? .systemBackground : UIColor(white: 0.95, alpha: 1.0)
        
        // Make title bold if unread
        titleLabel.font = notification.isRead ? UIFont.systemFont(ofSize: 16) : UIFont.boldSystemFont(ofSize: 16)
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        // If the notification is from today, just show the time
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        
        // If the notification is from yesterday, show "Yesterday"
        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }
        
        // If the notification is from this week, show the day name
        let daysApart = calendar.dateComponents([.day], from: date, to: now).day ?? 0
        if daysApart < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // Day name
            return formatter.string(from: date)
        }
        
        // Otherwise show the date
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
