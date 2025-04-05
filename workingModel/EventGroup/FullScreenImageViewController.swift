//
//  FullScreenImageViewController.swift
//  ThriveUp
//
//  Created by Sanidhya's MacBook Pro on 05/04/25.
//


import UIKit
import Kingfisher

class FullScreenImageViewController: UIViewController {
    // MARK: - Properties
    private let imageURL: URL
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    
    // MARK: - Initialization
    init(imageURL: URL) {
        self.imageURL = imageURL
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadImage()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .black
        
        // Setup close button
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        closeButton.layer.cornerRadius = 20
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup scroll view
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Setup image view
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)
        
        // Add tap gesture to toggle controls
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGesture)
        
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.require(toFail: doubleTapGesture)
        scrollView.addGestureRecognizer(singleTapGesture)
        
        // Add close button to view
        view.addSubview(closeButton)
        
        // Set constraints
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Image view
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            
            // Close button
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    // MARK: - Image Loading
    private func loadImage() {
        // Show loading indicator
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .white
        activityIndicator.startAnimating()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Load image with Kingfisher
        imageView.kf.setImage(with: imageURL) { [weak self] result in
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
            
            switch result {
            case .success(let imageResult):
                // Update content size after image is loaded
                self?.updateZoomScaleForSize(imageResult.image.size)
            case .failure(let error):
                print("Error loading image: \(error.localizedDescription)")
                // Show error message
                let label = UILabel()
                label.text = "Failed to load image"
                label.textColor = .white
                label.translatesAutoresizingMaskIntoConstraints = false
                self?.view.addSubview(label)
                
                if let view = self?.view {
                    NSLayoutConstraint.activate([
                        label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                        label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
                    ])
                }
            }
        }
    }
    
    private func updateZoomScaleForSize(_ imageSize: CGSize) {
        let widthScale = scrollView.bounds.width / imageSize.width
        let heightScale = scrollView.bounds.height / imageSize.height
        let minScale = min(widthScale, heightScale)
        
        scrollView.minimumZoomScale = minScale
        scrollView.zoomScale = minScale
    }
    
    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func handleSingleTap() {
        dismiss(animated: true)
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            // Zoom in to twice the size at the point tapped
            let location = gesture.location(in: imageView)
            let zoomRect = CGRect(
                x: location.x - (scrollView.bounds.width / 4),
                y: location.y - (scrollView.bounds.height / 4),
                width: scrollView.bounds.width / 2,
                height: scrollView.bounds.height / 2
            )
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }
}

// MARK: - UIScrollViewDelegate
extension FullScreenImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // Center the image when zooming
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: offsetY, right: offsetX)
    }
}