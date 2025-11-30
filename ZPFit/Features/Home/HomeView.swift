import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @Environment(\.diContainer) private var diContainer
    @State private var searchText = ""
    @AppStorage("selectedPlan") private var selectedPlan: String?
    @State private var showPlanSelection = false
    @Binding var selectedTab: MainTabView.Tab
    
    init(selectedTab: Binding<MainTabView.Tab>) {
        _selectedTab = selectedTab
        _viewModel = StateObject(wrappedValue: HomeViewModel(modelContainer: DIContainer.shared.persistenceService.container))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.ZP.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Premium Header
                        HomeHeader()
                        
                        // Hero Section (Program Status)
                        HeroSection(selectedPlan: selectedPlan, showPlanSelection: $showPlanSelection, selectedTab: $selectedTab)
                        
                        // Featured Workouts (Now before Stats)
                        FeaturedWorkoutsSection()
                        
                        // Stats Row
                        StatsRow()
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.fetchData()
                // Don't auto-show plan selection if we want to show the "No program" state in hero
                // if selectedPlan == nil {
                //    showPlanSelection = true
                // }
            }
            .sheet(isPresented: $showPlanSelection) {
                ProgramListView() // Using ProgramListView as the selection view
            }
        }
    }
}

// MARK: - Components

struct HomeHeader: View {
    @Environment(\.diContainer) private var diContainer
    
    var body: some View {
        HStack {
            // Avatar
            Circle()
                .fill(Color.white)
                .frame(width: 50, height: 50)
                .overlay(
                    Text("SK")
                        .font(.ZP.headline)
                        .foregroundStyle(Color.black)
                )
            
            // Name & Date
            VStack(alignment: .leading, spacing: 4) {
                Text("Sam")
                    .font(.ZP.title2)
                    .foregroundStyle(Color.ZP.textPrimary)
                Text(Date().formatted(date: .long, time: .omitted))
                    .font(.ZP.subheadline)
                    .foregroundStyle(Color.ZP.textSecondary)
            }
            
            Spacer()
            
            // XP Badge
            HStack(spacing: 8) {
                Text("0 XP")
                    .font(.ZP.headline)
                    .foregroundStyle(Color.white)
                Image(systemName: "medal.fill")
                    .foregroundStyle(Color.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.ZP.card)
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
    }
}

struct HeroSection: View {
    let selectedPlan: String?
    @Binding var showPlanSelection: Bool
    @Binding var selectedTab: MainTabView.Tab
    
    // Helper to get program details based on ID
    private var programDetails: (title: String, image: String, difficulty: String) {
        switch selectedPlan {
        case "jacklete": return ("Jacklete", "https://lirp.cdn-website.com/cee6e347/dms3rep/multi/opt/new-zach-img-02-640w.jpg", "Advanced")
        case "stndrd6": return ("STNDRD6: SHIFT", "https://lirp.cdn-website.com/cee6e347/dms3rep/multi/opt/new-zach-img-03-640w.jpg", "Intermediate")
        case "hybrid": return ("Hybrid Athlete", "https://lirp.cdn-website.com/cee6e347/dms3rep/multi/opt/IMG_2678-afe97dc5-640w.PNG", "Expert")
        default: return ("Program", "gym_background", "Beginner")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title above card
            Text(selectedPlan == nil ? "Select a Program" : programDetails.title)
                .font(.ZP.title2)
                .foregroundStyle(Color.ZP.textPrimary)
                .padding(.horizontal, 20)
            
            ZStack(alignment: .bottom) {
                // Background Image
                if let _ = selectedPlan {
                    AsyncImage(url: URL(string: programDetails.image)) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                        default:
                            Color.ZP.card // Fallback
                        }
                    }
                    .frame(height: 220)
                    .overlay(
                        LinearGradient(
                            colors: [.black.opacity(0.1), .black.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(24)
                    .clipped()
                } else {
                    // No Program State Background
                    Color.ZP.card
                        .frame(height: 220)
                        .cornerRadius(24)
                }
                
                // Content
                if selectedPlan == nil {
                    VStack(spacing: 12) {
                        Text("No program, no plan")
                            .font(.ZP.title1)
                            .foregroundStyle(Color.white)
                        
                        Text("Let's fix that — select your first program.")
                            .font(.ZP.body)
                            .foregroundStyle(Color.white.opacity(0.8))
                        
                        Button(action: { showPlanSelection = true }) {
                            Text("Select a Program")
                                .font(.ZP.headline)
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.bottom, 60) // Center vertically roughly
                } else {
                    // Selected Program State Content
                    ZStack(alignment: .bottom) {
                        // Top Right Timer
                        VStack {
                            HStack {
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(Color.black.opacity(0.6))
                                        .frame(width: 50, height: 50)
                                    
                                    VStack(spacing: 0) {
                                        Text("60")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(Color.blue)
                                        Text("min")
                                            .font(.system(size: 10))
                                            .foregroundStyle(Color.white)
                                    }
                                    
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 2)
                                        .frame(width: 50, height: 50)
                                    
                                    Circle()
                                        .trim(from: 0, to: 0.75)
                                        .stroke(Color.white, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                        .frame(width: 50, height: 50)
                                        .rotationEffect(.degrees(-90))
                                }
                            }
                            Spacer()
                        }
                        .padding(16)
                        
                        // Bottom Content
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 8) {
                                // Difficulty Badge
                                HStack(spacing: 4) {
                                    Image(systemName: "chart.bar.fill")
                                        .font(.caption2)
                                    Text(programDetails.difficulty)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                }
                                .foregroundStyle(Color.purple)
                                
                                // Workout Title
                                Text("Abs + Cardio")
                                    .font(.ZP.title2)
                                    .foregroundStyle(Color.white)
                            }
                            
                            Spacer()
                            
                            // Start Button
                            Button(action: { selectedTab = .programs }) {
                                Text("Start Day 1")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Color.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color(red: 0.0, green: 0.35, blue: 0.9))
                                    .cornerRadius(12)
                            }
                        }
                        .padding(16)
                    }
                    .frame(height: 220)
                }
            }
            .padding(.horizontal, 20)
            
            if selectedPlan != nil {
                // W1 Component
                WeekAtAGlance()
                    .padding(.horizontal, 20)
            }
        }
    }
}

