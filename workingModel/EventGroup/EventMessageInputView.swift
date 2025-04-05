//
//  EventMessageInputView.swift
//  ThriveUp
//
//  Created by Sanidhya's MacBook Pro on 05/04/25.
//

import UIKit

// Renamed protocol to avoid conflicts
protocol EventMessageInputViewDelegate: AnyObject {
    func didTapSend(text: String)
    func didTapAttachment()
}

// Renamed class to avoid conflicts
class EventMessageInputView: UIView {
    // MARK: - UI Components
    private let textView = UITextView()
    private let sendButton = UIButton()
    private let attachButton = UIButton()
    private let placeholderLabel = UILabel()
    private let disabledLabel = UILabel()
    
    // MARK: - Properties
    weak var delegate: EventMessageInputViewDelegate?
    private let maxTextViewHeight: CGFloat = 120
    var isEnabled: Bool = true {
        didSet {
            updateEnabledState()
        }
    }
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .systemBackground
        
        // Add a top separator line
        let topSeparator = UIView()
        topSeparator.backgroundColor = .systemGray5
        topSeparator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topSeparator)
        
        // Setup text view
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.layer.cornerRadius = 18
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.borderWidth = 1
        textView.backgroundColor = .systemGray6
        textView.delegate = self
        textView.isScrollEnabled = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textView)
        
        // Setup placeholder label
        placeholderLabel.text = "Message"
        placeholderLabel.font = UIFont.systemFont(ofSize: 16)
        placeholderLabel.textColor = .systemGray
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        textView.addSubview(placeholderLabel)
        
        // Setup disabled label
        disabledLabel.font = UIFont.systemFont(ofSize: 14)
        disabledLabel.textColor = .systemRed
        disabledLabel.text = "Chat is disabled"
        disabledLabel.isHidden = true
        disabledLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(disabledLabel)
        
        // Setup send button
        let sendImage = UIImage(systemName: "arrow.up.circle.fill")
        sendButton.setImage(sendImage, for: .normal)
        sendButton.tintColor = .systemBlue
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(sendButton)
        
        // Setup attach button
        let attachImage = UIImage(systemName: "paperclip")
        attachButton.setImage(attachImage, for: .normal)
        attachButton.tintColor = .systemGray
        attachButton.addTarget(self, action: #selector(attachTapped), for: .touchUpInside)
        attachButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(attachButton)
        
        // Set constraints
        NSLayoutConstraint.activate([
            // Top separator
            topSeparator.topAnchor.constraint(equalTo: topAnchor),
            topSeparator.leadingAnchor.constraint(equalTo: leadingAnchor),
            topSeparator.trailingAnchor.constraint(equalTo: trailingAnchor),
            topSeparator.heightAnchor.constraint(equalToConstant: 0.5),
            
            // Attach button
            attachButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            attachButton.centerYAnchor.constraint(equalTo: textView.centerYAnchor),
            attachButton.widthAnchor.constraint(equalToConstant: 40),
            attachButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Text view
            textView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            textView.leadingAnchor.constraint(equalTo: attachButton.trailingAnchor, constant: 4),
            textView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -4),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            
            // Placeholder
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 12),
            placeholderLabel.centerYAnchor.constraint(equalTo: textView.centerYAnchor),
            
            // Disabled label
            disabledLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            disabledLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            // Send button
            sendButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            sendButton.centerYAnchor.constraint(equalTo: textView.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 40),
            sendButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Overall view constraints
            heightAnchor.constraint(greaterThanOrEqualToConstant: 56)
        ])
        
        // Initial button state
        sendButton.isEnabled = false
    }
    
    // MARK: - Actions
    @objc private func sendTapped() {
        guard isEnabled, let text = textView.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return
        }
        
        delegate?.didTapSend(text: text)
        textView.text = ""
        updateTextViewHeight()
        placeholderLabel.isHidden = false
        sendButton.isEnabled = false
    }
    
    @objc private func attachTapped() {
        guard isEnabled else { return }
        delegate?.didTapAttachment()
    }
    
    // MARK: - Helper Methods
    private func updateTextViewHeight() {
        let size = CGSize(width: textView.bounds.width, height: .infinity)
        let estimatedSize = textView.sizeThatFits(size)
        
        // Calculate the new height, constrained to the max height
        let newHeight = min(estimatedSize.height, maxTextViewHeight)
        
        // Only update if the height changed
        if textView.constraints.first(where: { $0.firstAttribute == .height }) == nil {
            textView.heightAnchor.constraint(equalToConstant: newHeight).isActive = true
        } else {
            textView.constraints.first(where: { $0.firstAttribute == .height })?.constant = newHeight
        }
        
        // Enable scrolling if at max height
        textView.isScrollEnabled = estimatedSize.height > maxTextViewHeight
        
        // Request layout
        setNeedsLayout()
    }
    
    private func updateEnabledState() {
        textView.isUserInteractionEnabled = isEnabled
        sendButton.isEnabled = isEnabled && !textView.text.isEmpty
        attachButton.isEnabled = isEnabled
        
        if isEnabled {
            textView.alpha = 1.0
            disabledLabel.isHidden = true
            placeholderLabel.isHidden = !textView.text.isEmpty
        } else {
            textView.alpha = 0.5
            disabledLabel.isHidden = false
            placeholderLabel.isHidden = true
        }
    }
    
    // MARK: - Public Methods
    func showDisabledState(with message: String) {
        isEnabled = false
        disabledLabel.text = message
    }
    
    func showEnabledState() {
        isEnabled = true
    }
}

// MARK: - UITextViewDelegate
extension EventMessageInputView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        sendButton.isEnabled = !textView.text.isEmpty
        updateTextViewHeight()
    }
}
