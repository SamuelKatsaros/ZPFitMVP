import SwiftUI
import SwiftData

struct CalendarView: View {
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        Text(currentMonthYear)
                            .font(.ZP.title3)
                            .foregroundStyle(Color.black)
                        
                        // Calendar Strip
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(weekDates, id: \.self) { date in
                                    CalendarDay(
                                        day: dayLetter(for: date),
                                        date: dayNumber(for: date),
                                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate)
                                    )
                                    .onTapGesture {
                                        selectedDate = date
                                    }
                                }
                            }
                        }
                        
                        Text("Today Report")
                            .font(.ZP.title2)
                            .foregroundStyle(Color.black)
                        
                        // Bento Grid
                        HStack(alignment: .top, spacing: 16) {
                            // Left Column
                            VStack(spacing: 16) {
                                // Active Calories
                                BentoCard(color: Color(hex: "F2F2F7")) {
                                    VStack(alignment: .leading) {
                                        Text("Active calories")
                                            .font(.ZP.caption)
                                            .foregroundStyle(.gray)
                                        Text("645 Cal")
                                            .font(.ZP.headline)
                                            .foregroundStyle(.black)
                                        
                                        Spacer()
                                        
                                        ZStack {
                                            Circle()
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                                            Circle()
                                                .trim(from: 0, to: 0.8)
                                                .stroke(Color.purple, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                                .rotationEffect(.degrees(-90))
                                            Text("80%")
                                                .font(.ZP.caption)
                                                .foregroundStyle(.black)
                                        }
                                        .frame(height: 80)
                                    }
                                }
                                .frame(height: 160)
                                
                                // Heart Rate
                                BentoCard(color: Color(hex: "FFE5E5")) {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Image(systemName: "heart.fill")
                                                .foregroundStyle(.red)
                                            Text("Heart Rate")
                                                .font(.ZP.subheadline)
                                                .foregroundStyle(.black)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "waveform.path.ecg")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .foregroundStyle(.red)
                                            .frame(height: 40)
                                        
                                        Text("79 Bpm")
                                            .font(.ZP.caption)
                                            .foregroundStyle(.gray)
                                            .frame(maxWidth: .infinity, alignment: .trailing)
                                    }
                                }
                                .frame(height: 140)
                                
                                // Sleep
                                BentoCard(color: Color(hex: "E5E5FF")) {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Image(systemName: "moon.fill")
                                                .foregroundStyle(.purple)
                                            Text("Sleep")
                                                .font(.ZP.subheadline)
                                                .foregroundStyle(.black)
                                        }
                                        
                                        Spacer()
                                        
                                        HStack(alignment: .bottom, spacing: 4) {
                                            ForEach(0..<7) { _ in
                                                Capsule()
                                                    .fill(Color.purple)
                                                    .frame(width: 6, height: CGFloat.random(in: 10...30))
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                                .frame(height: 100)
                            }
                            
                            // Right Column
                            VStack(spacing: 16) {
                                // Cycling
                                BentoCard(color: Color.ZP.card) {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Image(systemName: "bicycle")
                                                .foregroundStyle(.white)
                                            Text("Cycling")
                                                .font(.ZP.headline)
                                                .foregroundStyle(.white)
                                        }
                                        
                                        Spacer()
                                        
                                        // Map Placeholder
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .cornerRadius(8)
                                            .overlay(
                                                PolylineShape()
                                                    .stroke(Color.ZP.accent, lineWidth: 2)
                                            )
                                    }
                                }
                                .frame(height: 180)
                                
                                // Steps
                                BentoCard(color: Color(hex: "FFEACC")) {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Image(systemName: "figure.walk")
                                                .foregroundStyle(.orange)
                                            Text("Steps")
                                                .font(.ZP.subheadline)
                                                .foregroundStyle(.black)
                                        }
                                        
                                        Spacer()
                                        
                                        Text("999/2000")
                                            .font(.ZP.caption)
                                            .foregroundStyle(.gray)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                        
                                        Capsule()
                                            .fill(Color.orange.opacity(0.3))
                                            .frame(height: 6)
                                            .overlay(
                                                GeometryReader { g in
                                                    Capsule()
                                                        .fill(Color.orange)
                                                        .frame(width: g.size.width * 0.5)
                                                }
                                            )
                                    }
                                }
                                .frame(height: 100)
                                
                                // Water
                                BentoCard(color: Color(hex: "D1EEFF")) {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Image(systemName: "drop.fill")
                                                .foregroundStyle(.blue)
                                            Text("Water")
                                                .font(.ZP.subheadline)
                                                .foregroundStyle(.black)
                                        }
                                        
                                        Spacer()
                                        
                                        ZStack(alignment: .bottom) {
                                            Text("6/8 Cups")
                                                .font(.ZP.caption)
                                                .foregroundStyle(.black)
                                                .padding(.bottom, 4)
                                                .zIndex(1)
                                            
                                            WaveShape(progress: 0.6)
                                                .fill(Color.blue.opacity(0.5))
                                                .frame(height: 30)
                                        }
                                    }
                                }
                                .frame(height: 100)
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Stats")
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    
    // MARK: - Helper functions
    private var currentMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private var weekDates: [Date] {
        let calendar = Calendar.current
        let today = Date() // Always use actual today, not selectedDate
        
        // Generate dates: 2 days before today, today (at index 2), and 4 days after
        return (-2...4).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: today)
        }
    }
    
    private func dayLetter(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE" // Single letter
        return formatter.string(from: date)
    }
    
    private func dayNumber(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

struct CalendarDay: View {
    let day: String
    let date: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(day)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? Color.white : Color.black)
            Text(date)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(isSelected ? Color.white : Color.black)
        }
        .frame(width: 60, height: 60)
        .background(isSelected ? Color.black : Color.ZP.accent)
        .cornerRadius(16)
    }
}

struct BentoCard<Content: View>: View {
    let color: Color
    let content: Content
    
    init(color: Color, @ViewBuilder content: () -> Content) {
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(color)
            .cornerRadius(20)
    }
}

struct PolylineShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 10, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - 10))
        path.addLine(to: CGPoint(x: rect.maxX - 10, y: rect.maxY - 10))
        return path
    }
}

struct WaveShape: Shape {
    var progress: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY * (1 - progress)))
        path.addCurve(to: CGPoint(x: rect.minX, y: rect.maxY * (1 - progress)),
                      control1: CGPoint(x: rect.maxX * 0.75, y: rect.maxY * (1 - progress) - 10),
                      control2: CGPoint(x: rect.maxX * 0.25, y: rect.maxY * (1 - progress) + 10))
        path.closeSubpath()
        return path
    }
}
