import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    @AppStorage("selectedPlan") private var selectedPlan: String?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.diContainer) private var diContainer
    @Query private var programs: [Program]
    @State private var hasLoadedSessions = false
    
    enum Tab: String, CaseIterable {
        case home = "Home"
        case programs = "Explore"
        // case progress = "Progress" // Removed Progress tab
        case calendar = "Stats"
        case profile = "Profile"
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .programs: return "figure.run"
            // case .progress: return "chart.bar.fill" // Removed Progress tab icon
            case .calendar: return "chart.bar.fill"
            case .profile: return "person.fill"
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selectedTab {
                case .home:
                    HomeView(selectedTab: $selectedTab)
                case .programs:
                    ProgramsTabView()  // NEW: Wrapper that shows workout or list
                case .calendar:
                    CalendarView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Tab Bar
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 24))
                                .symbolEffect(.bounce, value: selectedTab == tab)
                            
                            if selectedTab == tab {
                                Circle()
                                    .fill(Color.ZP.primary)
                                    .frame(width: 4, height: 4)
                                    .matchedGeometryEffect(id: "TabIndicator", in: namespace)
                            } else {
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 4, height: 4)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(selectedTab == tab ? Color.ZP.primary : Color.ZP.textSecondary)
                        .padding(.vertical, 12)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .background(.ultraThinMaterial)
            .background(Color.black.opacity(0.4))
            .cornerRadius(32)
            .overlay(
                RoundedRectangle(cornerRadius: 32)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            // Load sessions once when entering the app
            // This replaces the automatic loading in AuthService to improve onboarding performance
            if !hasLoadedSessions {
                print("📱 MainTabView: Loading sessions on first appearance")
                diContainer.firestoreService.loadSessions()
                hasLoadedSessions = true
            }
        }
    }
    
    @Namespace private var namespace
}
