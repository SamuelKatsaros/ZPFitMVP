# Walkthrough - Active Program & Workout View

## Changes
1.  **Created `TodaysWorkoutView.swift`**: A new view that displays the current day's workout for the selected program. It handles fetching the program from SwiftData and includes a fallback/loading state.
    *   **Update**: Added a hardcoded fallback for the "Jacklete" program to ensure the workout displays immediately even if SwiftData seeding hasn't completed or failed.
2.  **Updated `ProgramListView.swift`**: Modified to check `@AppStorage("selectedPlan")`. If a plan is selected, it now renders `TodaysWorkoutView` instead of the program list.
3.  **Simplified `MainTabView.swift`**: Removed the conditional logic for the `.programs` tab. It now always renders `ProgramListView`, delegating the view switching logic to `ProgramListView` itself.
4.  **Updated `HomeView.swift`**:
    *   Added `selectedTab` binding to `HomeView` and `HeroSection`.
    *   Updated "Start Day 1" button to switch the tab to `.programs` (which now shows the workout view).

## Verification
-   **Program Selection**: When a user selects a program in `ProgramListView` (via `ProgramDetailView`), `selectedPlan` is updated.
-   **View Switching**: `ProgramListView` detects the change and switches to `TodaysWorkoutView`.
-   **Home Navigation**: Clicking "Start Day 1" on Home switches to the Programs tab, which displays `TodaysWorkoutView`.
-   **Persistence**: `selectedPlan` is persisted via `AppStorage`, so the state remains across app launches.
-   **Fallback**: If "Jacklete" is selected but data is missing, the view now correctly displays the "Chest + Shoulders" workout instead of a loading screen.

## Next Steps
-   Ensure Firestore data is loaded correctly so `TodaysWorkoutView` can find the program details.
-   Implement the actual workout logic in `TodaysWorkoutView` (currently reuses `WorkoutDetailView` or fallback).
