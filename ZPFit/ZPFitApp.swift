//
//  ZPFitApp.swift
//  ZPFit
//
//  Created by Samuel E Katsaros on 11/21/25.
//

import SwiftUI
import SwiftData

@main
struct ZPFitApp: App {
    // Initialize DIContainer as a static shared instance (no need for @StateObject)
    private let diContainer = DIContainer.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.diContainer, diContainer)
                .environmentObject(diContainer.subscriptionService) // Inject as EnvironmentObject for easy access
                .modelContainer(diContainer.persistenceService.container)
                .preferredColorScheme(.dark) // Force dark mode for premium feel
        }
    }
}
