//
//  JobApplicationManager.swift
//  ApplyWise
//
//  Created by Tlaitirang Rathete on 8/9/2025.
//

import SwiftUI
import Foundation // Provides essential data types (Date, UUID, Calendar) and collections for data management

// Protocol ensures consistent interface for job application CRUD operations
protocol JobApplicationManagerProtocol {
    func addApplication(_ application: JobApplication)
    func updateApplication(_ application: JobApplication)
    func deleteApplication(withId id: UUID)
    func getApplications(by status: ApplicationStatus) -> [JobApplication]
    func getAllApplications() -> [JobApplication]
}

// Statistics structure for analytics and reporting
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

// Main manager class for handling job applications
class JobApplicationManager: ObservableObject, JobApplicationManagerProtocol {
    @Published var applications: [JobApplication] = []
    
    // Core CRUD operations for job applications
    
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
    
    // Analytics methods for generating statistics
    
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
    
    // Helper methods for filtering and finding specific applications
    
    func getHighPriorityApplications() -> [JobApplication] {
        return applications.filter { $0.priority == .high || $0.priority == .urgent }
    }
    
    //This function returns job applications that have follow-up dates due within the next 3 days
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

// Production ready - all testing and sample data removed
