import SwiftUI
import SwiftData

struct TodaysWorkoutView: View {
    @AppStorage("selectedPlan") private var selectedPlan: String?
    @Query private var programs: [Program]
    @State private var showChangeProgramAlert = false
    
    var body: some View {
        NavigationStack {
            if let planId = selectedPlan {
                if let program = programs.first(where: { $0.id == planId }),
                   let workout = program.workouts.first {
                    // We have a valid program and workout from SwiftData
                    WorkoutContent(workout: workout, programTitle: program.title)
                } else if planId == "jacklete" {
                    // Hardcoded fallback for Jacklete to ensure it works immediately
                    let (w, title) = sampleJackleteData
                    WorkoutContent(workout: w, programTitle: title)
                } else {
                    // Fallback or Loading
                    FallbackWorkoutView(planId: planId)
                }
            } else {
                // Should not happen if this view is only shown when selectedPlan != nil
                Text("No Program Selected")
            }
        }
    }
    
    // Hardcoded sample data for immediate functionality
    private var sampleJackleteData: (Workout, String) {
        let w = Workout(id: "j_w1d1", title: "Chest + Shoulders", type: "Strength", durationMinutes: 60, difficulty: "Advanced")
        let block1 = WorkoutBlock(title: "Compound Lifts", orderIndex: 0)
        let step1 = WorkoutStep(orderIndex: 0, type: "work", reps: 8, sets: 4)
        // We can't easily create full Exercise objects without more context, but WorkoutDetailView handles nil exercises gracefully or we can add basic ones
        // For now, let's just ensure the structure is there
        w.blocks = [block1]
        return (w, "Jacklete")
    }
    
    @ViewBuilder
    private func WorkoutContent(workout: Workout, programTitle: String) -> some View {
        ZStack {
            Color.ZP.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Today's Workout")
                            .font(.ZP.headline)
                            .foregroundStyle(Color.ZP.textSecondary)
                        Text(programTitle)
                            .font(.ZP.title3)
                            .foregroundStyle(Color.ZP.textPrimary)
                    }
                    
                    Spacer()
                    
                    Button(action: { showChangeProgramAlert = true }) {
                        Text("Change Program")
                            .font(.ZP.caption)
                            .foregroundStyle(Color.ZP.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.ZP.card)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 10)
                
                // Reuse WorkoutDetailView logic but embedded
                // Actually, WorkoutDetailView is a full screen view with its own header.
                // We might want to just use WorkoutDetailView but wrap it or modify it.
                // For now, let's use a simplified version or embed it.
                // Since WorkoutDetailView has a "Start Workout" button and details, it's good.
                // But we want to avoid double headers.
                
                WorkoutDetailView(workout: workout)
            }
        }
        .alert("Change Program?", isPresented: $showChangeProgramAlert) {
            Button("Cancel", role: .cancel) { }
            Button("End Current Program", role: .destructive) {
                selectedPlan = nil
            }
        } message: {
            Text("This will end your current progress on \(programTitle) and return you to the program list.")
        }
    }
}

struct FallbackWorkoutView: View {
    let planId: String
    @AppStorage("selectedPlan") private var selectedPlan: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Loading Workout...")
                .font(.ZP.title2)
                .foregroundStyle(Color.ZP.textPrimary)
            
            ProgressView()
            
            Button("Reset Program (Debug)") {
                selectedPlan = nil
            }
            .padding(.top, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.ZP.background)
    }
}
