//
//  JobApplicationManager.swift
//  ApplyWise
//
//  Created by Tlaitirang Rathete on 8/9/2025.
//

import SwiftUI
import Foundation

//Manager Protocols

protocol JobApplicationManagerProtocol {
    func addApplication(_ application: JobApplication)
    func updateApplication(_ application: JobApplication)
    func deleteApplication(withId id: UUID)
    func getApplications(by status: ApplicationStatus) -> [JobApplication]
    func getAllApplications() -> [JobApplication]
}

//Statistics Structures

struct ApplicationStats {
    let total: Int
    let interviews: Int
    let offers: Int
    let rejections: Int
    let pending: Int
    
    var successRate: Double {
        guard total > 0 else { return 0.0 }
        return Double(offers) / Double(total) * 100
    }
    
    var interviewRate: Double {
        guard total > 0 else { return 0.0 }
        return Double(interviews) / Double(total) * 100
    }
}

//Main Manager Class

class JobApplicationManager: ObservableObject, JobApplicationManagerProtocol {
    @Published var applications: [JobApplication] = []
    
    //JobApplicationManagerProtocol Implementation
    
    func addApplication(_ application: JobApplication) {
        applications.append(application)
    }
    
    func updateApplication(_ application: JobApplication) {
        if let index = applications.firstIndex(where: { $0.id == application.id }) {
            applications[index] = application
            application.updateLastModified()
        }
    }
    
    func deleteApplication(withId id: UUID) {
        applications.removeAll { $0.id == id }
    }
    
    func getApplications(by status: ApplicationStatus) -> [JobApplication] {
        return applications.filter { $0.status == status }
    }
    
    func getAllApplications() -> [JobApplication] {
        return applications
    }
    
    //Analytics Methods
    
    func getApplicationStats() -> ApplicationStats {
        let total = applications.count
        let interviews = applications.filter { $0.status == .interviewing }.count
        let offers = applications.filter { $0.status == .offer }.count
        let rejections = applications.filter { $0.status == .rejected }.count
        let pending = applications.filter {
            $0.status == .applied || $0.status == .screening
        }.count
        
        return ApplicationStats(
            total: total,
            interviews: interviews,
            offers: offers,
            rejections: rejections,
            pending: pending
        )
    }
    
    //Sample Data Setup
    
    func setupSampleData() {
        // Clear existing data
        applications.removeAll()
        
        // Create sample applications
        let app1 = TaskFactory.createJobApplication(companyName: "Apple Inc", jobTitle: "Senior iOS Developer")
        app1.contactEmail = "jobs@apple.com"
        app1.salary = "$120,000 - $150,000"
        app1.location = "Cupertino, CA"
        app1.notes = "Dream job! Focus on SwiftUI experience."
        app1.priority = .high
        
        let app2 = TaskFactory.createJobApplication(companyName: "Google", jobTitle: "Mobile Developer")
        app2.status = .interviewing
        app2.contactEmail = "careers@google.com"
        app2.salary = "$110,000 - $140,000"
        app2.location = "Mountain View, CA"
        app2.priority = .high
        
        let app3 = TaskFactory.createJobApplication(companyName: "Microsoft", jobTitle: "iOS Engineer")
        app3.status = .offer
        app3.contactEmail = "jobs@microsoft.com"
        app3.salary = "$115,000 - $145,000"
        app3.location = "Seattle, WA"
        app3.priority = .urgent
        
        let app4 = TaskFactory.createJobApplication(companyName: "Meta", jobTitle: "Mobile Developer")
        app4.status = .rejected
        app4.contactEmail = "careers@meta.com"
        app4.location = "Menlo Park, CA"
        app4.notes = "Good interview experience, but they went with someone else."
        app4.priority = .medium
        
        let app5 = TaskFactory.createJobApplication(companyName: "Netflix", jobTitle: "iOS Developer")
        app5.status = .screening
        app5.contactEmail = "jobs@netflix.com"
        app5.salary = "$105,000 - $135,000"
        app5.location = "Los Gatos, CA"
        app5.priority = .medium
        
        let app6 = TaskFactory.createJobApplication(companyName: "Spotify", jobTitle: "Senior Mobile Engineer")
        app6.status = .withdrawn
        app6.contactEmail = "careers@spotify.com"
        app6.location = "New York, NY"
        app6.notes = "Decided to focus on other opportunities."
        app6.priority = .low
        
        // Add applications
        addApplication(app1)
        addApplication(app2)
        addApplication(app3)
        addApplication(app4)
        addApplication(app5)
        addApplication(app6)
        
        // Add some follow-up dates
        app1.followUpDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())
        app2.followUpDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
    }
    
    //Helper Methods
    
    func getHighPriorityApplications() -> [JobApplication] {
        return applications.filter { $0.priority == .high || $0.priority == .urgent }
    }
    
    func getFollowUpsDue() -> [JobApplication] {
        let threeDaysFromNow = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        return applications.filter {
            if let followUp = $0.followUpDate {
                return followUp >= Date() && followUp <= threeDaysFromNow
            }
            return false
        }.sorted {
            ($0.followUpDate ?? Date.distantFuture) < ($1.followUpDate ?? Date.distantFuture)
        }
    }
    
    func getApplicationsThisWeek() -> [JobApplication] {
        let weekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        return applications.filter { $0.applicationDate >= weekAgo }
    }
    
    func getSuccessfulApplications() -> [JobApplication] {
        return applications.filter { $0.status == .offer }
    }
    
    func getActiveApplications() -> [JobApplication] {
        return applications.filter {
            $0.status != .rejected && $0.status != .withdrawn
        }
    }
}

// MARK: - Preview Support

#Preview("Job Application Manager") {
    let manager = JobApplicationManager()
    manager.setupSampleData()
    
    let stats = manager.getApplicationStats()
    
    return VStack(alignment: .leading, spacing: 12) {
        Text("Job Application Manager")
            .font(.title)
            .bold()
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Statistics:")
                .font(.headline)
            
            Text("Total Applications: \(stats.total)")
            Text("Interviews: \(stats.interviews)")
            Text("Offers: \(stats.offers)")
            Text("Success Rate: \(String(format: "%.1f%%", stats.successRate))")
            Text("Interview Rate: \(String(format: "%.1f%%", stats.interviewRate))")
        }
        
        Divider()
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Applications:")
                .font(.headline)
            
            ForEach(manager.applications.prefix(3)) { app in
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(app.jobTitle) at \(app.companyName)")
                        .font(.subheadline)
                        .bold()
                    Text("Status: \(app.status.rawValue)")
                        .font(.caption)
                        .foregroundColor(app.status.color)
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
        
        Spacer()
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
}
