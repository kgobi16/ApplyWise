//
//  ContentView.swift
//  ApplyWise
//
//  Created by Tlaitirang Rathete on 3/9/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var jobManager = JobApplicationManager()
    @State private var selectedTab = 1

    
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
            
            // Tab 2: Analytics
            AnalyticsView()
                .environmentObject(jobManager)
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Analytics")
                }
                .tag(1)
            
            // Tab 3: List View 
            ListView()
                .environmentObject(jobManager)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("List")
                }
                .tag(2)
            
            // Tab 4: Add Application (Quick Access)
            QuickAddView()
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
    
    return QuickAddView()
        .environmentObject(manager)
}
