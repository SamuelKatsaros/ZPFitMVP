import Foundation
import SwiftData
import SwiftUI

struct ProgramDataSeeder {
    static func seed(context: ModelContext) {
        // Check if data exists
        let descriptor = FetchDescriptor<Program>()
        if let count = try? context.fetchCount(descriptor), count > 0 {
            return // Already seeded
        }
        
        // 1. Jacklete (Build Muscle)
        let jacklete = Program(
            id: "jacklete",
            title: "Jacklete",
            subtitle: "Build muscle, strength, and explosive power",
            difficulty: "Advanced",
            durationWeeks: 9,
            coverImage: "https://lirp.cdn-website.com/cee6e347/dms3rep/multi/opt/new-zach-img-02-640w.jpg"
        )
        
        // Jacklete Workouts (Week 1)
        let j_w1d1 = Workout(id: "j_w1d1", title: "Chest + Shoulders", type: "Strength", durationMinutes: 60, difficulty: "Advanced")
        let j_w1d2 = Workout(id: "j_w1d2", title: "Legs - Quad Focus", type: "Strength", durationMinutes: 75, difficulty: "Advanced")
        let j_w1d3 = Workout(id: "j_w1d3", title: "Back + Rear Delts", type: "Strength", durationMinutes: 60, difficulty: "Advanced")
        let j_w1d4 = Workout(id: "j_w1d4", title: "Rest & Recovery", type: "Rest", durationMinutes: 0, difficulty: "None")
        let j_w1d5 = Workout(id: "j_w1d5", title: "Arms + Abs", type: "Hypertrophy", durationMinutes: 45, difficulty: "Intermediate")
        let j_w1d6 = Workout(id: "j_w1d6", title: "Legs - Hamstring Focus", type: "Strength", durationMinutes: 70, difficulty: "Advanced")
        let j_w1d7 = Workout(id: "j_w1d7", title: "Rest", type: "Rest", durationMinutes: 0, difficulty: "None")
        
        jacklete.workouts = [j_w1d1, j_w1d2, j_w1d3, j_w1d4, j_w1d5, j_w1d6, j_w1d7]
        
        // Add exercises to W1D1 (Sample)
        let benchPress = Exercise(id: "bench_press", name: "Barbell Bench Press", instructions: "Flat bench press", videoURL: "", thumbnailURL: "", muscleGroup: "Chest")
        let inclineDb = Exercise(id: "incline_db", name: "Incline DB Press", instructions: "Incline dumbbell press", videoURL: "", thumbnailURL: "", muscleGroup: "Chest")
        
        let block1 = WorkoutBlock(title: "Compound Lifts", orderIndex: 0)
        let step1 = WorkoutStep(orderIndex: 0, type: "work", reps: 8, sets: 4)
        step1.exercise = benchPress
        let step2 = WorkoutStep(orderIndex: 1, type: "work", reps: 10, sets: 3)
        step2.exercise = inclineDb
        
        block1.steps = [step1, step2]
        j_w1d1.blocks = [block1]
        
        
        // 2. STNDRD6 (Lose Weight / Transformation)
        let stndrd = Program(
            id: "stndrd6",
            title: "STNDRD6: SHIFT",
            subtitle: "6-week transformation program",
            difficulty: "Intermediate",
            durationWeeks: 6,
            coverImage: "https://lirp.cdn-website.com/cee6e347/dms3rep/multi/opt/new-zach-img-03-640w.jpg"
        )
        
        let s_w1d1 = Workout(id: "s_w1d1", title: "Full Body Ignition", type: "HIIT", durationMinutes: 45, difficulty: "Intermediate")
        let s_w1d2 = Workout(id: "s_w1d2", title: "Cardio Flow", type: "Cardio", durationMinutes: 30, difficulty: "Beginner")
        let s_w1d3 = Workout(id: "s_w1d3", title: "Upper Body Sculpt", type: "Strength", durationMinutes: 45, difficulty: "Intermediate")
        let s_w1d4 = Workout(id: "s_w1d4", title: "Active Recovery", type: "Recovery", durationMinutes: 20, difficulty: "None")
        let s_w1d5 = Workout(id: "s_w1d5", title: "Lower Body Power", type: "Strength", durationMinutes: 50, difficulty: "Intermediate")
        let s_w1d6 = Workout(id: "s_w1d6", title: "Metabolic Conditioning", type: "HIIT", durationMinutes: 40, difficulty: "Advanced")
        let s_w1d7 = Workout(id: "s_w1d7", title: "Rest", type: "Rest", durationMinutes: 0, difficulty: "None")
        
        stndrd.workouts = [s_w1d1, s_w1d2, s_w1d3, s_w1d4, s_w1d5, s_w1d6, s_w1d7]
        
        
        // 3. Hybrid Athlete (Get Stronger / Endurance)
        let hybrid = Program(
            id: "hybrid",
            title: "Hybrid Athlete",
            subtitle: "Endurance and strength combined",
            difficulty: "Expert",
            durationWeeks: 12,
            coverImage: "https://lirp.cdn-website.com/cee6e347/dms3rep/multi/opt/IMG_2678-afe97dc5-640w.PNG"
        )
        
        let h_w1d1 = Workout(id: "h_w1d1", title: "Run + Squat", type: "Hybrid", durationMinutes: 90, difficulty: "Expert")
        let h_w1d2 = Workout(id: "h_w1d2", title: "Upper Power", type: "Strength", durationMinutes: 60, difficulty: "Advanced")
        let h_w1d3 = Workout(id: "h_w1d3", title: "Zone 2 Run", type: "Cardio", durationMinutes: 45, difficulty: "Intermediate")
        let h_w1d4 = Workout(id: "h_w1d4", title: "Deadlift + Accessories", type: "Strength", durationMinutes: 70, difficulty: "Advanced")
        let h_w1d5 = Workout(id: "h_w1d5", title: "Tempo Run", type: "Cardio", durationMinutes: 40, difficulty: "Advanced")
        let h_w1d6 = Workout(id: "h_w1d6", title: "Long Run", type: "Cardio", durationMinutes: 90, difficulty: "Intermediate")
        let h_w1d7 = Workout(id: "h_w1d7", title: "Rest", type: "Rest", durationMinutes: 0, difficulty: "None")
        
        hybrid.workouts = [h_w1d1, h_w1d2, h_w1d3, h_w1d4, h_w1d5, h_w1d6, h_w1d7]
        
        // Insert
        context.insert(jacklete)
        context.insert(stndrd)
        context.insert(hybrid)
        
        try? context.save()
    }
}
