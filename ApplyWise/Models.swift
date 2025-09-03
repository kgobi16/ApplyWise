import SwiftUI
import Foundation

// MARK: - Base Protocols

protocol TaskProtocol: ObservableObject, Identifiable {
    var id: UUID { get }
    var title: String { get set }
    var priority: TaskPriority { get set }
    var createdDate: Date { get set }
    var lastUpdatedDate: Date { get set }
    var notes: String { get set }
    
    func validate() throws
    func updateLastModified()
}

protocol StatusManageable {
    associatedtype StatusType: CaseIterable & RawRepresentable where StatusType.RawValue == String
    var status: StatusType { get set }
    func updateStatus(_ newStatus: StatusType)
}

protocol ContactManageable {
    var contactEmail: String { get set }
    var contactName: String { get set }
    func validateContact() throws
}

protocol JobApplicationProtocol: TaskProtocol, StatusManageable, ContactManageable where StatusType == ApplicationStatus {
    var companyName: String { get set }
    var jobTitle: String { get set }
    var applicationDate: Date { get set }
    var followUpDate: Date? { get set }
    var salary: String { get set }
    var location: String { get set }
}

// MARK: - Enums

enum TaskPriority: String, CaseIterable, Identifiable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
    
    var id: String { self.rawValue }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

enum ApplicationStatus: String, CaseIterable, Identifiable, Codable {
    case applied = "Applied"
    case screening = "Screening"
    case interviewing = "Interviewing"
    case offer = "Offer"
    case rejected = "Rejected"
    case withdrawn = "Withdrawn"
    
    var id: String { self.rawValue }
    
    var color: Color {
        switch self {
        case .applied: return .blue
        case .screening: return .orange
        case .interviewing: return .purple
        case .offer: return .green
        case .rejected: return .red
        case .withdrawn: return .gray
        }
    }
}

enum AppError: Error, LocalizedError {
    case invalidEmail
    case emptyFields
    case applicationNotFound
    case saveFailed
    case invalidDate
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .emptyFields:
            return "Please fill in all required fields"
        case .applicationNotFound:
            return "Application not found"
        case .saveFailed:
            return "Failed to save application"
        case .invalidDate:
            return "Please enter a valid date"
        }
    }
}

// MARK: - Base Task Class

class BaseTask: ObservableObject, TaskProtocol, Codable {
    @Published var id: UUID
    @Published var title: String
    @Published var priority: TaskPriority
    @Published var createdDate: Date
    @Published var lastUpdatedDate: Date
    @Published var notes: String
    
    init(title: String, priority: TaskPriority = .medium, notes: String = "") {
        self.id = UUID()
        self.title = title
        self.priority = priority
        self.createdDate = Date()
        self.lastUpdatedDate = Date()
        self.notes = notes
    }
    
    func validate() throws {
        if title.isEmpty {
            throw AppError.emptyFields
        }
    }
    
    func updateLastModified() {
        lastUpdatedDate = Date()
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case id, title, priority, createdDate, lastUpdatedDate, notes
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        priority = try container.decode(TaskPriority.self, forKey: .priority)
        createdDate = try container.decode(Date.self, forKey: .createdDate)
        lastUpdatedDate = try container.decode(Date.self, forKey: .lastUpdatedDate)
        notes = try container.decode(String.self, forKey: .notes)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(priority, forKey: .priority)
        try container.encode(createdDate, forKey: .createdDate)
        try container.encode(lastUpdatedDate, forKey: .lastUpdatedDate)
        try container.encode(notes, forKey: .notes)
    }
}

// MARK: - Job Application Class (Inherits from BaseTask)

class JobApplication: BaseTask, JobApplicationProtocol, ContactManageable {
    @Published var companyName: String
    @Published var jobTitle: String
    @Published var applicationDate: Date
    @Published var status: ApplicationStatus
    @Published var followUpDate: Date?
    @Published var salary: String
    @Published var location: String
    @Published var contactEmail: String
    @Published var contactName: String
    
    init(companyName: String, jobTitle: String, contactEmail: String = "", contactName: String = "", notes: String = "", salary: String = "", location: String = "", priority: TaskPriority = .medium) {
        self.companyName = companyName
        self.jobTitle = jobTitle
        self.applicationDate = Date()
        self.status = .applied
        self.contactEmail = contactEmail
        self.contactName = contactName
        self.followUpDate = nil
        self.salary = salary
        self.location = location
        
        super.init(title: "\(jobTitle) at \(companyName)", priority: priority, notes: notes)
    }
    
    func updateStatus(_ newStatus: ApplicationStatus) {
        status = newStatus
        updateLastModified()
    }
    
    func validateContact() throws {
        if !contactEmail.isEmpty && !isValidEmail(contactEmail) {
            throw AppError.invalidEmail
        }
    }
    
    override func validate() throws {
        try super.validate()
        if companyName.isEmpty || jobTitle.isEmpty {
            throw AppError.emptyFields
        }
        try validateContact()
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    // MARK: - Codable Implementation
    
    enum JobApplicationCodingKeys: String, CodingKey {
        case companyName, jobTitle, applicationDate, status, followUpDate, salary, location, contactEmail, contactName
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: JobApplicationCodingKeys.self)
        companyName = try container.decode(String.self, forKey: .companyName)
        jobTitle = try container.decode(String.self, forKey: .jobTitle)
        applicationDate = try container.decode(Date.self, forKey: .applicationDate)
        status = try container.decode(ApplicationStatus.self, forKey: .status)
        followUpDate = try container.decodeIfPresent(Date.self, forKey: .followUpDate)
        salary = try container.decode(String.self, forKey: .salary)
        location = try container.decode(String.self, forKey: .location)
        contactEmail = try container.decode(String.self, forKey: .contactEmail)
        contactName = try container.decode(String.self, forKey: .contactName)
        
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: JobApplicationCodingKeys.self)
        try container.encode(companyName, forKey: .companyName)
        try container.encode(jobTitle, forKey: .jobTitle)
        try container.encode(applicationDate, forKey: .applicationDate)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(followUpDate, forKey: .followUpDate)
        try container.encode(salary, forKey: .salary)
        try container.encode(location, forKey: .location)
        try container.encode(contactEmail, forKey: .contactEmail)
        try container.encode(contactName, forKey: .contactName)
        
        try super.encode(to: encoder)
    }
}

// MARK: - Task Factory (Factory Pattern)

class TaskFactory {
    static func createJobApplication(companyName: String, jobTitle: String) -> JobApplication {
        return JobApplication(companyName: companyName, jobTitle: jobTitle)
    }
}

// MARK: - Preview Support

#Preview("Job Application Model") {
    let application = TaskFactory.createJobApplication(companyName: "Apple Inc", jobTitle: "iOS Developer")
    application.priority = .high
    application.salary = "$120,000"
    application.location = "Cupertino, CA"
    application.contactEmail = "jobs@apple.com"
    
    return VStack {
        Text("Sample Job Application Created")
        Text("Company: \(application.companyName)")
        Text("Title: \(application.jobTitle)")
        Text("Priority: \(application.priority.rawValue)")
    }
    .padding()
}
