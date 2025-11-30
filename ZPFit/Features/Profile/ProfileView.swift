import SwiftUI

struct ProfileView: View {
    @Environment(\.diContainer) private var diContainer
    @EnvironmentObject var subscriptionService: SubscriptionService
    @StateObject private var notificationService = NotificationService()
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = true
    @State private var showLogoutAlert = false
    @State private var animateStats = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.ZP.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Premium Header
                        ProfileHeader()
                        
                        // Stats Grid
                        StatsGrid()
                        
                        // Membership Card
                        MembershipCard()
                        
                        // Settings List
                        SettingsList()
                        
                        // Logout
                        LogoutButton(showLogoutAlert: $showLogoutAlert)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
            .alert("Log Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    hasCompletedOnboarding = false
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }
}

// MARK: - Components

struct ProfileHeader: View {
    @Environment(\.diContainer) private var diContainer
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.ZP.cardHover)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text("SK")
                            .font(.ZP.largeTitle)
                            .foregroundStyle(Color.ZP.textPrimary)
                    )
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(Color.ZP.primary)
                    .background(Circle().fill(Color.black).padding(2))
            }
            
            VStack(spacing: 4) {
                Text("Sam Katsaros")
                    .font(.ZP.title1)
                    .foregroundStyle(Color.ZP.textPrimary)
                
                Text("Member since 2025")
                    .font(.ZP.subheadline)
                    .foregroundStyle(Color.ZP.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

struct StatsGrid: View {
    var body: some View {
        HStack(spacing: 16) {
            StatCard(title: "Workouts", value: "12", unit: "", icon: "figure.run")
            StatCard(title: "Calories", value: "4.2k", unit: "", icon: "flame.fill")
            StatCard(title: "Hours", value: "8.5h", unit: "", icon: "clock.fill")
        }
        .padding(.horizontal, 20)
    }
}

struct MembershipCard: View {
    @EnvironmentObject var subscriptionService: SubscriptionService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Membership")
                    .font(.ZP.headline)
                    .foregroundStyle(Color.ZP.textSecondary)
                Spacer()
                if subscriptionService.isPremium {
                    Text("PRO")
                        .font(.ZP.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.ZP.primary)
                        .foregroundStyle(Color.black)
                        .cornerRadius(8)
                }
            }
            
            Text(subscriptionService.isPremium ? "Premium Access" : "Free Plan")
                .font(.ZP.title2)
                .foregroundStyle(Color.ZP.textPrimary)
            
            if !subscriptionService.isPremium {
                Button(action: {}) {
                    Text("Upgrade to Premium")
                        .font(.ZP.headline)
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.ZP.primary)
                        .cornerRadius(16)
                }
            }
        }
        .padding(24)
        .background(Color.ZP.card)
        .cornerRadius(24)
        .padding(.horizontal, 20)
    }
}

struct SettingsList: View {
    var body: some View {
        VStack(spacing: 1) {
            SettingsItem(icon: "bell.fill", title: "Notifications")
            SettingsItem(icon: "lock.fill", title: "Privacy")
            SettingsItem(icon: "gear", title: "General")
            SettingsItem(icon: "questionmark.circle.fill", title: "Support")
        }
        .background(Color.ZP.card)
        .cornerRadius(20)
        .padding(.horizontal, 20)
    }
}

struct SettingsItem: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.ZP.textSecondary)
                .frame(width: 24)
            
            Text(title)
                .font(.ZP.body)
                .foregroundStyle(Color.ZP.textPrimary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.ZP.textSecondary)
        }
        .padding(20)
        .background(Color.ZP.card) // Ensure background for tap target
    }
}

struct LogoutButton: View {
    @Binding var showLogoutAlert: Bool
    
    var body: some View {
        Button(action: { showLogoutAlert = true }) {
            Text("Log Out")
                .font(.ZP.headline)
                .foregroundStyle(Color.ZP.error)
                .padding()
        }
    }
}
