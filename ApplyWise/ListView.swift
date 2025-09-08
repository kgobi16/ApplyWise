//
//  ListView.swift
//  ApplyWise
//
//  Created by Tlaitirang Rathete on 8/9/2025.
//

import SwiftUI

struct ListView: View {
    @EnvironmentObject var jobManager: JobApplicationManager
    @State private var searchText = ""
    @State private var selectedStatus: ApplicationStatus?
    @State private var selectedPriority: TaskPriority?
    @State private var sortOrder: SortOrder = .dateDescending
    @State private var showingFilterSheet = false
    @State private var showingExportSheet = false
    @State private var selectedApplications = Set<UUID>()
    @State private var isSelectionMode = false
    @State private var showingBulkActionSheet = false
    
    enum SortOrder: String, CaseIterable, Identifiable {
        case dateDescending = "Newest First"
        case dateAscending = "Oldest First"
        case companyAZ = "Company A-Z"
        case companyZA = "Company Z-A"
        case priorityHigh = "Priority High-Low"
        case priorityLow = "Priority Low-High"
        case status = "Status"
        
        var id: String { self.rawValue }
    }
    
    var filteredAndSortedApplications: [JobApplication] {
        var applications = jobManager.getAllApplications()
        
        // Apply search filter
        if !searchText.isEmpty {
            applications = applications.filter { app in
                app.companyName.localizedCaseInsensitiveContains(searchText) ||
                app.jobTitle.localizedCaseInsensitiveContains(searchText) ||
                app.location.localizedCaseInsensitiveContains(searchText) ||
                app.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply status filter
        if let status = selectedStatus {
            applications = applications.filter { $0.status == status }
        }
        
        // Apply priority filter
        if let priority = selectedPriority {
            applications = applications.filter { $0.priority == priority }
        }
        
        // Apply sorting
        return sortApplications(applications, by: sortOrder)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Summary Bar
                if selectedStatus != nil || selectedPriority != nil {
                    FilterSummaryBar(
                        selectedStatus: $selectedStatus,
                        selectedPriority: $selectedPriority,
                        resultCount: filteredAndSortedApplications.count
                    )
                }
                
                // Quick Stats Header
                if !isSelectionMode {
                    QuickStatsHeader()
                        .environmentObject(jobManager)
                }
                
                // Main List
                List {
                    if filteredAndSortedApplications.isEmpty {
                        EmptyStateView(
                            searchText: searchText,
                            hasFilters: selectedStatus != nil || selectedPriority != nil
                        )
                    } else {
                        // Section headers based on sort order
                        if sortOrder == .status {
                            ForEach(ApplicationStatus.allCases) { status in
                                let statusApplications = filteredAndSortedApplications.filter { $0.status == status }
                                if !statusApplications.isEmpty {
                                    Section(header: StatusSectionHeader(status: status, count: statusApplications.count)) {
                                        ForEach(statusApplications) { application in
                                            ApplicationListRow(
                                                application: application,
                                                isSelected: selectedApplications.contains(application.id),
                                                selectionMode: isSelectionMode,
                                                onSelectionToggle: { toggleSelection(for: application.id) }
                                            )
                                            .environmentObject(jobManager)
                                        }
                                    }
                                }
                            }
                        } else if sortOrder == .priorityHigh || sortOrder == .priorityLow {
                            ForEach(TaskPriority.allCases.reversed()) { priority in
                                let priorityApplications = filteredAndSortedApplications.filter { $0.priority == priority }
                                if !priorityApplications.isEmpty {
                                    Section(header: PrioritySectionHeader(priority: priority, count: priorityApplications.count)) {
                                        ForEach(priorityApplications) { application in
                                            ApplicationListRow(
                                                application: application,
                                                isSelected: selectedApplications.contains(application.id),
                                                selectionMode: isSelectionMode,
                                                onSelectionToggle: { toggleSelection(for: application.id) }
                                            )
                                            .environmentObject(jobManager)
                                        }
                                    }
                                }
                            }
                        } else {
                            // Single section for other sort orders
                            Section {
                                ForEach(filteredAndSortedApplications) { application in
                                    ApplicationListRow(
                                        application: application,
                                        isSelected: selectedApplications.contains(application.id),
                                        selectionMode: isSelectionMode,
                                        onSelectionToggle: { toggleSelection(for: application.id) }
                                    )
                                    .environmentObject(jobManager)
                                }
                                .onDelete(perform: deleteApplications)
                            }
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search applications...")
                .refreshable {
                    // Refresh functionality
                    jobManager.setupSampleData()
                }
            }
            .navigationTitle(isSelectionMode ? "\(selectedApplications.count) Selected" : "Applications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    if isSelectionMode {
                        Button("Cancel") {
                            exitSelectionMode()
                        }
                    } else {
                        Button(action: {
                            showingFilterSheet = true
                        }) {
                            Label("Filter", systemImage: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .foregroundColor(hasActiveFilters ? .blue : .primary)
                        }
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if isSelectionMode {
                        Button("Actions") {
                            showingBulkActionSheet = true
                        }
                        .disabled(selectedApplications.isEmpty)
                    } else {
                        Menu {
                            Menu("Sort by") {
                                ForEach(SortOrder.allCases) { order in
                                    Button(action: { sortOrder = order }) {
                                        HStack {
                                            Text(order.rawValue)
                                            if sortOrder == order {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Divider()
                            
                            Button("Select Multiple") {
                                enterSelectionMode()
                            }
                            
                            Button("Export All") {
                                showingExportSheet = true
                            }
                            
                            Button("Refresh Data") {
                                jobManager.setupSampleData()
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheetView(
                    selectedStatus: $selectedStatus,
                    selectedPriority: $selectedPriority
                )
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportSheetView(applications: getApplicationsToExport())
            }
            .confirmationDialog("Bulk Actions", isPresented: $showingBulkActionSheet) {
                Button("Delete Selected", role: .destructive) {
                    deleteSelectedApplications()
                }
                
                Button("Mark as High Priority") {
                    setBulkPriority(.high)
                }
                
                Button("Mark as Low Priority") {
                    setBulkPriority(.low)
                }
                
                Button("Move to Interviewing") {
                    setBulkStatus(.interviewing)
                }
                
                Button("Export Selected") {
                    showingExportSheet = true
                }
                
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func sortApplications(_ applications: [JobApplication], by order: SortOrder) -> [JobApplication] {
        switch order {
        case .dateDescending:
            return applications.sorted { $0.applicationDate > $1.applicationDate }
        case .dateAscending:
            return applications.sorted { $0.applicationDate < $1.applicationDate }
        case .companyAZ:
            return applications.sorted { $0.companyName.localizedCaseInsensitiveCompare($1.companyName) == .orderedAscending }
        case .companyZA:
            return applications.sorted { $0.companyName.localizedCaseInsensitiveCompare($1.companyName) == .orderedDescending }
        case .priorityHigh:
            return applications.sorted { priorityValue($0.priority) > priorityValue($1.priority) }
        case .priorityLow:
            return applications.sorted { priorityValue($0.priority) < priorityValue($1.priority) }
        case .status:
            return applications.sorted { statusValue($0.status) < statusValue($1.status) }
        }
    }
    
    private func priorityValue(_ priority: TaskPriority) -> Int {
        switch priority {
        case .urgent: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
    
    private func statusValue(_ status: ApplicationStatus) -> Int {
        switch status {
        case .applied: return 1
        case .screening: return 2
        case .interviewing: return 3
        case .offer: return 4
        case .rejected: return 5
        case .withdrawn: return 6
        }
    }
    
    private var hasActiveFilters: Bool {
        selectedStatus != nil || selectedPriority != nil
    }
    
    private func toggleSelection(for id: UUID) {
        if selectedApplications.contains(id) {
            selectedApplications.remove(id)
        } else {
            selectedApplications.insert(id)
        }
    }
    
    private func enterSelectionMode() {
        isSelectionMode = true
        selectedApplications.removeAll()
    }
    
    private func exitSelectionMode() {
        isSelectionMode = false
        selectedApplications.removeAll()
    }
    
    private func deleteApplications(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let application = filteredAndSortedApplications[index]
                jobManager.deleteApplication(withId: application.id)
            }
        }
    }
    
    private func deleteSelectedApplications() {
        withAnimation {
            for id in selectedApplications {
                jobManager.deleteApplication(withId: id)
            }
            exitSelectionMode()
        }
    }
    
    private func setBulkPriority(_ priority: TaskPriority) {
        for id in selectedApplications {
            if let application = jobManager.getAllApplications().first(where: { $0.id == id }) {
                application.priority = priority
                jobManager.updateApplication(application)
            }
        }
        exitSelectionMode()
    }
    
    private func setBulkStatus(_ status: ApplicationStatus) {
        for id in selectedApplications {
            if let application = jobManager.getAllApplications().first(where: { $0.id == id }) {
                application.updateStatus(status)
                jobManager.updateApplication(application)
            }
        }
        exitSelectionMode()
    }
    
    private func getApplicationsToExport() -> [JobApplication] {
        if isSelectionMode && !selectedApplications.isEmpty {
            return filteredAndSortedApplications.filter { selectedApplications.contains($0.id) }
        } else {
            return filteredAndSortedApplications
        }
    }
}

// MARK: - Quick Stats Header

struct QuickStatsHeader: View {
    @EnvironmentObject var jobManager: JobApplicationManager
    
    var body: some View {
        let stats = jobManager.getApplicationStats()
        
        HStack(spacing: 16) {
            QuickStatItem(title: "Total", value: "\(stats.total)", color: .blue)
            QuickStatItem(title: "Active", value: "\(stats.pending + stats.interviews)", color: .orange)
            QuickStatItem(title: "Success", value: String(format: "%.0f%%", stats.successRate), color: .green)
            QuickStatItem(title: "Follow-ups", value: "\(jobManager.getFollowUpsDue().count)", color: .red)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

struct QuickStatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Application List Row

struct ApplicationListRow: View {
    @ObservedObject var application: JobApplication
    @EnvironmentObject var jobManager: JobApplicationManager
    @State private var showingDetail = false
    
    let isSelected: Bool
    let selectionMode: Bool
    let onSelectionToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection Circle
            if selectionMode {
                Button(action: onSelectionToggle) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .gray)
                        .font(.title2)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Main Content
            VStack(alignment: .leading, spacing: 8) {
                // Header Row
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(application.companyName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(application.jobTitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        // Status Badge
                        Text(application.status.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(application.status.color.opacity(0.2))
                            .foregroundColor(application.status.color)
                            .cornerRadius(12)
                        
                        // Priority Indicator
                        HStack(spacing: 4) {
                            Circle()
                                .fill(application.priority.color)
                                .frame(width: 6, height: 6)
                            Text(application.priority.rawValue)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Details Row
                HStack {
                    // Location & Salary
                    VStack(alignment: .leading, spacing: 2) {
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
                    
                    Spacer()
                    
                    // Date and Indicators
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(application.applicationDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 6) {
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
                
                // Progress Indicator (if needed)
                if let followUp = application.followUpDate, followUp <= Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date() {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        
                        Text("Follow-up due soon!")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                }
            }
            .padding(.vertical, 4)
            
            // Action Buttons
            if !selectionMode {
                VStack(spacing: 8) {
                    Button(action: { showingDetail = true }) {
                        Image(systemName: "info.circle")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    StatusQuickActionButton(application: application)
                        .environmentObject(jobManager)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if selectionMode {
                onSelectionToggle()
            } else {
                showingDetail = true
            }
        }
        .sheet(isPresented: $showingDetail) {
            ApplicationDetailSheet(application: application)
                .environmentObject(jobManager)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Delete", role: .destructive) {
                jobManager.deleteApplication(withId: application.id)
            }
            
            Button("Edit") {
                showingDetail = true
            }
            .tint(.blue)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button("Follow Up") {
                application.followUpDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())
                jobManager.updateApplication(application)
            }
            .tint(.orange)
        }
    }
}

// MARK: - Supporting Views

struct FilterSummaryBar: View {
    @Binding var selectedStatus: ApplicationStatus?
    @Binding var selectedPriority: TaskPriority?
    let resultCount: Int
    
    var body: some View {
        HStack {
            Text("\(resultCount) results")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack(spacing: 8) {
                if let status = selectedStatus {
                    FilterChip(title: status.rawValue, color: status.color) {
                        selectedStatus = nil
                    }
                }
                
                if let priority = selectedPriority {
                    FilterChip(title: priority.rawValue, color: priority.color) {
                        selectedPriority = nil
                    }
                }
                
                if selectedStatus != nil || selectedPriority != nil {
                    Button("Clear All") {
                        selectedStatus = nil
                        selectedPriority = nil
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }
}

struct FilterChip: View {
    let title: String
    let color: Color
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color)
        .cornerRadius(12)
    }
}

struct StatusSectionHeader: View {
    let status: ApplicationStatus
    let count: Int
    
    var body: some View {
        HStack {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            
            Text(status.rawValue)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("(\(count))")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct PrioritySectionHeader: View {
    let priority: TaskPriority
    let count: Int
    
    var body: some View {
        HStack {
            Circle()
                .fill(priority.color)
                .frame(width: 8, height: 8)
            
            Text("\(priority.rawValue) Priority")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("(\(count))")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct StatusQuickActionButton: View {
    @ObservedObject var application: JobApplication
    @EnvironmentObject var jobManager: JobApplicationManager
    
    var nextStatus: ApplicationStatus? {
        switch application.status {
        case .applied: return .screening
        case .screening: return .interviewing
        case .interviewing: return .offer
        case .offer, .rejected, .withdrawn: return nil
        }
    }
    
    var body: some View {
        if let next = nextStatus {
            Button(action: {
                application.updateStatus(next)
                jobManager.updateApplication(application)
            }) {
                Image(systemName: "arrow.right.circle")
                    .font(.title3)
                    .foregroundColor(next.color)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct EmptyStateView: View {
    let searchText: String
    let hasFilters: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "tray" : "magnifyingglass")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            if !searchText.isEmpty {
                Text("No results for \"\(searchText)\"")
                    .font(.headline)
                Text("Try adjusting your search or filters")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else if hasFilters {
                Text("No applications match your filters")
                    .font(.headline)
                Text("Try adjusting your filter criteria")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("No applications yet")
                    .font(.headline)
                Text("Start by adding your first job application")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Filter Sheet

struct FilterSheetView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedStatus: ApplicationStatus?
    @Binding var selectedPriority: TaskPriority?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Status") {
                    Picker("Status Filter", selection: $selectedStatus) {
                        Text("All Statuses").tag(ApplicationStatus?.none)
                        ForEach(ApplicationStatus.allCases) { status in
                            HStack {
                                Circle()
                                    .fill(status.color)
                                    .frame(width: 12, height: 12)
                                Text(status.rawValue)
                            }
                            .tag(ApplicationStatus?.some(status))
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                }
                
                Section("Priority") {
                    Picker("Priority Filter", selection: $selectedPriority) {
                        Text("All Priorities").tag(TaskPriority?.none)
                        ForEach(TaskPriority.allCases) { priority in
                            HStack {
                                Circle()
                                    .fill(priority.color)
                                    .frame(width: 12, height: 12)
                                Text(priority.rawValue)
                            }
                            .tag(TaskPriority?.some(priority))
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                }
            }
            .navigationTitle("Filter Applications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") {
                        selectedStatus = nil
                        selectedPriority = nil
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Export Sheet

struct ExportSheetView: View {
    @Environment(\.presentationMode) var presentationMode
    let applications: [JobApplication]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export \(applications.count) Applications")
                    .font(.headline)
                    .padding()
                
                VStack(spacing: 16) {
                    Button("Export as CSV") {
                        exportAsCSV()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Export as PDF Report") {
                        exportAsPDF()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Share Summary") {
                        shareSummary()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Export Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func exportAsCSV() {
        // CSV export logic would go here
        print("Exporting \(applications.count) applications as CSV")
        presentationMode.wrappedValue.dismiss()
    }
    
    private func exportAsPDF() {
        // PDF export logic would go here
        print("Exporting \(applications.count) applications as PDF")
        presentationMode.wrappedValue.dismiss()
    }
    
    private func shareSummary() {
        // Share summary logic would go here
        print("Sharing summary of \(applications.count) applications")
        presentationMode.wrappedValue.dismiss()
    }
}



// MARK: - Previews

#Preview("List View") {
    let manager = JobApplicationManager()
    manager.setupSampleData()
    
    return ListView()
        .environmentObject(manager)
}

#Preview("Application List Row") {
    let application = TaskFactory.createJobApplication(companyName: "Apple Inc", jobTitle: "Senior iOS Developer")
    application.priority = .high
    application.salary = "$120,000 - $150,000"
    application.location = "Cupertino, CA"
    application.followUpDate = Date()
    application.notes = "Great opportunity with excellent benefits"
    
    return ApplicationListRow(
        application: application,
        isSelected: false,
        selectionMode: false,
        onSelectionToggle: {}
    )
    .environmentObject(JobApplicationManager())
    .padding()
}

#Preview("Filter Summary Bar") {
    FilterSummaryBar(
        selectedStatus: .constant(.interviewing),
        selectedPriority: .constant(.high),
        resultCount: 5
    )
}

#Preview("Quick Stats Header") {
    let manager = JobApplicationManager()
    manager.setupSampleData()
    
    return QuickStatsHeader()
        .environmentObject(manager)
}
