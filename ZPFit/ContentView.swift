//
//  ContentView.swift
//  ZPFit
//
//  Created by Samuel E Katsaros on 11/21/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    var body: some View {
        Group {
            if !authService.isAuthenticated {
                // Show onboarding/signup for unauthenticated users
                // Authentication is now integrated into onboarding flow
                OnboardingView(viewModel: OnboardingViewModel(
                    authService: DIContainer.shared.authenticationService,
                    firestoreService: DIContainer.shared.firestoreService
                ))
            } else {
                // Show main app if authenticated
                MainTabView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DIContainer.shared.authenticationService)
}
