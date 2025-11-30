import SwiftUI
import SwiftData

struct ProgramListView: View {
    @State private var showWorkout = false
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("selectedPlan") private var selectedPlan: String?
    
    var body: some View {
        if selectedPlan != nil {
            TodaysWorkoutView()
        } else {
            NavigationStack {
                ZStack {
                    Color.ZP.background.ignoresSafeArea()
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Header
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Programs")
                                    .font(.ZP.largeTitle)
                                    .foregroundStyle(Color.ZP.textPrimary)
                                
                                Text("Choose your path. Build your discipline.")
                                    .font(.ZP.body)
                                    .foregroundStyle(Color.ZP.textSecondary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Program Cards
                            VStack(spacing: 24) {
                                NavigationLink(destination: ProgramDetailView(program: Program(id: "jacklete", title: "Jacklete", subtitle: "Build muscle, strength, and explosive power", difficulty: "Advanced", durationWeeks: 9, coverImage: "https://lirp.cdn-website.com/cee6e347/dms3rep/multi/opt/new-zach-img-02-640w.jpg"))) {
                                    PremiumProgramCard(
                                        title: "Jacklete",
                                        description: "Chris Bumstead's new approach to building muscle, strength, and explosive power.",
                                        difficulty: "Advanced",
                                        duration: "9 WEEKS",
                                        phases: ["Phase 1", "Phase 2", "Phase 3"],
                                        imageURL: "https://lirp.cdn-website.com/cee6e347/dms3rep/multi/opt/new-zach-img-02-640w.jpg",
                                        accentColor: .purple
                                    )
                                }
                                .buttonStyle(ZPScaleButtonStyle())
                                
                                NavigationLink(destination: ProgramDetailView(program: Program(id: "stndrd6", title: "STNDRD6: SHIFT", subtitle: "6-week transformation program", difficulty: "Intermediate", durationWeeks: 6, coverImage: "https://lirp.cdn-website.com/cee6e347/dms3rep/multi/opt/new-zach-img-03-640w.jpg"))) {
                                    PremiumProgramCard(
                                        title: "STNDRD6: SHIFT",
                                        description: "A 6-week transformation to build muscle, strength, and confidence through proven methods.",
                                        difficulty: "Intermediate",
                                        duration: "6 WEEKS",
                                        phases: [],
                                        imageURL: "https://lirp.cdn-website.com/cee6e347/dms3rep/multi/opt/new-zach-img-03-640w.jpg",
                                        accentColor: .white
                                    )
                                }
                                .buttonStyle(ZPScaleButtonStyle())
                                
                                NavigationLink(destination: ProgramDetailView(program: Program(id: "hybrid", title: "Hybrid Athlete", subtitle: "Endurance and strength combined", difficulty: "Expert", durationWeeks: 12, coverImage: "https://lirp.cdn-website.com/cee6e347/dms3rep/multi/opt/IMG_2678-afe97dc5-640w.PNG"))) {
                                    PremiumProgramCard(
                                        title: "Hybrid Athlete",
                                        description: "Combine endurance and strength for the ultimate functional physique.",
                                        difficulty: "Expert",
                                        duration: "12 WEEKS",
                                        phases: [],
                                        imageURL: "https://lirp.cdn-website.com/cee6e347/dms3rep/multi/opt/IMG_2678-afe97dc5-640w.PNG",
                                        accentColor: .blue
                                    )
                                }
                                .buttonStyle(ZPScaleButtonStyle())
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 100)
                    }
                }
                .navigationBarHidden(true)
            }
        }
    }
}

struct PremiumProgramCard: View {
    let title: String
    let description: String
    let difficulty: String
    let duration: String
    let phases: [String]
    let imageURL: String
    let accentColor: Color
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background Image
            AsyncImage(url: URL(string: imageURL)) { phase in
                switch phase {
                case .empty:
                    Color.ZP.card.overlay(ProgressView())
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Color.ZP.card // Fallback
                @unknown default:
                    Color.ZP.card
                }
            }
            .frame(height: 320)
            .overlay(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.6), .black.opacity(0.9)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(32)
            .clipped()
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                // Top Badges (Absolute positioning relative to ZStack would be better, but VStack with Spacer works too if we change alignment)
                
                Spacer()
                
                // Title
                Text(title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Color.white)
                
                // Description
                Text(description)
                    .font(.ZP.body)
                    .foregroundStyle(Color.white.opacity(0.8))
                    .lineLimit(3)
                    .padding(.bottom, 4)
                
                // Phases
                if !phases.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(phases, id: \.self) { phase in
                            Text(phase)
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(8)
                                .foregroundStyle(Color.white)
                        }
                    }
                }
            }
            .padding(24)
            
            // Top Badges
            VStack {
                HStack {
                    // Difficulty Badge
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar.fill")
                            .font(.caption)
                        Text(difficulty)
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(accentColor.opacity(0.2))
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .foregroundStyle(accentColor)
                    
                    Spacer()
                    
                    // Duration Badge
                    Text(duration)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                        .foregroundStyle(Color.white)
                }
                Spacer()
            }
            .padding(20)
        }
        .frame(height: 320)
        .cornerRadius(32)
    }
}
