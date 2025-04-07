//
//  RegistrationDetailViewController.swift
//  ThriveUp
//
//  Created by Sanidhya's MacBook Pro on 07/04/25.
//


import UIKit

import UIKit

class RegistrationDetailViewController: UIViewController {
    
    // MARK: - Properties
    private let registration: [String: Any]
    private let index: Int
    private let profileImageURL: String?
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        scrollView.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1.0)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor(red: 0.95, green: 0.61, blue: 0.07, alpha: 0.1)
        imageView.layer.cornerRadius = 50
        imageView.layer.borderWidth = 3
        imageView.layer.borderColor = UIColor(red: 0.95, green: 0.61, blue: 0.07, alpha: 0.3).cgColor
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let initialsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        label.textColor = UIColor(red: 0.95, green: 0.61, blue: 0.07, alpha: 1.0)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let registrationNumberLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .darkGray
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let detailsContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let detailsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // MARK: - Section Views
    private let personalInfoSectionView: SectionView = {
        let view = SectionView(title: "Personal Information")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let academicInfoSectionView: SectionView = {
        let view = SectionView(title: "Academic Information")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let contactInfoSectionView: SectionView = {
        let view = SectionView(title: "Contact Information")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Detail Items
    // Personal Info Items
    private let nameInfoView = DetailItemView(icon: "person.fill")
    private let regNumberInfoView = DetailItemView(icon: "number")
    
    // Academic Info Items
    private let courseInfoView = DetailItemView(icon: "book.fill")
    private let departmentInfoView = DetailItemView(icon: "building.columns.fill")
    private let yearInfoView = DetailItemView(icon: "calendar")
    private let sectionInfoView = DetailItemView(icon: "tablecells")
    private let specializationInfoView = DetailItemView(icon: "star.fill")
    private let faNumberInfoView = DetailItemView(icon: "person.badge.key.fill")
    private let facultyAdvisorInfoView = DetailItemView(icon: "person.text.rectangle.fill")
    
    // Contact Info Items
    private let emailInfoView = DetailItemView(icon: "envelope.fill")
    private let personalEmailInfoView = DetailItemView(icon: "envelope.badge.fill")
    private let collegeEmailInfoView = DetailItemView(icon: "envelope.circle.fill")
    private let contactNumberInfoView = DetailItemView(icon: "phone.fill")
    
    // MARK: - Initializers
    init(registration: [String: Any], index: Int, profileImageURL: String?) {
        self.registration = registration
        self.index = index
        self.profileImageURL = profileImageURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureWithRegistrationData()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        title = "Registration Details"
        view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1.0)
        
        // Configure navigation bar to white
        navigationController?.navigationBar.barTintColor = .white
        navigationController?.navigationBar.tintColor = UIColor(red: 0.95, green: 0.61, blue: 0.07, alpha: 1.0)
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.black]
        
        // Add views to hierarchy
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(headerView)
        headerView.addSubview(profileImageView)
        profileImageView.addSubview(initialsLabel)
        headerView.addSubview(nameLabel)
        headerView.addSubview(registrationNumberLabel)
        
        contentView.addSubview(detailsContainer)
        detailsContainer.addSubview(detailsStackView)
        
        // Add sections to stack view
        detailsStackView.addArrangedSubview(personalInfoSectionView)
        detailsStackView.addArrangedSubview(academicInfoSectionView)
        detailsStackView.addArrangedSubview(contactInfoSectionView)
        
        // Add detail items to sections
        personalInfoSectionView.addItem(nameInfoView)
        personalInfoSectionView.addItem(regNumberInfoView)
        
        academicInfoSectionView.addItem(courseInfoView)
        academicInfoSectionView.addItem(departmentInfoView)
        academicInfoSectionView.addItem(yearInfoView)
        academicInfoSectionView.addItem(sectionInfoView)
        academicInfoSectionView.addItem(specializationInfoView)
        academicInfoSectionView.addItem(faNumberInfoView)
        academicInfoSectionView.addItem(facultyAdvisorInfoView)
        
        contactInfoSectionView.addItem(emailInfoView)
        contactInfoSectionView.addItem(personalEmailInfoView)
        contactInfoSectionView.addItem(collegeEmailInfoView)
        contactInfoSectionView.addItem(contactNumberInfoView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        let contentViewHeightConstraint = contentView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        contentViewHeightConstraint.priority = .defaultLow
        
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            contentViewHeightConstraint,
            
            // Header view
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            headerView.heightAnchor.constraint(equalToConstant: 220),
            
            // Profile image
            profileImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            profileImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),
            
            // Initials label
            initialsLabel.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            
            // Name label
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            // Registration number label
            registrationNumberLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            registrationNumberLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            registrationNumberLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            registrationNumberLabel.bottomAnchor.constraint(lessThanOrEqualTo: headerView.bottomAnchor, constant: -16),
            
            // Details container
            detailsContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            detailsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            detailsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            detailsContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            // Details stack view
            detailsStackView.topAnchor.constraint(equalTo: detailsContainer.topAnchor, constant: 16),
            detailsStackView.leadingAnchor.constraint(equalTo: detailsContainer.leadingAnchor, constant: 16),
            detailsStackView.trailingAnchor.constraint(equalTo: detailsContainer.trailingAnchor, constant: -16),
            detailsStackView.bottomAnchor.constraint(equalTo: detailsContainer.bottomAnchor, constant: -16),
        ])
    }
    
    // MARK: - Data Configuration
    private func configureWithRegistrationData() {
        // Configure name and profile image
        let fullName = registration["Name"] as? String ?? "N/A"
        nameLabel.text = fullName
        
        // If we have a profile image URL, load the image
        if let profileURL = profileImageURL, let url = URL(string: profileURL) {
            initialsLabel.isHidden = true
            loadImage(from: url)
        } else {
            // Otherwise use initials
            initialsLabel.isHidden = false
            
            // Create initials from name
            let components = fullName.components(separatedBy: " ")
            var initials = ""
            if components.count > 0 {
                if let first = components.first?.prefix(1) {
                    initials += String(first)
                }
                if components.count > 1, let last = components.last?.prefix(1) {
                    initials += String(last)
                } else if let first = components.first?.prefix(2) {
                    initials = String(first)
                }
            }
            initialsLabel.text = initials.uppercased()
        }
        
        // Configure registration number
        let regNumber = registration["Registration No."] as? String ?? "N/A"
        registrationNumberLabel.text = regNumber
        
        // Configure personal information
        nameInfoView.configure(title: "Full Name", value: fullName)
        regNumberInfoView.configure(title: "Registration Number", value: regNumber)
        
        // Configure academic information
        let course = registration["Course"] as? String ?? "N/A"
        courseInfoView.configure(title: "Course", value: course)
        
        let department = registration["Department"] as? String ?? "N/A"
        departmentInfoView.configure(title: "Department", value: department)
        
        let year = registration["Year of Study"] as? String ?? "N/A"
        yearInfoView.configure(title: "Year of Study", value: year)
        
        let section = registration["Section"] as? String ?? "N/A"
        sectionInfoView.configure(title: "Section", value: section)
        
        let specialization = registration["Specialization"] as? String ?? "N/A"
        specializationInfoView.configure(title: "Specialization", value: specialization)
        
        let faNumber = registration["FA Number"] as? String ?? "N/A"
        faNumberInfoView.configure(title: "FA Number", value: faNumber)
        
        let facultyAdvisor = registration["Faculty Advisor"] as? String ?? "N/A"
        facultyAdvisorInfoView.configure(title: "Faculty Advisor", value: facultyAdvisor)
        
        // Configure contact information
        let email = registration["email"] as? String ?? "N/A"
        emailInfoView.configure(title: "Email", value: email)
        
        let personalEmail = registration["Personal Email ID"] as? String ?? "N/A"
        personalEmailInfoView.configure(title: "Personal Email", value: personalEmail)
        
        let collegeEmail = registration["College Email ID"] as? String ?? "N/A"
        collegeEmailInfoView.configure(title: "College Email", value: collegeEmail)
        
        let contactNumber = registration["Contact Number"] as? String ?? "N/A"
        contactNumberInfoView.configure(title: "Contact Number", value: contactNumber)
    }
    
    private func loadImage(from url: URL) {
        // Create a URLSession task to fetch the image
        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let self = self,
                  let imageData = data,
                  error == nil,
                  let image = UIImage(data: imageData) else {
                return
            }
            
            // Update UI on the main thread
            DispatchQueue.main.async {
                self.profileImageView.image = image
            }
        }
        task.resume()
    }
}

