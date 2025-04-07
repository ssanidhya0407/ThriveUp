//import UIKit
//
//class RegistrationTableViewCell: UITableViewCell {
//    
//    static let identifier = "RegistrationTableViewCell"
//    
//    // MARK: - UI Components
//    private let containerView: UIView = {
//        let view = UIView()
//        view.backgroundColor = .white
//        view.layer.cornerRadius = 12
//        view.layer.shadowColor = UIColor.black.cgColor
//        view.layer.shadowOpacity = 0.1
//        view.layer.shadowOffset = CGSize(width: 0, height: 2)
//        view.layer.shadowRadius = 4
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
//    
//    private let serialNumberView: UIView = {
//        let view = UIView()
//        view.backgroundColor = UIColor(red: 0.95, green: 0.61, blue: 0.07, alpha: 1.0) // Orange shade
//        view.layer.cornerRadius = 18
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
//    
//    private let serialNumberLabel: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.boldSystemFont(ofSize: 16)
//        label.textColor = .white
//        label.textAlignment = .center
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//    
//    private let nameLabel: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.boldSystemFont(ofSize: 18)
//        label.textColor = .black
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//    
//    private let yearBadge: UIView = {
//        let view = UIView()
//        view.backgroundColor = UIColor(red: 0.91, green: 0.95, blue: 0.98, alpha: 1.0) // Light blue
//        view.layer.cornerRadius = 10
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
//    
//    private let yearLabel: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
//        label.textColor = UIColor(red: 0.15, green: 0.31, blue: 0.55, alpha: 1.0) // Dark blue
//        label.textAlignment = .center
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//    
//    private let infoStackView: UIStackView = {
//        let stackView = UIStackView()
//        stackView.axis = .vertical
//        stackView.spacing = 8
//        stackView.alignment = .leading
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//        return stackView
//    }()
//    
//    private let emailInfoView = InfoItemView(icon: "envelope")
//    private let phoneInfoView = InfoItemView(icon: "phone")
//    private let courseInfoView = InfoItemView(icon: "book")
//    private let departmentInfoView = InfoItemView(icon: "building.columns")
//    private let registrationInfoView = InfoItemView(icon: "number")
//    
//    private let expandButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("View Details", for: .normal)
//        button.setTitleColor(UIColor(red: 0.95, green: 0.61, blue: 0.07, alpha: 1.0), for: .normal) // Orange
//        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
//        button.backgroundColor = .clear
//        button.translatesAutoresizingMaskIntoConstraints = false
//        return button
//    }()
//    
//    private var detailsStackView: UIStackView = {
//        let stackView = UIStackView()
//        stackView.axis = .vertical
//        stackView.spacing = 8
//        stackView.alignment = .leading
//        stackView.isHidden = true
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//        return stackView
//    }()
//    
//    private let dividerLine: UIView = {
//        let view = UIView()
//        view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
//    
//    private let personalEmailInfoView = InfoItemView(icon: "envelope.fill")
//    private let collegeEmailInfoView = InfoItemView(icon: "envelope.badge")
//    private let faNumberInfoView = InfoItemView(icon: "person.badge.key")
//    private let facultyAdvisorInfoView = InfoItemView(icon: "person.text.rectangle")
//    private let sectionInfoView = InfoItemView(icon: "tablecells")
//    private let specializationInfoView = InfoItemView(icon: "star")
//    
//    private var isExpanded = false
//    private var detailsHeightConstraint: NSLayoutConstraint?
//    
//    // MARK: - Initializers
//    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//        setupUI()
//        setupActions()
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        isExpanded = false
//        detailsStackView.isHidden = true
//        expandButton.setTitle("View Details", for: .normal)
//    }
//    
//    // MARK: - Setup UI
//    private func setupUI() {
//        selectionStyle = .none
//        contentView.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1.0) // Light background
//        
//        contentView.addSubview(containerView)
//        containerView.addSubview(serialNumberView)
//        serialNumberView.addSubview(serialNumberLabel)
//        containerView.addSubview(nameLabel)
//        containerView.addSubview(yearBadge)
//        yearBadge.addSubview(yearLabel)
//        containerView.addSubview(infoStackView)
//        containerView.addSubview(expandButton)
//        containerView.addSubview(dividerLine)
//        containerView.addSubview(detailsStackView)
//        
//        // Add info items to main stack
//        infoStackView.addArrangedSubview(emailInfoView)
//        infoStackView.addArrangedSubview(phoneInfoView)
//        infoStackView.addArrangedSubview(courseInfoView)
//        infoStackView.addArrangedSubview(registrationInfoView)
//        infoStackView.addArrangedSubview(departmentInfoView)
//        
//        // Add info items to details stack
//        detailsStackView.addArrangedSubview(personalEmailInfoView)
//        detailsStackView.addArrangedSubview(collegeEmailInfoView)
//        detailsStackView.addArrangedSubview(faNumberInfoView)
//        detailsStackView.addArrangedSubview(facultyAdvisorInfoView)
//        detailsStackView.addArrangedSubview(sectionInfoView)
//        detailsStackView.addArrangedSubview(specializationInfoView)
//        
//        setupConstraints()
//    }
//    
//    private func setupConstraints() {
//        // Container view
//        NSLayoutConstraint.activate([
//            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
//            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
//            
//            // Serial number circle
//            serialNumberView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
//            serialNumberView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
//            serialNumberView.widthAnchor.constraint(equalToConstant: 36),
//            serialNumberView.heightAnchor.constraint(equalToConstant: 36),
//            
//            serialNumberLabel.centerXAnchor.constraint(equalTo: serialNumberView.centerXAnchor),
//            serialNumberLabel.centerYAnchor.constraint(equalTo: serialNumberView.centerYAnchor),
//            
//            // Name label
//            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
//            nameLabel.leadingAnchor.constraint(equalTo: serialNumberView.trailingAnchor, constant: 12),
//            nameLabel.trailingAnchor.constraint(equalTo: yearBadge.leadingAnchor, constant: -8),
//            
//            // Year badge
//            yearBadge.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
//            yearBadge.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
//            yearBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
//            yearBadge.heightAnchor.constraint(equalToConstant: 20),
//            
//            yearLabel.centerXAnchor.constraint(equalTo: yearBadge.centerXAnchor),
//            yearLabel.centerYAnchor.constraint(equalTo: yearBadge.centerYAnchor),
//            yearLabel.leadingAnchor.constraint(equalTo: yearBadge.leadingAnchor, constant: 8),
//            yearLabel.trailingAnchor.constraint(equalTo: yearBadge.trailingAnchor, constant: -8),
//            
//            // Info stack
//            infoStackView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 16),
//            infoStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
//            infoStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
//            
//            // Expand button
//            expandButton.topAnchor.constraint(equalTo: infoStackView.bottomAnchor, constant: 12),
//            expandButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
//            expandButton.heightAnchor.constraint(equalToConstant: 30),
//            
//            // Divider line
//            dividerLine.topAnchor.constraint(equalTo: expandButton.bottomAnchor, constant: 4),
//            dividerLine.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
//            dividerLine.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
//            dividerLine.heightAnchor.constraint(equalToConstant: 1),
//            
//            // Details stack
//            detailsStackView.topAnchor.constraint(equalTo: dividerLine.bottomAnchor, constant: 12),
//            detailsStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
//            detailsStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
//            detailsStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
//        ])
//    }
//    
//    private func setupActions() {
//        expandButton.addTarget(self, action: #selector(toggleDetails), for: .touchUpInside)
//    }
//    
//    @objc private func toggleDetails() {
//        isExpanded.toggle()
//        detailsStackView.isHidden = !isExpanded
//        expandButton.setTitle(isExpanded ? "Hide Details" : "View Details", for: .normal)
//        
//        // Notify the tableView to update cell height
//        if let tableView = self.superview as? UITableView {
//            tableView.beginUpdates()
//            tableView.endUpdates()
//        }
//    }
//    
//    // MARK: - Configure Cell
//    func configure(with registration: [String: Any], index: Int) {
//        serialNumberLabel.text = "\(index + 1)"
//        nameLabel.text = registration["Name"] as? String ?? "N/A"
//        
//        // Main info items
//        let email = registration["email"] as? String ?? "N/A"
//        emailInfoView.configure(title: "Email", value: email)
//        
//        let contactNumber = registration["Contact Number"] as? String ?? "N/A"
//        phoneInfoView.configure(title: "Contact", value: contactNumber)
//        
//        let course = registration["Course"] as? String ?? "N/A"
//        courseInfoView.configure(title: "Course", value: course)
//        
//        let regNumber = registration["Registration No."] as? String ?? "N/A"
//        registrationInfoView.configure(title: "Reg. No.", value: regNumber)
//        
//        let department = registration["Department"] as? String ?? "N/A"
//        departmentInfoView.configure(title: "Department", value: department)
//        
//        // Details info items
//        let personalEmail = registration["Personal Email ID"] as? String ?? "N/A"
//        personalEmailInfoView.configure(title: "Personal Email", value: personalEmail)
//        
//        let collegeEmail = registration["College Email ID"] as? String ?? "N/A"
//        collegeEmailInfoView.configure(title: "College Email", value: collegeEmail)
//        
//        let faNumber = registration["FA Number"] as? String ?? "N/A"
//        faNumberInfoView.configure(title: "FA Number", value: faNumber)
//        
//        let facultyAdvisor = registration["Faculty Advisor"] as? String ?? "N/A"
//        facultyAdvisorInfoView.configure(title: "Faculty Advisor", value: facultyAdvisor)
//        
//        let section = registration["Section"] as? String ?? "N/A"
//        sectionInfoView.configure(title: "Section", value: section)
//        
//        let specialization = registration["Specialization"] as? String ?? "N/A"
//        specializationInfoView.configure(title: "Specialization", value: specialization)
//        
//        // Year badge
//        let year = registration["Year of Study"] as? String ?? "N/A"
//        yearLabel.text = "Year \(year)"
//    }
//}
//
//// MARK: - InfoItemView
//class InfoItemView: UIView {
//    private let iconImageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.contentMode = .scaleAspectFit
//        imageView.tintColor = UIColor(red: 0.95, green: 0.61, blue: 0.07, alpha: 1.0) // Orange
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        return imageView
//    }()
//    
//    private let titleLabel: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
//        label.textColor = UIColor.darkGray
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//    
//    private let valueLabel: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
//        label.textColor = UIColor.black
//        label.numberOfLines = 0
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//    
//    init(icon: String) {
//        super.init(frame: .zero)
//        
//        if #available(iOS 13.0, *) {
//            iconImageView.image = UIImage(systemName: icon)
//        } else {
//            // Fallback for earlier iOS versions
//            iconImageView.image = UIImage(named: icon)
//        }
//        
//        setupUI()
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    private func setupUI() {
//        addSubview(iconImageView)
//        addSubview(titleLabel)
//        addSubview(valueLabel)
//        
//        NSLayoutConstraint.activate([
//            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
//            iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
//            iconImageView.widthAnchor.constraint(equalToConstant: 16),
//            iconImageView.heightAnchor.constraint(equalToConstant: 16),
//            
//            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
//            titleLabel.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
//            titleLabel.widthAnchor.constraint(equalToConstant: 80),
//            
//            valueLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
//            valueLabel.topAnchor.constraint(equalTo: topAnchor),
//            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
//            valueLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
//        ])
//    }
//    
//    func configure(title: String, value: String) {
//        titleLabel.text = title + ":"
//        valueLabel.text = value
//    }
//}
