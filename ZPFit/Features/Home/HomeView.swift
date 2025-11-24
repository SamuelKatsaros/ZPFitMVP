import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @Environment(\.diContainer) private var diContainer
    @State private var searchText = ""
    
    init() {
        _viewModel = StateObject(wrappedValue: HomeViewModel(modelContainer: DIContainer.shared.persistenceService.container))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Good Morning 🔥")
                                    .font(.ZP.subheadline)
                                    .foregroundStyle(Color.ZP.textSecondary)
                                Text("Sam Katsaros")
                                    .font(.ZP.largeTitle)
                                    .foregroundStyle(Color.black)
                            }
                            Spacer()
                            // Profile Image Placeholder
                            Circle()
                                .fill(Color.ZP.lightCard)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundStyle(Color.ZP.textSecondary)
                                )
                        }
                        .padding(.top, 10)
                        
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Color.ZP.textSecondary)
                            TextField("Search", text: $searchText)
                                .foregroundStyle(Color.black)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        .environment(\.colorScheme, .light) // Ensure light mode appearance
                        
                        // Workout Plans
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Workout Plans")
                                .font(.ZP.title2)
                                .foregroundStyle(Color.black)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    NavigationLink(destination: WorkoutDetailView()) {
                                        WorkoutPlanCard(
                                            title: "Lower Body Training",
                                            calories: "500 cal",
                                            duration: "50 Min",
                                            imageUrl: URL(string: "https://lirp.cdn-website.com/cee6e347/dms3rep/multi/opt/new-zach-img-03-640w.jpg")
                                        )
                                    }
                                    
                                    NavigationLink(destination: WorkoutDetailView()) {
                                        WorkoutPlanCard(
                                            title: "Upper Body Strength",
                                            calories: "450 cal",
                                            duration: "45 Min",
                                            imageUrl: URL(string: "https://lirp.cdn-website.com/cee6e347/dms3rep/multi/opt/new-zach-img-03-640w.jpg")
                                        )
                                    }
                                }
                                .padding(.horizontal, 1) // Small padding to prevent clipping
                            }
                        }
                        
                        // Today's Plan
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Today's Plan")
                                .font(.ZP.title2)
                                .foregroundStyle(Color.black)
                            
                            VStack(spacing: 16) {
                                PlanRow(
                                    title: "Push Up",
                                    subtitle: "100 Push-ups",
                                    progress: 0.45,
                                    level: "Intermediate",
                                    imageName: "figure.strengthtraining.traditional"
                                )
                                PlanRow(
                                    title: "Upright Rows",
                                    subtitle: "20 Kettle Bell Upright Rows",
                                    progress: 0.75,
                                    level: "Beginner",
                                    imageName: "figure.core.training"
                                )
                                PlanRow(
                                    title: "Milo Run",
                                    subtitle: "30 min run",
                                    progress: 0.0,
                                    level: "Beginner",
                                    imageName: "figure.run"
                                )
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 100) // Space for Tab Bar
                }
            }
            .navigationTitle("Home")
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                viewModel.fetchData()
            }
        }
    }
}

// MARK: - Components

struct WorkoutPlanCard: View {
    let title: String
    let calories: String
    let duration: String
    let imageUrl: URL?
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background Image
            if let imageUrl = imageUrl {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.black)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Rectangle()
                            .fill(Color.black)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundStyle(Color.white.opacity(0.3))
                            )
                    @unknown default:
                        Rectangle()
                            .fill(Color.black)
                    }
                }
                .frame(width: 280, height: 180)
                .cornerRadius(24)
                .clipped()
            } else {
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 280, height: 180)
                    .cornerRadius(24)
            }
            
            // Content
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(title)
                        .font(.ZP.title2)
                        .foregroundStyle(Color.white)
                        .frame(width: 150, alignment: .leading)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 8) {
                        Label(calories, systemImage: "flame.fill")
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                        
                        Label(duration, systemImage: "clock.fill")
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .font(.ZP.caption)
                    .foregroundStyle(Color.white)
                }
                
                Spacer()
                
                // Play Button
                Circle()
                    .fill(Color.ZP.accent)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "play.fill")
                            .foregroundStyle(Color.ZP.textBlack)
                    )
            }
            .padding(20)
        }
        .frame(width: 280, height: 180)
    }
}

struct PlanRow: View {
    let title: String
    let subtitle: String
    let progress: Double
    let level: String
    let imageName: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Image
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.ZP.lightCard)
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: imageName)
                        .font(.largeTitle)
                        .foregroundStyle(Color.ZP.textSecondary)
                )
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.ZP.headline)
                        .foregroundStyle(Color.black)
                    Spacer()
                    Text(level)
                        .font(.ZP.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black)
                        .cornerRadius(8)
                        .foregroundStyle(Color.white)
                }
                
                Text(subtitle)
                    .font(.ZP.subheadline)
                    .foregroundStyle(Color.ZP.textSecondary)
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.ZP.lightCard)
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(Color.ZP.accent)
                            .frame(width: geometry.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
}
