//
//  ZPFitApp.swift
//  ZPFit
//
//  Created by Samuel E Katsaros on 11/21/25.
//

import SwiftUI
import SwiftData
import FirebaseCore

@main
struct ZPFitApp: App {
    
    // Configure Firebase at the very start, before anything else
    init() {
        setupFirebase()
    }
    
    // Static setup to ensure Firebase is configured before DIContainer
    private func setupFirebase() {
        // Only configure once
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.diContainer, DIContainer.shared)
                .environmentObject(DIContainer.shared.subscriptionService)
                .environmentObject(DIContainer.shared.authenticationService)
                .environmentObject(DIContainer.shared.firestoreService)
                .modelContainer(DIContainer.shared.persistenceService.container)
                .preferredColorScheme(.dark) // Force dark mode for premium feel
        }
    }
}
