import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    
    enum Tab: String, CaseIterable {
        case home = "Home"
        case programs = "Explore"
        case calendar = "Stats"
        case profile = "Profile"
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .programs: return "figure.run"
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
                    HomeView()
                case .programs:
                    ProgramListView()
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
                        HStack(spacing: 8) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20))
                            
                            if selectedTab == tab {
                                Text(tab.rawValue)
                                    .font(.ZP.subheadline)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, selectedTab == tab ? 16 : 12)
                        .background(
                            ZStack {
                                if selectedTab == tab {
                                    Capsule()
                                        .fill(Color.ZP.accent)
                                        .matchedGeometryEffect(id: "TabBackground", in: namespace)
                                }
                            }
                        )
                        .foregroundStyle(selectedTab == tab ? Color.ZP.textBlack : Color.white)
                    }
                    .frame(maxWidth: selectedTab == tab ? .infinity : 60)
                    
                    if tab != Tab.allCases.last {
                        Spacer(minLength: 4)
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(Color.black)
            .cornerRadius(32)
            .padding(.horizontal, 24) // Increased horizontal padding for floating look
            .padding(.bottom, 0) // Reduced bottom padding to bring it lower
        }
        .ignoresSafeArea(.keyboard)
    }
    
    @Namespace private var namespace
}
