import UIKit

class RegistrationTableViewCell: UITableViewCell {
    
    static let identifier = "RegistrationTableViewCell"
    
    // MARK: - UI Components
    private let serialNumberLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .black
        return label
    }()
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.numberOfLines = 2
        return label
    }()
    
    private let yearLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .black
        return label
    }()
    
    private let collegeEmailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.numberOfLines = 2
        return label
    }()
    
    private let contactNumberLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        return label
    }()
    
    private let courseLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        return label
    }()
    
    private let departmentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        return label
    }()
    
    private let faNumberLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        return label
    }()
    
    private let facultyAdvisorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        return label
    }()
    
    private let personalEmailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.numberOfLines = 2
        return label
    }()
    
    private let registrationNumberLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        return label
    }()
    
    private let sectionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        return label
    }()
    
    private let specializationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        return label
    }()
    
    // MARK: - Initializer
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        let stackView = UIStackView(arrangedSubviews: [
            serialNumberLabel, nameLabel, collegeEmailLabel, contactNumberLabel,
            courseLabel, departmentLabel, faNumberLabel, facultyAdvisorLabel,
            personalEmailLabel, registrationNumberLabel, sectionLabel, specializationLabel, emailLabel, yearLabel
        ])
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])
    }
    
    // MARK: - Configure Cell
    func configure(with registration: [String: Any], index: Int) {
        serialNumberLabel.text = "\(index + 1)"
        nameLabel.text = "Name: \(registration["Name"] as? String ?? "N/A")"
        emailLabel.text = "Email: \(registration["email"] as? String ?? "N/A")"
        collegeEmailLabel.text = "College Email ID: \(registration["College Email ID"] as? String ?? "N/A")"
        contactNumberLabel.text = "Contact Number: \(registration["Contact Number"] as? String ?? "N/A")"
        courseLabel.text = "Course: \(registration["Course"] as? String ?? "N/A")"
        departmentLabel.text = "Department: \(registration["Department"] as? String ?? "N/A")"
        faNumberLabel.text = "FA Number: \(registration["FA Number"] as? String ?? "N/A")"
        facultyAdvisorLabel.text = "Faculty Advisor: \(registration["Faculty Advisor"] as? String ?? "N/A")"
        personalEmailLabel.text = "Personal Email ID: \(registration["Personal Email ID"] as? String ?? "N/A")"
        registrationNumberLabel.text = "Registration No.: \(registration["Registration No."] as? String ?? "N/A")"
        sectionLabel.text = "Section: \(registration["Section"] as? String ?? "N/A")"
        specializationLabel.text = "Specialization: \(registration["Specialization"] as? String ?? "N/A")"
        yearLabel.text = "Year of Study: \(registration["Year of Study"] as? String ?? "N/A")"
    }
}
