//
//  ContentView.swift
//  ApplyWise
//
//  Created by Tlaitirang Rathete on 3/9/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var jobManager = JobApplicationManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Kanban Board
            KanbanView()
                .environmentObject(jobManager)
                .tabItem {
                    Image(systemName: "rectangle.3.offgrid")
                    Text("Board")
                }
                .tag(0)
            
            // Tab 2: Analytics placeholder
            AnalyticsView()
                .environmentObject(jobManager)
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Analytics")
                }
                .tag(1)
            
            // Tab 3: List View placeholder
            ListPlaceholderView()
                .environmentObject(jobManager)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("List")
                }
                .tag(2)
            
            // Tab 4: Add Application (Quick Access)
            AddApplicationPlaceholderView()
                .environmentObject(jobManager)
                .tabItem {
                    Image(systemName: "plus.circle")
                    Text("Add")
                }
                .tag(3)
        }
        .onAppear {
            // Load sample data when the app starts
            jobManager.setupSampleData()
        }
    }
}

// Placeholder Views (We'll replace these in next steps)


struct ListPlaceholderView: View {
    @EnvironmentObject var jobManager: JobApplicationManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Applications List")
                    .font(.largeTitle)
                    .bold()
                
                
                // Show a simple list preview
                List {
                    ForEach(jobManager.applications.prefix(5)) { application in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(application.companyName)
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text(application.status.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(application.status.color.opacity(0.2))
                                    .foregroundColor(application.status.color)
                                    .cornerRadius(8)
                            }
                            
                            Text(application.jobTitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Applications")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AddApplicationPlaceholderView: View {
    @EnvironmentObject var jobManager: JobApplicationManager
    @State private var companyName = ""
    @State private var jobTitle = ""
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Quick Add Application")
                    .font(.largeTitle)
                    .bold()
                
                
                VStack(spacing: 16) {
                    TextField("Company Name", text: $companyName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Job Title", text: $jobTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: addApplication) {
                        Text("Add Application")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                (companyName.isEmpty || jobTitle.isEmpty) ? Color.gray : Color.blue
                            )
                            .cornerRadius(12)
                    }
                    .disabled(companyName.isEmpty || jobTitle.isEmpty)
                }
                .padding()
                
                if !jobManager.applications.isEmpty {
                    Text("Recent additions:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(jobManager.applications.suffix(3).reversed()) { app in
                            Text("✓ \(app.jobTitle) at \(app.companyName)")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Application")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Application Added!", isPresented: $showingSuccess) {
                Button("OK") {
                    companyName = ""
                    jobTitle = ""
                }
            } message: {
                Text("Your application to \(companyName) has been added successfully!")
            }
        }
    }
    
    private func addApplication() {
        let newApplication = TaskFactory.createJobApplication(
            companyName: companyName.trimmingCharacters(in: .whitespacesAndNewlines),
            jobTitle: jobTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        jobManager.addApplication(newApplication)
        showingSuccess = true
    }
}

//Helper Views

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



// Previews

#Preview("Content View") {
    ContentView()
}

#Preview("Kanban Placeholder") {
    let manager = JobApplicationManager()
    manager.setupSampleData()
    
    return KanbanView()
        .environmentObject(manager)
}

#Preview("Analytics Placeholder") {
    let manager = JobApplicationManager()
    manager.setupSampleData()
    
    return AnalyticsView()
        .environmentObject(manager)
}

#Preview("Add Application Placeholder") {
    let manager = JobApplicationManager()
    manager.setupSampleData()
    
    return AddApplicationPlaceholderView()
        .environmentObject(manager)
}
