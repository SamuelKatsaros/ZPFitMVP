import SwiftUI
import SwiftData

struct ProgramListView: View {
    @State private var showWorkout = false
    
    // Sample workout for the hero card
    private var heroWorkout: Workout {
        let workout = Workout(
            id: "hero-workout",
            title: "ZP's 20 Minute Burn Session",
            type: "HIIT",
            durationMinutes: 20,
            difficulty: "Intermediate"
        )
        
        // Create a workout block
        let block = WorkoutBlock(title: "Main Set", orderIndex: 0)
        
        // Create exercises
        let jumpingJacks = Exercise(
            id: "jumping-jacks",
            name: "Jumping Jacks",
            instructions: "Jump with arms and legs spread",
            videoURL: "https://pub-1750bfb161e049c787c9c9bffaad69ef.r2.dev/W1D1.mp4",
            thumbnailURL: "",
            muscleGroup: "Full Body"
        )
        
        let burpees = Exercise(
            id: "burpees",
            name: "Burpees",
            instructions: "Full body explosive movement",
            videoURL: "https://pub-1750bfb161e049c787c9c9bffaad69ef.r2.dev/W1D1.mp4",
            thumbnailURL: "",
            muscleGroup: "Full Body"
        )
        
        // Create workout steps
        let step1 = WorkoutStep(orderIndex: 0, type: "work", durationSeconds: 45)
        step1.exercise = jumpingJacks
        
        let rest1 = WorkoutStep(orderIndex: 1, type: "rest", durationSeconds: 15)
        
        let step2 = WorkoutStep(orderIndex: 2, type: "work", durationSeconds: 45)
        step2.exercise = burpees
        
        let rest2 = WorkoutStep(orderIndex: 3, type: "rest", durationSeconds: 15)
        
        block.steps = [step1, rest1, step2, rest2]
        workout.blocks = [block]
        
        return workout
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Hero Card
                        NavigationLink(destination: WorkoutDetailView(
                            workout: heroWorkout,
                            videoURL: URL(string: "https://pub-1750bfb161e049c787c9c9bffaad69ef.r2.dev/W1D1.mp4")
                        )) {
                            ZStack(alignment: .bottomLeading) {
                                Rectangle()
                                    .fill(Color.black)
                                    .frame(height: 220)
                                    .cornerRadius(24)
                                
                                VideoThumbnailView(videoURL: URL(string: "https://pub-1750bfb161e049c787c9c9bffaad69ef.r2.dev/W1D1.mp4")!)
                                    .frame(height: 220)
                                    .cornerRadius(24)
                                    .opacity(0.7)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("ZP's 20 Minute\nBurn Session")
                                        .font(.ZP.title1)
                                        .foregroundStyle(Color.white)
                                    
                                    HStack(spacing: 4) {
                                        Text("Start Workout")
                                            .font(.ZP.subheadline)
                                            .foregroundStyle(Color.ZP.accent)
                                        Image(systemName: "play.circle.fill")
                                            .foregroundStyle(Color.ZP.accent)
                                    }
                                }
                                .padding(24)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Best for you
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Best for you")
                                .font(.ZP.title2)
                                .foregroundStyle(Color.black)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                BestForYouCard(title: "Ab Sequence", duration: "10 min", level: "Beginner", imageName: "figure.core.training")
                                BestForYouCard(title: "HIIT Session", duration: "10 min", level: "Beginner", imageName: "figure.highintensity.intervaltraining")
                                BestForYouCard(title: "Quick Sprint", duration: "5 min", level: "Expert", imageName: "figure.run")
                                BestForYouCard(title: "Weights", duration: "30 min", level: "Intermediate", imageName: "dumbbell.fill")
                            }
                        }
                        
                        // Challenge
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Challenge")
                                .font(.ZP.title2)
                                .foregroundStyle(Color.black)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ChallengeCard(title: "Abs", icon: "flame.fill", backgroundColor: Color.ZP.accent, textColor: Color.black)
                                    ChallengeCard(title: "Sprint", icon: "figure.run", backgroundColor: Color.black, textColor: Color.white)
                                    ChallengeCard(title: "Distance", icon: "waterbottle.fill", backgroundColor: Color.white, textColor: Color.black, hasBorder: true)
                                }
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Explore")
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

struct BestForYouCard: View {
    let title: String
    let duration: String
    let level: String
    let imageName: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.ZP.headline)
                    .foregroundStyle(Color.black)
                    .lineLimit(1)
                
                Text(duration)
                    .font(.ZP.caption)
                    .foregroundStyle(Color.ZP.textSecondary)
                
                Text(level)
                    .font(.ZP.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.ZP.lightCard)
                    .cornerRadius(4)
                    .foregroundStyle(Color.ZP.textSecondary)
            }
            Spacer()
            Image(systemName: imageName)
                .font(.title2)
                .foregroundStyle(Color.ZP.accent)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
}

struct ChallengeCard: View {
    let title: String
    let icon: String
    let backgroundColor: Color
    let textColor: Color
    var hasBorder: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.ZP.headline)
                .foregroundStyle(textColor)
            
            Spacer()
            
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(textColor.opacity(0.8))
        }
        .padding()
        .frame(width: 110, height: 110)
        .background(backgroundColor)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.2), lineWidth: hasBorder ? 1 : 0)
        )
    }
}