struct WeekAtAGlance: View {
    var body: some View {
        HStack(spacing: 16) {
            Text("W1")
                .font(.ZP.headline)
                .foregroundStyle(Color.white)
            
            HStack(spacing: 10) {
                // Day 1 - Active (Blue dashed circle with check)
                ZStack {
                    Circle()
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "checkmark")
                        .font(.caption2)
                        .foregroundStyle(Color.blue)
                }
                
                // Other days
                ForEach(0..<4) { _ in
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.caption2)
                                .foregroundStyle(Color.white.opacity(0.2))
                        )
                }
                
                // Rest days
                ForEach(0..<2) { _ in
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "moon.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.white.opacity(0.2))
                        )
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.ZP.textSecondary)
            }
        }
        .padding(16)
        .background(Color.ZP.card)
        .cornerRadius(20)
    }
}

struct StatsRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink(destination: CalendarView()) {
                HStack {
                    Text("Stats")
                        .font(.ZP.title2)
                        .foregroundStyle(Color.ZP.textPrimary)
                    Spacer()
                    Text("See all")
                        .font(.ZP.subheadline)
                        .foregroundStyle(Color.ZP.textSecondary)
                    Image(systemName: "chevron.right")
                        .font(.ZP.caption)
                        .foregroundStyle(Color.ZP.textSecondary)
                }
                .padding(.horizontal, 20)
            }
            
            // Weight Card
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("-- lbs")
                        .font(.ZP.title2)
                        .foregroundStyle(Color.ZP.textPrimary)
                    Text("No information yet")
                        .font(.ZP.subheadline)
                        .foregroundStyle(Color.ZP.textSecondary)
                }
                Spacer()
                HStack {
                    Text("Weigh in")
                        .font(.ZP.subheadline)
                        .foregroundStyle(Color.ZP.textPrimary)
                    Image(systemName: "arrow.right")
                        .font(.ZP.caption)
                        .foregroundStyle(Color.ZP.textPrimary)
                }
            }
            .padding(20)
            .background(Color.ZP.card)
            .cornerRadius(20)
            .padding(.horizontal, 20)
            
            // Calories & Steps
            HStack(spacing: 16) {
                HomeStatBox(icon: "flame.fill", title: "Calories", value: "0 / 2135", color: .purple)
                HomeStatBox(icon: "shoe.fill", title: "Steps", value: "0 / 0", color: .orange)
            }
            .padding(.horizontal, 20)
        }
    }
}

struct HomeStatBox: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 4)
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: icon)
                        .foregroundStyle(color)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.ZP.subheadline)
                    .foregroundStyle(Color.ZP.textPrimary)
                Text(value)
                    .font(.ZP.headline)
                    .foregroundStyle(Color.ZP.textSecondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.ZP.card)
        .cornerRadius(20)
    }
}

struct FeaturedWorkoutsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink(destination: ProgramListView()) {
                HStack {
                    Text("Workouts")
                        .font(.ZP.title2)
                        .foregroundStyle(Color.ZP.textPrimary)
                    Spacer()
                    Text("Schedule")
                        .font(.ZP.subheadline)
                        .foregroundStyle(Color.ZP.textSecondary)
                    Image(systemName: "chevron.right")
                        .font(.ZP.caption)
                        .foregroundStyle(Color.ZP.textSecondary)
                }
                .padding(.horizontal, 20)
            }
            
            // Empty Schedule Card
            HStack(spacing: 16) {
                Image(systemName: "calendar")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.ZP.textSecondary)
                    .frame(width: 50, height: 50)
                    .background(Color.ZP.cardHover)
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nothing on the schedule")
                        .font(.ZP.headline)
                        .foregroundStyle(Color.ZP.textPrimary)
                    Text("No workout yet — let's get moving!")
                        .font(.ZP.subheadline)
                        .foregroundStyle(Color.ZP.textSecondary)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.ZP.card)
            .cornerRadius(20)
            .padding(.horizontal, 20)
        }
    }
}
