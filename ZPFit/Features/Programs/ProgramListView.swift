import SwiftUI
import SwiftData

struct ProgramListView: View {
    @StateObject private var viewModel: ProgramListViewModel
    @Environment(\.dismiss) private var dismiss
    
    init() {
        _viewModel = StateObject(wrappedValue: ProgramListViewModel(
            firestoreService: DIContainer.shared.firestoreService,
            authService: DIContainer.shared.authenticationService
        ))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.ZP.background.ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .tint(Color.white)
                } else if viewModel.programs.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.ZP.textSecondary)
                        
                        Text("No Programs Available")
                            .font(.ZP.title2)
                            .foregroundStyle(Color.ZP.textPrimary)
                        
                        Text("Programs will appear here once added to Firestore")
                            .font(.ZP.body)
                            .foregroundStyle(Color.ZP.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
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
                            
                            // Load from Firestore
                            VStack(spacing: 24) {
                                ForEach(viewModel.programs) { program in
                                    Button(action: {
                                        Task {
                                            await viewModel.selectProgram(program)
                                            // Wait for Firestore to update (increased delay)
                                            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                                            // Dismiss the sheet
                                            dismiss()
                                            // Post notification to refresh HomeView
                                            NotificationCenter.default.post(name: NSNotification.Name("ProgramSelected"), object: nil)
                                        }
                                    }) {
                                        PremiumProgramCard(
                                            title: program.title,
                                            description: program.subtitle,
                                            difficulty: program.difficulty ?? "Intermediate",
                                            duration: "\(program.durationWeeks) WEEKS",
                                            phases: [],
                                            imageURL: program.coverImage,
                                            accentColor: .purple
                                        )
                                    }
                                    .buttonStyle(ZPScaleButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.loadPrograms()
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
                let _ = print("🖼️ Loading image: '\(imageURL)'")
                switch phase {
                case .empty:
                    Color.ZP.card.overlay(ProgressView())
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure(let error):
                    let _ = print("❌ Image load failed: \(error)")
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text("Failed to load image")
                            .font(.caption)
                            .foregroundStyle(.white)
                        Text(imageURL)
                            .font(.caption2)
                            .foregroundStyle(.gray)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.ZP.card)
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
