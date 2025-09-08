//
//  AnalyticsView.swift
//  ApplyWise
//
//  Created by Tlaitirang Rathete on 8/9/2025.
//

import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject var jobManager: JobApplicationManager
    @State private var selectedTimeRange: TimeRange = .month
    @State private var selectedChart: ChartType = .status
    
    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
        
        var id: String { self.rawValue }
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            case .year: return 365
            }
        }
    }
    
    enum ChartType: String, CaseIterable, Identifiable {
        case status = "Status Distribution"
        case timeline = "Application Timeline"
        case success = "Success Metrics"
        case priority = "Priority Analysis"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Controls
                    VStack(spacing: 16) {
                        // Time Range Picker
                        Picker("Time Range", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        // Chart Type Picker
                        Picker("Chart Type", selection: $selectedChart) {
                            ForEach(ChartType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(12)
                    
                    // Key Metrics Dashboard
                    KeyMetricsDashboard()
                        .environmentObject(jobManager)
                    
                    // Main Chart
                    VStack(alignment: .leading, spacing: 16) {
                        Text(selectedChart.rawValue)
                            .font(.headline)
                            .padding(.horizontal)
                        
                        switch selectedChart {
                        case .status:
                            StatusDistributionChart()
                                .environmentObject(jobManager)
                        case .timeline:
                            ApplicationTimelineChart(timeRange: selectedTimeRange)
                                .environmentObject(jobManager)
                        case .success:
                            SuccessMetricsChart()
                                .environmentObject(jobManager)
                        case .priority:
                            PriorityAnalysisChart()
                                .environmentObject(jobManager)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .gray.opacity(0.1), radius: 4)
                    
                    // Insights and Recommendations
                    InsightsSection()
                        .environmentObject(jobManager)
                    
                    // Detailed Statistics
                    DetailedStatisticsSection(timeRange: selectedTimeRange)
                        .environmentObject(jobManager)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Export Data") {
                            exportAnalyticsData()
                        }
                        Button("Share Report") {
                            shareAnalyticsReport()
                        }
                        Button("Refresh Data") {
                            jobManager.setupSampleData()
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
    
    private func exportAnalyticsData() {
        // Export functionality would go here
        print("Exporting analytics data...")
    }
    
    private func shareAnalyticsReport() {
        // Share functionality would go here
        print("Sharing analytics report...")
    }
}

// MARK: - Key Metrics Dashboard

struct KeyMetricsDashboard: View {
    @EnvironmentObject var jobManager: JobApplicationManager
    
    var body: some View {
        let stats = jobManager.getApplicationStats()
        
        VStack(spacing: 16) {
            // Primary Metrics
            HStack(spacing: 12) {
                MetricCard(
                    title: "Total Applications",
                    value: "\(stats.total)",
                    subtitle: "All time",
                    color: .blue,
                    icon: "paperplane.fill"
                )
                
                MetricCard(
                    title: "Success Rate",
                    value: String(format: "%.1f%%", stats.successRate),
                    subtitle: "Offers/Total",
                    color: stats.successRate >= 10 ? .green : .orange,
                    icon: "target"
                )
            }
            
            HStack(spacing: 12) {
                MetricCard(
                    title: "Interview Rate",
                    value: String(format: "%.1f%%", stats.interviewRate),
                    subtitle: "Interviews/Total",
                    color: stats.interviewRate >= 20 ? .green : .orange,
                    icon: "person.2.fill"
                )
                
                MetricCard(
                    title: "Active Apps",
                    value: "\(stats.pending + stats.interviews)",
                    subtitle: "\(stats.pending) pending",
                    color: .purple,
                    icon: "clock.fill"
                )
            }
            
            // Weekly Progress Bar
            WeeklyProgressView()
                .environmentObject(jobManager)
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct WeeklyProgressView: View {
    @EnvironmentObject var jobManager: JobApplicationManager
    
    var body: some View {
        let thisWeekApps = jobManager.getApplicationsThisWeek().count
        let lastWeekApps = getLastWeekApplications()
        
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Weekly Progress")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(thisWeekApps) this week")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 8) {
                Text("Last week: \(lastWeekApps)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                let change = thisWeekApps - lastWeekApps
                if change > 0 {
                    Label("+\(change)", systemImage: "arrow.up")
                        .font(.caption)
                        .foregroundColor(.green)
                } else if change < 0 {
                    Label("\(change)", systemImage: "arrow.down")
                        .font(.caption)
                        .foregroundColor(.red)
                } else {
                    Label("0", systemImage: "minus")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                let maxApplications = max(thisWeekApps, lastWeekApps, 1)
                let progress = Double(thisWeekApps) / Double(maxApplications)
                
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func getLastWeekApplications() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let twoWeeksAgo = calendar.date(byAdding: .weekOfYear, value: -2, to: now) ?? now
        let oneWeekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        
        return jobManager.getAllApplications().filter {
            $0.applicationDate >= twoWeeksAgo && $0.applicationDate < oneWeekAgo
        }.count
    }
}

// MARK: - Chart Views

struct StatusDistributionChart: View {
    @EnvironmentObject var jobManager: JobApplicationManager
    
    var chartData: [ChartDataPoint] {
        ApplicationStatus.allCases.map { status in
            let count = jobManager.getApplications(by: status).count
            return ChartDataPoint(category: status.rawValue, value: Double(count), color: status.color)
        }.filter { $0.value > 0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if chartData.isEmpty {
                EmptyChartView(message: "No application data available")
            } else {
                // Bar Chart Representation
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(chartData, id: \.category) { dataPoint in
                        VStack(spacing: 4) {
                            Rectangle()
                                .fill(dataPoint.color)
                                .frame(width: 40, height: CGFloat(dataPoint.value * 20))
                                .cornerRadius(4)
                                .animation(.easeInOut, value: dataPoint.value)
                            
                            Text("\(Int(dataPoint.value))")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Text(dataPoint.category)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .rotationEffect(.degrees(-45))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                
                // Legend
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(chartData, id: \.category) { dataPoint in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(dataPoint.color)
                                .frame(width: 12, height: 12)
                            
                            Text(dataPoint.category)
                                .font(.caption)
                            
                            Spacer()
                            
                            Text("\(Int(dataPoint.value))")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                .cornerRadius(8)
            }
        }
    }
}

struct ApplicationTimelineChart: View {
    @EnvironmentObject var jobManager: JobApplicationManager
    let timeRange: AnalyticsView.TimeRange
    
    var timelineData: [TimelinePoint] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -timeRange.days, to: endDate) ?? endDate
        
        var data: [TimelinePoint] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let applicationsCount = jobManager.getAllApplications().filter { app in
                calendar.isDate(app.applicationDate, inSameDayAs: currentDate)
            }.count
            
            data.append(TimelinePoint(
                date: currentDate,
                applications: applicationsCount
            ))
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return data
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if timelineData.allSatisfy({ $0.applications == 0 }) {
                EmptyChartView(message: "No applications in selected time range")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(timelineData.indices, id: \.self) { index in
                            let point = timelineData[index]
                            
                            VStack(spacing: 2) {
                                Rectangle()
                                    .fill(Color.blue.opacity(0.7))
                                    .frame(width: 20, height: CGFloat(point.applications * 30))
                                    .cornerRadius(2)
                                
                                if timeRange == .week || index % 7 == 0 {
                                    Text(point.date.formatted(.dateTime.day().month(.abbreviated)))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .rotationEffect(.degrees(-45))
                                }
                            }
                        }
                    }
                    .padding()
                }
                .frame(height: 200)
                
                // Summary
                let totalApps = timelineData.reduce(0) { $0 + $1.applications }
                let avgPerDay = timeRange.days > 0 ? Double(totalApps) / Double(timeRange.days) : 0
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Total: \(totalApps)")
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("Avg/day: \(String(format: "%.1f", avgPerDay))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("Last \(timeRange.rawValue.lowercased())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                .cornerRadius(8)
            }
        }
    }
}

struct SuccessMetricsChart: View {
    @EnvironmentObject var jobManager: JobApplicationManager
    
    var body: some View {
        let stats = jobManager.getApplicationStats()
        
        VStack(spacing: 16) {
            // Funnel Chart
            VStack(spacing: 8) {
                FunnelBarView(
                    title: "Applications",
                    count: stats.total,
                    percentage: 100.0,
                    color: .blue
                )
                
                FunnelBarView(
                    title: "Interviews",
                    count: stats.interviews,
                    percentage: stats.interviewRate,
                    color: .purple
                )
                
                FunnelBarView(
                    title: "Offers",
                    count: stats.offers,
                    percentage: stats.successRate,
                    color: .green
                )
            }
            
            // Success Tips
            VStack(alignment: .leading, spacing: 8) {
                Text("Improvement Areas")
                    .font(.headline)
                
                if stats.interviewRate < 20 {
                    InsightRow(
                        icon: "doc.text",
                        text: "Consider improving your resume - interview rate is below average (20%)",
                        color: .orange
                    )
                }
                
                if stats.successRate < 10 {
                    InsightRow(
                        icon: "person.crop.circle",
                        text: "Focus on interview skills - offer rate could be improved (target 10%+)",
                        color: .red
                    )
                }
                
                if stats.total < 10 {
                    InsightRow(
                        icon: "paperplane",
                        text: "Increase application volume for better opportunities",
                        color: .blue
                    )
                }
                
                if stats.interviewRate >= 20 && stats.successRate >= 10 && stats.total >= 10 {
                    InsightRow(
                        icon: "checkmark.circle",
                        text: "Great job! Your metrics are above average",
                        color: .green
                    )
                }
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .cornerRadius(8)
        }
    }
}

struct PriorityAnalysisChart: View {
    @EnvironmentObject var jobManager: JobApplicationManager
    
    var priorityData: [ChartDataPoint] {
        TaskPriority.allCases.map { priority in
            let count = jobManager.getAllApplications().filter { $0.priority == priority }.count
            return ChartDataPoint(category: priority.rawValue, value: Double(count), color: priority.color)
        }.filter { $0.value > 0 }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(priorityData, id: \.category) { dataPoint in
                    VStack(spacing: 4) {
                        Rectangle()
                            .fill(dataPoint.color)
                            .frame(width: 50, height: CGFloat(dataPoint.value * 25))
                            .cornerRadius(6)
                        
                        Text("\(Int(dataPoint.value))")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Text(dataPoint.category)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 150)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Priority Distribution Analysis")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let mostCommon = priorityData.max(by: { $0.value < $1.value }) {
                    Text("Most applications are prioritized as: \(mostCommon.category)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                let highPriorityCount = priorityData.filter {
                    $0.category == "High" || $0.category == "Urgent"
                }.reduce(0) { $0 + Int($1.value) }
                
                if highPriorityCount > 0 {
                    Text("You have \(highPriorityCount) high-priority applications that need attention")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .cornerRadius(8)
        }
    }
}

// MARK: - Supporting Views

struct FunnelBarView: View {
    let title: String
    let count: Int
    let percentage: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(count)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text("(\(String(format: "%.1f", percentage))%)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 24)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * (percentage / 100), height: 24)
                        .cornerRadius(4)
                        .animation(.easeInOut, value: percentage)
                }
            }
            .frame(height: 24)
        }
    }
}

struct InsightRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

struct EmptyChartView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGroupedBackground))
        .cornerRadius(8)
    }
}

// MARK: - Insights Section

struct InsightsSection: View {
    @EnvironmentObject var jobManager: JobApplicationManager
    
    var body: some View {
        let insights = generateInsights()
        
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights & Recommendations")
                .font(.headline)
            
            VStack(spacing: 12) {
                ForEach(insights.indices, id: \.self) { index in
                    HStack(spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        
                        Text(insights[index])
                            .font(.subheadline)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func generateInsights() -> [String] {
        let stats = jobManager.getApplicationStats()
        var insights: [String] = []
        
        if stats.total < 5 {
            insights.append("You're just getting started! Aim for 5-10 applications per week for better results.")
        }
        
        if stats.interviewRate < 15 {
            insights.append("Your interview rate is below average. Consider tailoring your resume and cover letter for each application.")
        }
        
        if stats.successRate < 5 && stats.interviews > 0 {
            insights.append("Focus on interview preparation. Practice common questions and research the companies thoroughly.")
        }
        
        let followUps = jobManager.getFollowUpsDue().count
        if followUps > 0 {
            insights.append("You have \(followUps) follow-ups due soon. Don't forget to reach out!")
        }
        
        let highPriorityApps = jobManager.getHighPriorityApplications().count
        if highPriorityApps > stats.total / 2 {
            insights.append("Most of your applications are high priority. Consider spreading your efforts across different priority levels.")
        }
        
        if insights.isEmpty {
            insights.append("Keep up the great work! Your application strategy looks solid.")
        }
        
        return insights
    }
}

// MARK: - Detailed Statistics

struct DetailedStatisticsSection: View {
    @EnvironmentObject var jobManager: JobApplicationManager
    let timeRange: AnalyticsView.TimeRange
    
    var body: some View {
        let stats = jobManager.getApplicationStats()
        
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Statistics")
                .font(.headline)
            
            VStack(spacing: 12) {
                StatRow(title: "Total Applications", value: "\(stats.total)")
                StatRow(title: "Pending Applications", value: "\(stats.pending)")
                StatRow(title: "Interview Conversion", value: String(format: "%.1f%%", stats.interviewRate))
                StatRow(title: "Offer Conversion", value: String(format: "%.1f%%", stats.successRate))
                StatRow(title: "Applications This Week", value: "\(jobManager.getApplicationsThisWeek().count)")
                StatRow(title: "Follow-ups Due", value: "\(jobManager.getFollowUpsDue().count)")
                StatRow(title: "High Priority Apps", value: "\(jobManager.getHighPriorityApplications().count)")
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
    }
}

// MARK: - Data Models

struct ChartDataPoint {
    let category: String
    let value: Double
    let color: Color
}

struct TimelinePoint {
    let date: Date
    let applications: Int
}

// MARK: - Previews

#Preview("Analytics View") {
    let manager = JobApplicationManager()
    manager.setupSampleData()
    
    return AnalyticsView()
        .environmentObject(manager)
}

#Preview("Key Metrics Dashboard") {
    let manager = JobApplicationManager()
    manager.setupSampleData()
    
    return KeyMetricsDashboard()
        .environmentObject(manager)
        .padding()
}

#Preview("Status Distribution Chart") {
    let manager = JobApplicationManager()
    manager.setupSampleData()
    
    return StatusDistributionChart()
        .environmentObject(manager)
        .padding()
}
