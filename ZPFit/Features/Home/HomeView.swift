import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @Environment(\.diContainer) private var diContainer
    @State private var searchText = ""
    @State private var showPlanSelection = false
    @State private var selectedSession: FirestoreSession?
    @State private var showAllSessions = false
    @Binding var selectedTab: MainTabView.Tab
    
    init(selectedTab: Binding<MainTabView.Tab>) {
        _selectedTab = selectedTab
        _viewModel = StateObject(wrappedValue: HomeViewModel(
            modelContainer: DIContainer.shared.persistenceService.container,
            firestoreService: DIContainer.shared.firestoreService,
            authService: DIContainer.shared.authenticationService
        ))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.ZP.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Premium Header
                        HomeHeader()
                        
                        // Hero Section (Program Status) - now uses viewModel
                        HeroSection(viewModel: viewModel, showPlanSelection: $showPlanSelection, selectedTab: $selectedTab)
                        
                        // Featured Workouts (Now before Stats)
                        FeaturedWorkoutsSection(
                            viewModel: viewModel,
                            selectedSession: $selectedSession,
                            showAllSessions: $showAllSessions
                        )
                        

                    }
                    .padding(.top, 10)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showPlanSelection) {
                ProgramListView()
            }
            .fullScreenCover(item: $selectedSession) { session in
                SessionPlayerView(
                    sessions: [session], // Only pass the selected session
                    initialSessionId: session.id ?? "",
                    isPresented: Binding(
                        get: { selectedSession != nil },
                        set: { if !$0 { selectedSession = nil } }
                    )
                )
            }
            .fullScreenCover(isPresented: $showAllSessions) {
                if let firstSession = viewModel.sessions.first {
                    SessionPlayerView(
                        sessions: viewModel.sessions, // Pass all sessions
                        initialSessionId: firstSession.id ?? "",
                        isPresented: $showAllSessions
                    )
                }
            }
        }
    }
}

// MARK: - Components


struct HomeHeader: View {
    @Environment(\.diContainer) private var diContainer
    @ObservedObject var firestoreService: FirestoreService = DIContainer.shared.firestoreService
    
    var body: some View {
        HStack {
            // Avatar with dynamic initials
            Circle()
                .fill(Color.white)
                .frame(width: 50, height: 50)
                .overlay(
                    Text(firestoreService.currentUserProfile?.initials ?? "??")
                        .font(.ZP.headline)
                        .foregroundStyle(Color.black)
                )
            
            // Name & Date
            VStack(alignment: .leading, spacing: 4) {
                Text(firestoreService.currentUserProfile?.firstName ?? "User")
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
    @ObservedObject var viewModel: HomeViewModel
    @Binding var showPlanSelection: Bool
    @Binding var selectedTab: MainTabView.Tab
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title above card
            Text(viewModel.selectedProgram == nil ? "Select a Program" : viewModel.selectedProgram?.title ?? "Program")
                .font(.ZP.title2)
                .foregroundStyle(Color.ZP.textPrimary)
                .padding(.horizontal, 20)
            
            ZStack(alignment: .bottom) {
                // Background Image
                if let program = viewModel.selectedProgram {
                    AsyncImage(url: URL(string: program.coverImage)) { phase in
                        let _ = print("🏠 Home Hero Image: '\(program.coverImage)'")
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                        case .failure(let error):
                            let _ = print("❌ Home Image load failed: \(error)")
                            VStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                Text(program.coverImage)
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.ZP.card)
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
                if viewModel.selectedProgram == nil {
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
                                        Text("\(viewModel.currentDay?.durationMinutes ?? 60)")
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
                                // Difficulty Badge or Completion Status
                                if viewModel.completedToday {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption2)
                                        Text("Completed!")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                    }
                                    .foregroundStyle(Color.green)
                                } else {
                                    HStack(spacing: 4) {
                                        Image(systemName: "chart.bar.fill")
                                            .font(.caption2)
                                        Text(viewModel.selectedProgram?.difficulty ?? "Beginner")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                    }
                                    .foregroundStyle(difficultyColor(for: viewModel.selectedProgram?.difficulty))
                                }
                                
                                // Workout Title
                                Text(viewModel.currentDay?.title ?? "Rest Day")
                                    .font(.ZP.title2)
                                    .foregroundStyle(Color.white)
                                
                                // Show next day message if completed
                                if viewModel.completedToday {
                                    Text("Next: Day \(viewModel.nextAvailableDay) tomorrow")
                                        .font(.caption)
                                        .foregroundStyle(Color.white.opacity(0.7))
                                }
                            }
                            
                            Spacer()
                            
                            // Start Button
                            Button(action: { selectedTab = .programs }) {
                                if viewModel.completedToday {
                                    Text("View Workout")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Color.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(12)
                                } else {
                                    Text("Start Day \(viewModel.nextAvailableDay)")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Color.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color(red: 0.0, green: 0.35, blue: 0.9))
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding(16)
                    }
                    .frame(height: 220)
                }
            }
            .padding(.horizontal, 20)
            
            if viewModel.selectedProgram != nil {
                // W1 Component
                WeekAtAGlance(viewModel: viewModel)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    // Helper function to get color based on difficulty
    private func difficultyColor(for difficulty: String?) -> Color {
        guard let difficulty = difficulty?.lowercased() else {
            return Color.green // Default for Beginner
        }
        
        switch difficulty {
        case "beginner":
            return Color.green
        case "intermediate":
            return Color.blue
        case "advanced":
            return Color.purple
        default:
            return Color.green
        }
    }
}

struct WeekAtAGlance: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            Text("W1")
                .font(.ZP.headline)
                .foregroundStyle(Color.white)
            
            HStack(spacing: 10) {
                // All 7 days
                ForEach(1...7, id: \.self) { dayNumber in
                    dayIndicator(for: dayNumber)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color.ZP.card)
        .cornerRadius(20)
    }
    
    @ViewBuilder
    private func dayIndicator(for dayNumber: Int) -> some View {
        let nextDay = viewModel.nextAvailableDay
        
        if dayNumber < nextDay {
            // Completed days - solid blue filled circle with white checkmark
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 28, height: 28)
                
                Image(systemName: "checkmark")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.white)
            }
        } else if dayNumber == nextDay {
            // Current day (pending) - blue dashed circle with dimmed checkmark
            ZStack {
                Circle()
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                    .frame(width: 28, height: 28)
                
                Image(systemName: "checkmark")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.blue.opacity(0.5))
            }
        } else {
            // Future days - gray circle with dimmed checkmark
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.white.opacity(0.2))
                )
        }
    }
}



