import SwiftUI
import Charts

struct ProgressView: View {
    // Mock Data
    let weeklyVolume: [WorkoutData] = [
        .init(day: "Mon", minutes: 30),
        .init(day: "Tue", minutes: 45),
        .init(day: "Wed", minutes: 0),
        .init(day: "Thu", minutes: 60),
        .init(day: "Fri", minutes: 30),
        .init(day: "Sat", minutes: 90),
        .init(day: "Sun", minutes: 0)
    ]
    
    struct WorkoutData: Identifiable {
        let id = UUID()
        let day: String
        let minutes: Int
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.ZP.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your Progress")
                                .font(.ZP.largeTitle)
                                .foregroundStyle(Color.ZP.textPrimary)
                            Text("Keep pushing your limits.")
                                .font(.ZP.body)
                                .foregroundStyle(Color.ZP.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top)
                        
                        // Chart
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Weekly Activity (Minutes)")
                                .font(.ZP.headline)
                                .foregroundStyle(Color.ZP.textPrimary)
                            
                            Chart {
                                ForEach(weeklyVolume) { data in
                                    BarMark(
                                        x: .value("Day", data.day),
                                        y: .value("Minutes", data.minutes)
                                    )
                                    .foregroundStyle(Color.ZP.primary)
                                    .cornerRadius(4)
                                }
                            }
                            .frame(height: 200)
                            .chartYAxis {
                                AxisMarks(position: .leading, values: .automatic) { value in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [5, 5]))
                                        .foregroundStyle(Color.ZP.textSecondary.opacity(0.3))
                                    AxisValueLabel()
                                        .foregroundStyle(Color.ZP.textSecondary)
                                }
                            }
                            .chartXAxis {
                                AxisMarks(values: .automatic) { value in
                                    AxisValueLabel()
                                        .foregroundStyle(Color.ZP.textSecondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color.ZP.card)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        
                        // Stats Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            StatBox(title: "Total Workouts", value: "12")
                            StatBox(title: "Time Trained", value: "8h 30m")
                            StatBox(title: "Calories", value: "4,200")
                            StatBox(title: "Avg Heart Rate", value: "135 bpm")
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Progress")
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.ZP.caption)
                .foregroundStyle(Color.ZP.textSecondary)
            Text(value)
                .font(.ZP.title2)
                .foregroundStyle(Color.ZP.textPrimary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ZP.card)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}
