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
                // Show authentication screen if not logged in
                AuthenticationView()
            } else if hasCompletedOnboarding {
                // Show main app if authenticated and onboarded
                MainTabView()
            } else {
                // Show onboarding if authenticated but not onboarded
                OnboardingView(viewModel: OnboardingViewModel(userProfileService: DIContainer.shared.userProfileService))
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DIContainer.shared.authenticationService)
}
