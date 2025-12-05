//
//  ContentView.swift
//  ZPFit
//
//  Created by Samuel E Katsaros on 11/21/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var firestoreService: FirestoreService
    @Environment(\.diContainer) private var diContainer
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    @State private var showLoadingScreen = true
    
    var body: some View {
        ZStack {
            Group {
                if !authService.isAuthenticated || !hasCompletedOnboarding {
                    // Show onboarding for:
                    // 1. Unauthenticated users
                    // 2. Users who haven't completed onboarding flow
                    // 3. Authenticated users with incomplete Firestore profiles
                    
                    // Check if user is authenticated but has incomplete profile
                    let prefilledEmail = authService.isAuthenticated && !firestoreService.isProfileComplete
                    ? authService.currentUserEmail
                    : nil
                    
                    OnboardingView(viewModel: OnboardingViewModel(
                        authService: DIContainer.shared.authenticationService,
                        firestoreService: DIContainer.shared.firestoreService,
                        prefilledEmail: prefilledEmail
                    ))
                } else {
                    // Show main app ONLY if authenticated AND completed onboarding
                    MainTabView()
                }
            }
            .opacity(showLoadingScreen ? 0 : 1) // Hide content while loading
            
            // Global Loading Screen
            if showLoadingScreen {
                LoadingView()
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .onAppear {
            // Force loading screen for at least 2 seconds to mask data fetching
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showLoadingScreen = false
                }
            }
        }
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.ZP.background.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "figure.run") // Replace with App Logo if available
                    .font(.system(size: 80))
                    .foregroundStyle(Color.white)
                    .symbolEffect(.bounce, options: .repeating)
                
                Text("ZP FIT")
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(Color.white)
                    .tracking(4)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DIContainer.shared.authenticationService)
        .environmentObject(DIContainer.shared.firestoreService)
}
