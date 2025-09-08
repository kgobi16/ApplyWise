//
//  SharedViews.swift
//  ApplyWise
//
//  Created by Tlaitirang Rathete on 8/9/2025.
//

import SwiftUI

//Application Detail Sheet (Shared Component)

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
                    
                    //Job Details
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

// Detail Row View (Shared Component)

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

// Add Job Application Sheet (Shared Component)

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

// MARK: - Previews

#Preview("Application Detail Sheet") {
    let application = TaskFactory.createJobApplication(
        companyName: "Apple Inc",
        jobTitle: "Senior iOS Developer"
    )
    application.contactEmail = "jobs@apple.com"
    application.salary = "$120,000 - $150,000"
    application.location = "Cupertino, CA"
    application.notes = "Exciting opportunity to work on cutting-edge iOS applications."
    application.priority = .high
    application.followUpDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())
    
    return ApplicationDetailSheet(application: application)
        .environmentObject(JobApplicationManager())
}

#Preview("Detail Row") {
    VStack(spacing: 8) {
        DetailRowView(title: "Location", value: "Cupertino, CA", icon: "location")
        DetailRowView(title: "Salary", value: "$120,000", icon: "dollarsign.circle")
        DetailRowView(title: "Contact", value: "jobs@apple.com", icon: "envelope")
    }
    .padding()
}

#Preview("Add Application Sheet") {
    AddJobApplicationSheet { application in
        print("Added: \(application.companyName)")
    }
}
