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
                Color.ZP.lightBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Premium Header
                        premiumHeader
                        
                        // Quick Stats
                        quickStatsSection
                        
                        // Membership Card
                        membershipCard
                        
                        // Achievements
                        achievementsSection
                        
                        // Settings
                        settingsSection
                        
                        // About
                        aboutSection
                        
                        // Logout Button
                        logoutButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100) // Extra padding for tab bar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                    animateStats = true
                }
            }
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
    
    // MARK: - Premium Header
    private var premiumHeader: some View {
        VStack(spacing: 16) {
            // Avatar and Name
            VStack(spacing: 12) {
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.ZP.accent.opacity(0.3), Color.ZP.accent.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(String((diContainer.userProfileService.currentUser?.name ?? "ZP").prefix(2).uppercased()))
                                .font(.ZP.largeTitle)
                                .foregroundStyle(Color.ZP.textOnLight)
                        )
                        .shadow(color: Color.ZP.accent.opacity(0.3), radius: 12, x: 0, y: 4)
                    
                    // Premium Badge
                    if subscriptionService.isPremium {
                        Circle()
                            .fill(Color.ZP.accent)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.ZP.textBlack)
                            )
                            .shadow(color: Color.ZP.accent.opacity(0.5), radius: 8, x: 0, y: 0)
                    }
                }
                
                VStack(spacing: 4) {
                    Text(diContainer.userProfileService.currentUser?.name ?? "Athlete")
                        .font(.ZP.title1)
                        .foregroundStyle(Color.ZP.textOnLight)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                        Text("Member since 2025")
                            .font(.ZP.subheadline)
                    }
                    .foregroundStyle(Color.gray)
                }
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.white, Color.ZP.lightCard],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
    }
    
    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                QuickStatCard(
                    icon: "figure.run",
                    value: "12",
                    label: "Workouts",
                    color: Color.ZP.accent,
                    animate: animateStats
                )
                
                QuickStatCard(
                    icon: "flame.fill",
                    value: "7",
                    label: "Day Streak",
                    color: Color.orange,
                    animate: animateStats
                )
                
                QuickStatCard(
                    icon: "clock.fill",
                    value: "8.5h",
                    label: "Total Time",
                    color: Color.blue,
                    animate: animateStats
                )
                
                QuickStatCard(
                    icon: "bolt.fill",
                    value: "4.2k",
                    label: "Calories",
                    color: Color.purple,
                    animate: animateStats
                )
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Membership Card
    private var membershipCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Membership")
                        .font(.ZP.caption)
                        .foregroundStyle(Color.gray)
                    
                    Text(subscriptionService.isPremium ? "PREMIUM" : "FREE")
                        .font(.ZP.title1)
                        .foregroundStyle(Color.ZP.textOnLight)
                }
                
                Spacer()
                
                if subscriptionService.isPremium {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.ZP.accent)
                        .shadow(color: Color.ZP.accent.opacity(0.5), radius: 8, x: 0, y: 0)
                }
            }
            
            if subscriptionService.isPremium {
                VStack(alignment: .leading, spacing: 8) {
                    MembershipBenefit(text: "Unlimited access to all programs")
                    MembershipBenefit(text: "1-on-1 coaching sessions")
                    MembershipBenefit(text: "Advanced analytics & insights")
                    MembershipBenefit(text: "Priority support")
                }
            } else {
                VStack(spacing: 12) {
                    Text("Unlock all features and take your fitness to the next level")
                        .font(.ZP.callout)
                        .foregroundStyle(Color.gray)
                        .multilineTextAlignment(.leading)
                    
                    Button(action: {
                        // Show paywall
                    }) {
                        HStack {
                            Text("Upgrade to Premium")
                                .font(.ZP.headline)
                                .foregroundStyle(Color.ZP.textBlack)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.right")
                                .foregroundStyle(Color.ZP.textBlack)
                        }
                        .padding()
                        .background(Color.ZP.accent)
                        .cornerRadius(12)
                        .shadow(color: Color.ZP.accent.opacity(0.4), radius: 12, x: 0, y: 4)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                if subscriptionService.isPremium {
                    LinearGradient(
                        colors: [Color.ZP.accent.opacity(0.15), Color.ZP.accent.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    Color.white
                }
            }
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(subscriptionService.isPremium ? Color.ZP.accent.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
    }
    
    // MARK: - Achievements Section
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements")
                .font(.ZP.headline)
                .foregroundStyle(Color.ZP.textOnLight)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                AchievementBadge(icon: "figure.run", title: "First Workout", unlocked: true, color: Color.ZP.accent)
                AchievementBadge(icon: "flame.fill", title: "7-Day Streak", unlocked: true, color: Color.orange)
                AchievementBadge(icon: "star.fill", title: "100 Workouts", unlocked: false, color: Color.blue)
                AchievementBadge(icon: "trophy.fill", title: "Marathon", unlocked: false, color: Color.purple)
                AchievementBadge(icon: "bolt.fill", title: "Power User", unlocked: false, color: Color.yellow)
                AchievementBadge(icon: "heart.fill", title: "Consistency", unlocked: true, color: Color.pink)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
    }
    
    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(spacing: 0) {
            SettingsRow(
                icon: "bell.fill",
                title: "Notifications",
                color: Color.ZP.accent,
                showToggle: true,
                isOn: Binding(
                    get: { notificationService.isAuthorized },
                    set: { _ in notificationService.requestAuthorization() }
                )
            )
            
            Divider().padding(.leading, 56)
            
            NavigationLink(destination: Text("Schedule Picker Placeholder")) {
                SettingsRow(
                    icon: "calendar",
                    title: "Workout Schedule",
                    color: Color.blue,
                    showChevron: true
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        VStack(spacing: 0) {
            Link(destination: URL(string: "https://zpfit.com/terms")!) {
                SettingsRow(
                    icon: "doc.text.fill",
                    title: "Terms of Service",
                    color: Color.gray,
                    showChevron: true
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider().padding(.leading, 56)
            
            Link(destination: URL(string: "https://zpfit.com/privacy")!) {
                SettingsRow(
                    icon: "lock.fill",
                    title: "Privacy Policy",
                    color: Color.gray,
                    showChevron: true
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider().padding(.leading, 56)
            
            SettingsRow(
                icon: "info.circle.fill",
                title: "Version",
                color: Color.gray,
                trailingText: "1.0.0"
            )
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
    }
    
    // MARK: - Logout Button
    private var logoutButton: some View {
        Button(action: {
            showLogoutAlert = true
        }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16))
                Text("Log Out")
                    .font(.ZP.headline)
            }
            .foregroundStyle(Color.ZP.error)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
    }
}

// MARK: - Supporting Views

struct QuickStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let animate: Bool
    
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
            
            Text(value)
                .font(.ZP.title2)
                .foregroundStyle(Color.ZP.textOnLight)
            
            Text(label)
                .font(.ZP.caption)
                .foregroundStyle(Color.gray)
        }
        .frame(width: 100)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .scaleEffect(scale)
        .opacity(opacity)
        .onChange(of: animate) { newValue in
            if newValue {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
        }
    }
}

struct MembershipBenefit: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(Color.ZP.accent)
            
            Text(text)
                .font(.ZP.callout)
                .foregroundStyle(Color.ZP.textOnLight)
        }
    }
}

struct AchievementBadge: View {
    let icon: String
    let title: String
    let unlocked: Bool
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(unlocked ? color.opacity(0.2) : Color.gray.opacity(0.1))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundStyle(unlocked ? color : Color.gray.opacity(0.4))
                )
            
            Text(title)
                .font(.ZP.caption)
                .foregroundStyle(unlocked ? Color.ZP.textOnLight : Color.gray)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    var showToggle: Bool = false
    var isOn: Binding<Bool>? = nil
    var showChevron: Bool = false
    var trailingText: String? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(color)
                )
            
            Text(title)
                .font(.ZP.body)
                .foregroundStyle(Color.ZP.textOnLight)
            
            Spacer()
            
            if showToggle, let binding = isOn {
                Toggle("", isOn: binding)
                    .labelsHidden()
                    .tint(Color.ZP.accent)
            } else if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.gray)
            } else if let text = trailingText {
                Text(text)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(Color.gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
