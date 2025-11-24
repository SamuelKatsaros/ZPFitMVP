//
//  ContentView.swift
//  ZPFit
//
//  Created by Samuel E Katsaros on 11/21/25.
//

import SwiftUI

struct ContentView: View {
    // Simple routing state for now. 
    // In Phase 4, we will check AppStorage("hasCompletedOnboarding")
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    var body: some View {
        if hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingView(viewModel: OnboardingViewModel(userProfileService: DIContainer.shared.userProfileService))
        }
    }
}

#Preview {
    ContentView()
}
