# ZP Fit - Runbook

## Prerequisites
- Xcode 15.0+ (iOS 17 SDK)
- macOS Sonoma or later

## Getting Started
1. **Clone the repository**.
2. **Open `ZPFit.xcodeproj`** in Xcode.
3. **Select the `ZPFit` scheme**.
4. **Choose a Simulator** (e.g., iPhone 15 Pro).
5. **Run (Cmd+R)**.

## Architecture Overview
The app follows a **MVVM + Coordinator + Services** pattern:
- **Core**: Contains `DIContainer`, `Services` (Persistence, UserProfile, Subscription), `Models` (SwiftData), and `DesignSystem`.
- **Features**: Organized by feature (Home, Programs, WorkoutPlayer, etc.). Each feature has its own Views and ViewModels.
- **UIComponents**: Reusable UI elements (Buttons, Cards, Headers).

## Key Services
- **PersistenceService**: Manages the SwiftData `ModelContainer`. Seeds initial data from `Resources/SeedData.json` on first launch.
- **UserProfileService**: Manages the current user's profile and onboarding state.
- **SubscriptionService**: Handles StoreKit 2 interactions (mocked for development).
- **NotificationService**: Manages local user notifications.

## Troubleshooting
- **Preview Crashes**: Ensure `DIContainer` is properly injected in the Preview provider. Most views require `.environment(\.diContainer, ...)` and `.modelContainer(...)`.
- **Data Issues**: If data looks wrong, delete the app from the simulator to reset the SwiftData store and re-seed from JSON.

## Testing
- **Unit Tests**: Located in `ZPFitTests` (Placeholder).
- **UI Tests**: Located in `ZPFitUITests` (Placeholder).
