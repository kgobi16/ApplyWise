//
//  QuickAddView.swift
//  ApplyWise
//
//  Created by Tlaitirang Rathete on 8/9/2025.
//

import SwiftUI

// Quick Add View (Uses SharedViews components)
struct QuickAddView: View {
    @EnvironmentObject var jobManager: JobApplicationManager
    @State private var showingAddSheet = false
    @State private var errorAlert: AppError?
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Add New Application")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Tap the button below to add a new job application with full details")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Add Button - Opens SharedViews AddJobApplicationSheet
                Button(action: {
                    showingAddSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Job Application")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Recent additions section or welcome message
                if !jobManager.applications.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Recent Applications")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("\(jobManager.applications.count) total")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(jobManager.applications.suffix(5).reversed()) { app in
                                RecentApplicationRow(application: app)
                                    .onTapGesture {
                                        // Could open detail view here
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    // Welcome state with helpful information
                    VStack(spacing: 20) {
                        VStack(spacing: 12) {
                            Image(systemName: "briefcase")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            
                            Text("Welcome to ApplyWise")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Track your job applications, monitor your progress, and never miss a follow-up again.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What you can track:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                FeatureRow(icon: "building.2", text: "Company and job details")
                                FeatureRow(icon: "person.crop.circle", text: "Contact information")
                                FeatureRow(icon: "flag", text: "Application priority levels")
                                FeatureRow(icon: "bell", text: "Follow-up reminders")
                                FeatureRow(icon: "chart.bar", text: "Success analytics")
                            }
                        }
                        .padding()
                        .background(Color(.systemGroupedBackground))
                        .cornerRadius(12)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding(.vertical)
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAddSheet) {
                // Using the SharedViews component - same as KanbanView
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
    }
    
    // Same error handling pattern as KanbanView and ListView
    private func handleAddApplication(_ application: JobApplication) {
        do {
            try application.validate()
            jobManager.addApplication(application)
            showingAddSheet = false
        } catch let error as AppError {
            errorAlert = error
            showingError = true
        } catch {
            errorAlert = .saveFailed
            showingError = true
        }
    }
}

// Feature row for welcome screen
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// Recent application row component
struct RecentApplicationRow: View {
    let application: JobApplication
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(application.status.color)
                .frame(width: 8, height: 8)
            
            // Application info
            VStack(alignment: .leading, spacing: 2) {
                Text("\(application.jobTitle) at \(application.companyName)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack {
                    Text(application.applicationDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(application.status.rawValue)
                        .font(.caption)
                        .foregroundColor(application.status.color)
                    
                    if !application.location.isEmpty {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(application.location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Priority and status indicators
            VStack(spacing: 4) {
                Circle()
                    .fill(application.priority.color)
                    .frame(width: 6, height: 6)
                
                if application.followUpDate != nil {
                    Image(systemName: "bell.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(application.priority.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// Helper views (Shared with other views)
struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title)
                .bold()
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// Preview configurations
#Preview("Quick Add View") {
    let manager = JobApplicationManager()
    QuickAddView()
        .environmentObject(manager)
}

#Preview("Quick Add View - Empty State") {
    let manager = JobApplicationManager()
    // Don't setup sample data to show empty state
    
    return QuickAddView()
        .environmentObject(manager)
}

#Preview("Recent Application Row") {
    let application = TaskFactory.createJobApplication(companyName: "Apple Inc", jobTitle: "Senior iOS Developer")
    application.priority = .high
    application.status = .interviewing
    application.location = "Cupertino, CA"
    application.followUpDate = Date()
    
    return RecentApplicationRow(application: application)
        .padding()
}

#Preview("Stat Card") {
    HStack {
        StatCard(title: "Total", value: "24", color: .blue)
        StatCard(title: "Success", value: "12%", color: .green)
    }
    .padding()
}