struct FeaturedWorkoutsSection: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var selectedSession: FirestoreSession?
    @Binding var showAllSessions: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Sessions")
                    .font(.ZP.title2)
                    .foregroundStyle(Color.ZP.textPrimary)
                Spacer()
                Button(action: { showAllSessions = true }) {
                    HStack(spacing: 4) {
                        Text("See all")
                            .font(.ZP.subheadline)
                        Image(systemName: "chevron.right")
                            .font(.ZP.caption)
                    }
                    .foregroundStyle(Color.ZP.textSecondary)
                }
            }
            .padding(.horizontal, 20)
            
            // Horizontal Scroll
            if viewModel.sessions.isEmpty {
                // Empty state
                HStack(spacing: 16) {
                    Image(systemName: "video")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.ZP.textSecondary)
                        .frame(width: 50, height: 50)
                        .background(Color.ZP.cardHover)
                        .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No sessions yet")
                            .font(.ZP.headline)
                            .foregroundStyle(Color.ZP.textPrimary)
                        Text("Check back soon for quick workout sessions!")
                            .font(.ZP.subheadline)
                            .foregroundStyle(Color.ZP.textSecondary)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.ZP.card)
                .cornerRadius(20)
                .padding(.horizontal, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.sessions) { session in
                            SessionCard(session: session)
                                .onTapGesture {
                                    selectedSession = session
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

// MARK: - Session Card Component

struct SessionCard: View {
    let session: FirestoreSession
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background Image
            AsyncImage(url: URL(string: session.thumbnailUrl)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure(_):
                    Color.ZP.cardHover
                        .overlay(
                            Image(systemName: "video.slash")
                                .foregroundStyle(Color.ZP.textSecondary)
                        )
                case .empty:
                    Color.ZP.cardHover
                @unknown default:
                    Color.ZP.cardHover
                }
            }
            .frame(width: 140, height: 220)
            .clipped()
            
            // Gradient Overlay
            LinearGradient(
                colors: [.black.opacity(0), .black.opacity(0.8)],
                startPoint: .center,
                endPoint: .bottom
            )
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    // Play Button / Type Indicator
                    Image(systemName: "play.fill")
                        .font(.caption2)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                    
                    Spacer()
                }
                
                Spacer()
                
                Text(session.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("\(session.duration) min")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white.opacity(0.9))
            }
            .padding(12)
        }
        .frame(width: 140, height: 220)
        .background(Color.ZP.card)
        .cornerRadius(20)
        // Add a subtle shadow to the card itself
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}
