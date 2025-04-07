import UIKit
import Kingfisher
import FirebaseAuth
import AVFoundation

class ChatMessageCell: UITableViewCell {
    // MARK: - UI Components
    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    private let nameLabel = UILabel()
    private let timeLabel = UILabel()
    private let profileImageView = UIImageView()
    private let messageImageView = UIImageView()
    private let audioPlayButton = UIButton(type: .system)
    private let audioProgressView = UIProgressView(progressViewStyle: .default)
    
    // MARK: - Media Handling
    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?
    
    // MARK: - Constraints that need to be managed
    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!
    private var imageHeightConstraint: NSLayoutConstraint!
    private var bubbleWidthConstraint: NSLayoutConstraint!
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.text = nil
        nameLabel.text = nil
        timeLabel.text = nil
        profileImageView.image = nil
        messageImageView.image = nil
        messageImageView.isHidden = true
        messageLabel.isHidden = false
        audioPlayButton.isHidden = true
        audioProgressView.isHidden = true
        audioPlayer?.stop()
        audioPlayer = nil
        playbackTimer?.invalidate()
        playbackTimer = nil
        
        // Reset constraints
        NSLayoutConstraint.deactivate([leadingConstraint, trailingConstraint])
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        // Setup profile image
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 16
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileImageView)
        
        // Setup bubble view
        bubbleView.layer.cornerRadius = 16
        bubbleView.clipsToBounds = true
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubbleView)
        
        // Setup name label
        nameLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        nameLabel.textColor = .secondaryLabel
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(nameLabel)
        
        // Setup message label
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(messageLabel)
        
        // Setup time label
        timeLabel.font = UIFont.systemFont(ofSize: 10)
        timeLabel.textColor = .tertiaryLabel
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(timeLabel)
        
        // Setup message image view
        messageImageView.contentMode = .scaleAspectFill
        messageImageView.clipsToBounds = true
        messageImageView.layer.cornerRadius = 8
        messageImageView.isHidden = true
        messageImageView.backgroundColor = .systemGray5
        messageImageView.translatesAutoresizingMaskIntoConstraints = false
        messageImageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        messageImageView.addGestureRecognizer(tapGesture)
        bubbleView.addSubview(messageImageView)
        
        // Setup audio controls
        audioPlayButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        audioPlayButton.tintColor = .white
        audioPlayButton.isHidden = true
        audioPlayButton.translatesAutoresizingMaskIntoConstraints = false
        audioPlayButton.addTarget(self, action: #selector(toggleAudio), for: .touchUpInside)
        bubbleView.addSubview(audioPlayButton)
        
        audioProgressView.progressTintColor = .white
        audioProgressView.trackTintColor = UIColor.white.withAlphaComponent(0.3)
        audioProgressView.isHidden = true
        audioProgressView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(audioProgressView)
        
        // Set up standard constraints
        NSLayoutConstraint.activate([
            // Profile image constraints
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            profileImageView.widthAnchor.constraint(equalToConstant: 32),
            profileImageView.heightAnchor.constraint(equalToConstant: 32),
            
            // Bubble view vertical constraints
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            // Name label constraints
            nameLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            
            // Message label constraints
            messageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            
            // Time label constraints
            timeLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            timeLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8),
            
            // Message image view constraints
            messageImageView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            messageImageView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 8),
            messageImageView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -8),
            
            // Audio controls
            audioPlayButton.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            audioPlayButton.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            audioPlayButton.widthAnchor.constraint(equalToConstant: 30),
            audioPlayButton.heightAnchor.constraint(equalToConstant: 30),
            
            audioProgressView.leadingAnchor.constraint(equalTo: audioPlayButton.trailingAnchor, constant: 8),
            audioProgressView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            audioProgressView.centerYAnchor.constraint(equalTo: audioPlayButton.centerYAnchor),
            audioProgressView.heightAnchor.constraint(equalToConstant: 4)
        ])
        
        // Connection from media to time label
        NSLayoutConstraint.activate([
            timeLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 4)
        ])
        
        // Create dynamic constraints
        leadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 8)
        trailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)
        
        // Image height constraint
        imageHeightConstraint = messageImageView.heightAnchor.constraint(equalToConstant: 180)
        imageHeightConstraint.isActive = true
        
        // Width constraint for bubble
        let screenWidth = UIScreen.main.bounds.width
        let maxBubbleWidth = screenWidth * 0.65
        bubbleWidthConstraint = bubbleView.widthAnchor.constraint(equalToConstant: maxBubbleWidth)
    }
    
    // MARK: - Configuration
    func configure(with message: ChatMessage) {
        nameLabel.text = message.sender.name
        messageLabel.text = message.messageContent
        
        // Format timestamp
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        timeLabel.text = formatter.string(from: message.timestamp)
        
        // Set profile image
        if let urlString = message.sender.profileImageURL, let url = URL(string: urlString) {
            profileImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "person.circle"),
                options: [
                    .transition(.fade(0.2)),
                    .cacheOriginalImage
                ]
            )
        } else {
            profileImageView.image = UIImage(systemName: "person.circle")
        }
        
        // Reset media views visibility
        messageLabel.isHidden = false
        messageImageView.isHidden = true
        audioPlayButton.isHidden = true
        audioProgressView.isHidden = true
        
        // Handle media content
        if let mediaURL = message.mediaURL, !mediaURL.isEmpty {
            if message.messageContent.contains("[Voice Message]") {
                // It's a voice message
                setupVoiceMessage(url: mediaURL)
            } else if message.messageContent.contains("Sent a photo") || message.messageContent.contains("[Image]") {
                // It's an image
                setupImageMessage(url: mediaURL)
            }
            // Can handle video and other types similarly
        }
        
        // Remove previous constraints
        NSLayoutConstraint.deactivate([leadingConstraint, trailingConstraint, bubbleWidthConstraint])
        
        // Set bubble style based on sender
        if message.isSender {
            // Current user's message (right aligned)
            bubbleView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.9)
            messageLabel.textColor = .white
            nameLabel.textColor = UIColor.white.withAlphaComponent(0.8)
            timeLabel.textColor = UIColor.white.withAlphaComponent(0.6)
            profileImageView.isHidden = true
            
            // Apply right alignment
            trailingConstraint.isActive = true
            bubbleWidthConstraint.isActive = true
            timeLabel.textAlignment = .right
            
        } else {
            // Other user's message (left aligned)
            bubbleView.backgroundColor = UIColor.systemGray6
            messageLabel.textColor = .label
            nameLabel.textColor = .secondaryLabel
            timeLabel.textColor = .tertiaryLabel
            profileImageView.isHidden = false
            
            // Apply left alignment
            leadingConstraint.isActive = true
            bubbleWidthConstraint.isActive = true
            timeLabel.textAlignment = .left
        }
        
        layoutIfNeeded()
    }
    
    // MARK: - Media Handling
    private func setupImageMessage(url: String) {
        guard let imageURL = URL(string: url) else { return }
        
        messageImageView.isHidden = false
        messageLabel.isHidden = true
        imageHeightConstraint.constant = 200
        
        // Update constraints to connect time label to image
        timeLabel.topAnchor.constraint(equalTo: messageImageView.bottomAnchor, constant: 4).isActive = true
        
        messageImageView.kf.setImage(
            with: imageURL,
            placeholder: UIImage(systemName: "photo"),
            options: [
                .transition(.fade(0.3)),
                .processor(DownsamplingImageProcessor(size: CGSize(width: 300, height: 300))),
                .scaleFactor(UIScreen.main.scale),
                .cacheOriginalImage
            ],
            completionHandler: { result in
                switch result {
                case .success:
                    break
                case .failure:
                    self.messageImageView.image = UIImage(systemName: "exclamationmark.triangle")
                }
            }
        )
    }
    
    private func setupVoiceMessage(url: String) {
        guard let audioURL = URL(string: url) else { return }
        
        messageLabel.isHidden = true
        audioPlayButton.isHidden = false
        audioProgressView.isHidden = false
        audioProgressView.progress = 0
        
        // Update time label connection for audio
        timeLabel.topAnchor.constraint(equalTo: audioPlayButton.bottomAnchor, constant: 8).isActive = true
        
        // Pre-load audio
        URLSession.shared.dataTask(with: audioURL) { data, _, error in
            guard let data = data, error == nil else { return }
            
            DispatchQueue.main.async {
                do {
                    self.audioPlayer = try AVAudioPlayer(data: data)
                    self.audioPlayer?.prepareToPlay()
                } catch {
                    print("Failed to initialize audio player: \(error)")
                }
            }
        }.resume()
    }
    
    @objc private func toggleAudio() {
        guard let player = audioPlayer else { return }
        
        if player.isPlaying {
            // Pause
            player.pause()
            audioPlayButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            playbackTimer?.invalidate()
            playbackTimer = nil
        } else {
            // Play
            player.play()
            audioPlayButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            
            // Set up timer to update progress
            playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self, let player = self.audioPlayer else { return }
                self.audioProgressView.progress = Float(player.currentTime / player.duration)
                
                if player.currentTime >= player.duration {
                    self.audioPlayButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
                    self.playbackTimer?.invalidate()
                    self.playbackTimer = nil
                }
            }
        }
    }
    
    @objc private func imageTapped() {
        // Can be implemented to show full screen image
        NotificationCenter.default.post(name: NSNotification.Name("ChatMessageImageTapped"), object: self)
    }
}