// MARK: - SectionView
class SectionView: UIView {
    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = UIColor(red: 0.95, green: 0.61, blue: 0.07, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dividerLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.95, green: 0.61, blue: 0.07, alpha: 0.3)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // MARK: - Initializers
    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        addSubview(titleLabel)
        addSubview(dividerLine)
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            dividerLine.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            dividerLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            dividerLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            dividerLine.heightAnchor.constraint(equalToConstant: 1),
            
            stackView.topAnchor.constraint(equalTo: dividerLine.bottomAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - Public Methods
    func addItem(_ item: UIView) {
        stackView.addArrangedSubview(item)
    }
}

// MARK: - DetailItemView
class DetailItemView: UIView {
    // MARK: - UI Components
    private let iconContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.95, green: 0.61, blue: 0.07, alpha: 0.1)
        view.layer.cornerRadius = 18
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor(red: 0.95, green: 0.61, blue: 0.07, alpha: 1.0)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .black
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Initializers
    init(icon: String) {
        super.init(frame: .zero)
        
        if #available(iOS 13.0, *) {
            iconImageView.image = UIImage(systemName: icon)
        } else {
            iconImageView.image = UIImage(named: icon)
        }
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            iconContainer.topAnchor.constraint(equalTo: topAnchor),
            iconContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 36),
            iconContainer.heightAnchor.constraint(equalToConstant: 36),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            valueLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 12),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - Public Methods
    func configure(title: String, value: String) {
        titleLabel.text = title
        valueLabel.text = value
    }
}
