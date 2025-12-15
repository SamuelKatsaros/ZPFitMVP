//
//  ZPFitApp.swift
//  ZPFit
//
//  Created by Samuel E Katsaros on 11/21/25.
//

import SwiftUI
import SwiftData
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct ZPFitApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
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
