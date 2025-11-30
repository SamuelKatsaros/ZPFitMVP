import SwiftUI
import SwiftData

struct CalendarView: View {
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.ZP.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Header & Calendar Strip
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text(currentMonthYear)
                                    .font(.ZP.title2)
                                    .foregroundStyle(Color.ZP.textPrimary)
                                Spacer()
                                Image(systemName: "calendar")
                                    .foregroundStyle(Color.ZP.primary)
                            }
                            .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(weekDates, id: \.self) { date in
                                        CalendarDay(
                                            day: dayLetter(for: date),
                                            date: dayNumber(for: date),
                                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate)
                                        )
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedDate = date
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Today's Report Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Today Report")
                                .font(.ZP.largeTitle)
                                .foregroundStyle(Color.ZP.textPrimary)
                            Text("Your daily activity summary")
                                .font(.ZP.body)
                                .foregroundStyle(Color.ZP.textSecondary)
                        }
                        .padding(.horizontal, 20)
                        
                        // Metrics Grid
                        VStack(spacing: 16) {
                            // Row 1: Active Calories (Large)
                            BentoCard(color: Color.ZP.card) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Image(systemName: "flame.fill")
                                                .foregroundStyle(.orange)
                                            Text("Active Calories")
                                                .font(.ZP.subheadline)
                                                .foregroundStyle(Color.ZP.textSecondary)
                                        }
                                        
                                        Text("645")
                                            .font(.system(size: 48, weight: .bold, design: .rounded))
                                            .foregroundStyle(Color.ZP.textPrimary)
                                        + Text(" kcal")
                                            .font(.ZP.headline)
                                            .foregroundStyle(Color.ZP.textSecondary)
                                            
                                        Text("Goal: 800 kcal")
                                            .font(.ZP.caption)
                                            .foregroundStyle(Color.ZP.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    ZStack {
                                        Circle()
                                            .stroke(Color.white.opacity(0.1), lineWidth: 12)
                                        Circle()
                                            .trim(from: 0, to: 0.8)
                                            .stroke(
                                                LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom),
                                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                            )
                                            .rotationEffect(.degrees(-90))
                                        
                                        VStack(spacing: 0) {
                                            Text("80%")
                                                .font(.ZP.headline)
                                                .foregroundStyle(Color.white)
                                        }
                                    }
                                    .frame(width: 100, height: 100)
                                }
                            }
                            .frame(height: 160)
                            
                            // Row 2: Heart Rate & Steps
                            HStack(spacing: 16) {
                                BentoCard(color: Color.ZP.card) {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Image(systemName: "heart.fill")
                                                .foregroundStyle(.red)
                                            Spacer()
                                            Text("79 bpm")
                                                .font(.ZP.headline)
                                                .foregroundStyle(Color.white)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "waveform.path.ecg")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .foregroundStyle(LinearGradient(colors: [.red.opacity(0.5), .red], startPoint: .leading, endPoint: .trailing))
                                            .frame(height: 40)
                                    }
                                }
                                .frame(height: 140)
                                
                                BentoCard(color: Color.ZP.card) {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Image(systemName: "figure.walk")
                                                .foregroundStyle(.green)
                                            Spacer()
                                            Text("Steps")
                                                .font(.ZP.subheadline)
                                                .foregroundStyle(Color.ZP.textSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Text("4,230")
                                            .font(.ZP.title2)
                                            .foregroundStyle(Color.white)
                                        
                                        GeometryReader { geometry in
                                            ZStack(alignment: .leading) {
                                                Capsule()
                                                    .fill(Color.white.opacity(0.2))
                                                    .frame(height: 6)
                                                Capsule()
                                                    .fill(Color.green)
                                                    .frame(width: geometry.size.width * 0.4, height: 6)
                                            }
                                        }
                                        .frame(height: 6)
                                    }
                                }
                                .frame(height: 140)
                            }
                            
                            // Row 3: Sleep & Water
                            HStack(spacing: 16) {
                                BentoCard(color: Color.ZP.card) {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Image(systemName: "moon.fill")
                                                .foregroundStyle(.purple)
                                            Text("Sleep")
                                                .font(.ZP.subheadline)
                                                .foregroundStyle(Color.ZP.textSecondary)
                                        }
                                        Spacer()
                                        Text("7h 30m")
                                            .font(.ZP.title2)
                                            .foregroundStyle(Color.white)
                                    }
                                }
                                .frame(height: 100)
                                
                                BentoCard(color: Color.ZP.card) {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Image(systemName: "drop.fill")
                                                .foregroundStyle(.blue)
                                            Text("Water")
                                                .font(.ZP.subheadline)
                                                .foregroundStyle(Color.ZP.textSecondary)
                                        }
                                        Spacer()
                                        Text("1.5 L")
                                            .font(.ZP.title2)
                                            .foregroundStyle(Color.white)
                                    }
                                }
                                .frame(height: 100)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
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
        let today = Date()
        return (-2...4).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: today)
        }
    }
    
    private func dayLetter(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE"
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
        VStack(spacing: 8) {
            Text(day)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isSelected ? Color.black : Color.ZP.textSecondary)
            Text(date)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(isSelected ? Color.black : Color.ZP.textPrimary)
        }
        .frame(width: 56, height: 76)
        .background(isSelected ? Color.ZP.primary : Color.ZP.card)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? Color.ZP.primary : Color.white.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: isSelected ? Color.ZP.primary.opacity(0.3) : Color.clear, radius: 10, x: 0, y: 5)
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
            .padding(20)
            .background(color)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 5)
    }
}
