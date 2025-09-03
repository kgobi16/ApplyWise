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
    @State private var draggedApplication: JobApplication?
    
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
    
    //Landscape Layout (Primary)
    
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
                            applications: jobManager.getApplications(by: status),
                            onDrop: { application in
                                handleStatusChange(application: application, newStatus: status)
                            }
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
    
    //Portrait Layout (Fallback)
    
    @ViewBuilder
    private func portraitLayout(geometry: GeometryProxy) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(ApplicationStatus.allCases) { status in
                    KanbanColumnView(
                        status: status,
                        applications: jobManager.getApplications(by: status),
                        onDrop: { application in
                            handleStatusChange(application: application, newStatus: status)
                        }
                    )
                    .frame(width: 280)
                }
            }
            .padding()
        }
    }
    
    //Helper Methods
    
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
    
    private func handleStatusChange(application: JobApplication, newStatus: ApplicationStatus) {
        application.updateStatus(newStatus)
        jobManager.updateApplication(application)
    }
}

//Kanban Header View

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

// Kanban Column View

struct KanbanColumnView: View {
    let status: ApplicationStatus
    let applications: [JobApplication]
    let onDrop: (JobApplication) -> Void
    
    @EnvironmentObject var jobManager: JobApplicationManager
    @State private var isTargeted = false
    
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
                            .draggable(application) {
                                JobCardPreview(application: application)
                            }
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
        .scaleEffect(isTargeted ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isTargeted)
        .dropDestination(for: JobApplication.self) { applications, location in
            guard let application = applications.first else { return false }
            onDrop(application)
            return true
        } isTargeted: { isTargeted in
            self.isTargeted = isTargeted
        }
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

//Job Card View

struct JobCardView: View {
    @ObservedObject var application: JobApplication
    @EnvironmentObject var jobManager: JobApplicationManager
    @State private var showingDetail = false
    
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
                    
                    Circle()
                        .fill(application.status.color)
                        .frame(width: 12, height: 12)
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
    }
}

// Job Card Preview for Drag

struct JobCardPreview: View {
    let application: JobApplication
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(application.companyName)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(application.jobTitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 4)
        .frame(width: 200)
    }
}

// Add Job Application Sheet

struct AddJobApplicationSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var companyName = ""
    @State private var jobTitle = ""
    @State private var contactEmail = ""
    @State private var notes = ""
    @State private var salary = ""
    @State private var location = ""
    @State private var priority: TaskPriority = .medium
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let onSave: (JobApplication) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Job Details") {
                    TextField("Company Name", text: $companyName)
                    TextField("Job Title", text: $jobTitle)
                    TextField("Location", text: $location)
                    TextField("Salary (optional)", text: $salary)
                }
                
                Section("Contact") {
                    TextField("Contact Email", text: $contactEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases) { priority in
                            HStack {
                                Circle()
                                    .fill(priority.color)
                                    .frame(width: 12, height: 12)
                                Text(priority.rawValue)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Application")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveApplication()
                    }
                    .disabled(companyName.isEmpty || jobTitle.isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveApplication() {
        let application = JobApplication(
            companyName: companyName.trimmingCharacters(in: .whitespacesAndNewlines),
            jobTitle: jobTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            contactEmail: contactEmail.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            salary: salary.trimmingCharacters(in: .whitespacesAndNewlines),
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            priority: priority
        )
        
        do {
            try application.validate()
            onSave(application)
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// Application Detail Sheet

struct ApplicationDetailSheet: View {
    @ObservedObject var application: JobApplication
    @EnvironmentObject var jobManager: JobApplicationManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(application.companyName)
                            .font(.title)
                            .bold()
                        
                        Text(application.jobTitle)
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Label(application.status.rawValue, systemImage: "circle.fill")
                                .foregroundColor(application.status.color)
                            
                            Spacer()
                            
                            Label(application.priority.rawValue, systemImage: "flag.fill")
                                .foregroundColor(application.priority.color)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Details
                    VStack(alignment: .leading, spacing: 16) {
                        if !application.location.isEmpty {
                            DetailRowView(title: "Location", value: application.location, icon: "location")
                        }
                        
                        if !application.salary.isEmpty {
                            DetailRowView(title: "Salary", value: application.salary, icon: "dollarsign.circle")
                        }
                        
                        if !application.contactEmail.isEmpty {
                            DetailRowView(title: "Contact", value: application.contactEmail, icon: "envelope")
                        }
                        
                        DetailRowView(title: "Applied", value: application.applicationDate.formatted(date: .complete, time: .omitted), icon: "calendar")
                        
                        if let followUp = application.followUpDate {
                            DetailRowView(title: "Follow Up", value: followUp.formatted(date: .complete, time: .omitted), icon: "bell")
                        }
                        
                        if !application.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Notes", systemImage: "note.text")
                                    .font(.headline)
                                
                                Text(application.notes)
                                    .padding()
                                    .background(Color.gray.opacity(0.05))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Application Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct DetailRowView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.headline)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

//Drag and Drop Extensions

extension JobApplication: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(for: JobApplication.self, contentType: .jobApplication)
    }
}

extension UTType {
    static var jobApplication = UTType(exportedAs: "com.applywise.jobapplication")
}

// Previews (With dummy data)

#Preview("Kanban View") {
    let manager = JobApplicationManager()
    manager.setupSampleData()
    
    return KanbanView()
        .environmentObject(manager)
        .previewInterfaceOrientation(.landscapeLeft)
}

#Preview("Kanban Column") {
    let manager = JobApplicationManager()
    let sample1 = TaskFactory.createJobApplication(companyName: "Apple Inc", jobTitle: "iOS Developer")
    sample1.priority = .high
    sample1.salary = "$120,000"
    sample1.location = "Cupertino, CA"
    
    let sample2 = TaskFactory.createJobApplication(companyName: "Google", jobTitle: "Mobile Engineer")
    sample2.priority = .medium
    sample2.followUpDate = Date()
    
    return KanbanColumnView(
        status: .applied,
        applications: [sample1, sample2],
        onDrop: { _ in }
    )
    .environmentObject(manager)
    .frame(width: 300, height: 500)
    .padding()
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
