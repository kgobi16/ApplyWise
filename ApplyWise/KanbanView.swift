//
//  KanbanView.swift
//  ApplyWise
//
//  Created by Tlaitirang Rathete on 8/9/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct KanbanView: View {
    @EnvironmentObject var jobManager: JobApplicationManager
    @State private var showingAddView = false
    @State private var errorAlert: AppError?
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                if geometry.size.width > geometry.size.height {
                    // Landscape Mode - Optimized Layout
                    landscapeLayout(geometry: geometry)
                } else {
                    // Portrait Mode - Fallback
                    portraitLayout(geometry: geometry)
                }
            }
            .navigationTitle("Job Board")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddView = true
                    }) {
                        Label("Add Application", systemImage: "plus.circle.fill")
                    }
                    
                    Button(action: {
                        jobManager.setupSampleData()
                    }) {
                        Label("Refresh Data", systemImage: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingAddView) {
                AddJobApplicationSheet { application in
                    handleAddApplication(application)
                }
            }
            .alert("Error", isPresented: $showingError, presenting: errorAlert) { error in
                Button("OK") { }
            } message: { error in
                Text(error.localizedDescription)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Force single view on iPad
    }
    
    // MARK: - Landscape Layout (Primary)
    
    @ViewBuilder
    private func landscapeLayout(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Header with stats
            KanbanHeaderView()
                .environmentObject(jobManager)
                .frame(height: 80)
            
            Divider()
            
            // Main Kanban Board
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(ApplicationStatus.allCases) { status in
                        KanbanColumnView(
                            status: status,
                            applications: jobManager.getApplications(by: status)
                        )
                        .frame(width: max(280, geometry.size.width / 6))
                        .frame(maxHeight: .infinity)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
        }
    }
    
    // MARK: - Portrait Layout (Fallback)
    
    @ViewBuilder
    private func portraitLayout(geometry: GeometryProxy) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(ApplicationStatus.allCases) { status in
                    KanbanColumnView(
                        status: status,
                        applications: jobManager.getApplications(by: status)
                    )
                    .frame(width: 280)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleAddApplication(_ application: JobApplication) {
        do {
            try application.validate()
            jobManager.addApplication(application)
            showingAddView = false
        } catch let error as AppError {
            errorAlert = error
            showingError = true
        } catch {
            errorAlert = .saveFailed
            showingError = true
        }
    }
}

// MARK: - Kanban Header View

struct KanbanHeaderView: View {
    @EnvironmentObject var jobManager: JobApplicationManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("ApplyWise")
                    .font(.title2)
                    .fontWeight(.bold)
                
                let stats = jobManager.getApplicationStats()
                Text("\(stats.total) applications • \(stats.interviews) interviews • \(stats.offers) offers")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Quick Action Buttons
            HStack(spacing: 12) {
                QuickStatView(
                    title: "Success Rate",
                    value: String(format: "%.1f%%", jobManager.getApplicationStats().successRate),
                    color: .green
                )
                
                QuickStatView(
                    title: "Interview Rate",
                    value: String(format: "%.1f%%", jobManager.getApplicationStats().interviewRate),
                    color: .blue
                )
                
                let highPriorityCount = jobManager.getHighPriorityApplications().count
                if highPriorityCount > 0 {
                    QuickStatView(
                        title: "High Priority",
                        value: "\(highPriorityCount)",
                        color: .orange
                    )
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct QuickStatView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 70)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Kanban Column View

struct KanbanColumnView: View {
    let status: ApplicationStatus
    let applications: [JobApplication]
    
    @EnvironmentObject var jobManager: JobApplicationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Column Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Circle()
                            .fill(status.color)
                            .frame(width: 8, height: 8)
                        
                        Text(status.rawValue)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    Text("\(applications.count) applications")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Column Actions
                Menu {
                    Button("Add Application Here") {
                        // Add new application with this status
                    }
                    
                    if !applications.isEmpty {
                        Button("Export List") {
                            // Export functionality
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(status.color.opacity(0.1))
            .cornerRadius(8)
            
            // Applications List
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(applications) { application in
                        JobCardView(application: application)
                            .environmentObject(jobManager)
                    }
                }
                .padding(.horizontal, 4)
            }
            
            // Empty State
            if applications.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: emptyStateIcon)
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text(emptyStateMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                )
            }
            
            Spacer()
        }
        .frame(maxHeight: .infinity)
        .padding(8)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var emptyStateIcon: String {
        switch status {
        case .applied: return "paperplane"
        case .screening: return "magnifyingglass"
        case .interviewing: return "person.2"
        case .offer: return "star"
        case .rejected: return "xmark.circle"
        case .withdrawn: return "arrow.uturn.left"
        }
    }
    
    private var emptyStateMessage: String {
        switch status {
        case .applied: return "No applications yet"
        case .screening: return "No screening in progress"
        case .interviewing: return "No interviews scheduled"
        case .offer: return "No offers received"
        case .rejected: return "No rejections"
        case .withdrawn: return "No withdrawn applications"
        }
    }
}

// MARK: - Job Card View

struct JobCardView: View {
    @ObservedObject var application: JobApplication
    @EnvironmentObject var jobManager: JobApplicationManager
    @State private var showingDetail = false
    @State private var showingStatusPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(application.companyName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Text(application.jobTitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Circle()
                        .fill(application.priority.color)
                        .frame(width: 8, height: 8)
                    
                    Button(action: {
                        showingStatusPicker = true
                    }) {
                        Circle()
                            .fill(application.status.color)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            
            // Details
            VStack(alignment: .leading, spacing: 6) {
                if !application.location.isEmpty {
                    Label(application.location, systemImage: "location.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                if !application.salary.isEmpty {
                    Label(application.salary, systemImage: "dollarsign.circle.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Divider()
                .opacity(0.5)
            
            // Footer
            HStack {
                Text(application.applicationDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    if application.followUpDate != nil {
                        Image(systemName: "bell.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    if !application.notes.isEmpty {
                        Image(systemName: "note.text")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    if !application.contactEmail.isEmpty {
                        Image(systemName: "envelope.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .onTapGesture {
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            ApplicationDetailSheet(application: application)
                .environmentObject(jobManager)
        }
        .confirmationDialog("Change Status", isPresented: $showingStatusPicker) {
            ForEach(ApplicationStatus.allCases) { status in
                Button(status.rawValue) {
                    application.updateStatus(status)
                    jobManager.updateApplication(application)
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}

// MARK: - Previews

#Preview("Kanban View") {
    let manager = JobApplicationManager()
    manager.setupSampleData()
    
    return KanbanView()
        .environmentObject(manager)
        .previewInterfaceOrientation(.landscapeLeft)
}

#Preview("Job Card") {
    let application = TaskFactory.createJobApplication(companyName: "Microsoft", jobTitle: "Senior iOS Developer")
    application.salary = "$130,000 - $150,000"
    application.location = "Seattle, WA"
    application.priority = .high
    application.followUpDate = Date()
    application.notes = "Great opportunity with excellent team"
    
    return JobCardView(application: application)
        .environmentObject(JobApplicationManager())
        .frame(width: 280)
        .padding()
}
