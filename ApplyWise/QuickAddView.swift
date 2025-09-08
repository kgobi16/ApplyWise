//
//  QuickAddView.swift
//  ApplyWise
//
//  Created by Tlaitirang Rathete on 8/9/2025.
//

import SwiftUI

//Quick Add View (Uses SharedViews components)

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
                
                // Recent additions section
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
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        
                        Text("No applications yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Add your first job application to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding(.vertical)
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        jobManager.setupSampleData()
                    }
                }
            }
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

// MARK: - Recent Application Row

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

// MARK: - Helper Views (Shared with other views)

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

// MARK: - Previews

#Preview("Quick Add View") {
    let manager = JobApplicationManager()
    manager.setupSampleData()
    
    return QuickAddView()
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
