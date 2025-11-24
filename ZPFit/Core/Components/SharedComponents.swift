import SwiftUI

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.ZP.title3)
            .foregroundStyle(Color.ZP.textPrimary)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(Color.ZP.accent)
                Spacer()
            }
            Text(value)
                .font(.ZP.title1)
                .foregroundStyle(Color.ZP.textPrimary)
            Text(unit)
                .font(.ZP.caption)
                .foregroundStyle(Color.ZP.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.ZP.card)
        .cornerRadius(16)
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let title: String
    let icon: String
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.ZP.accent)
                .padding(.bottom, 4)
            Text(title)
                .font(.ZP.caption)
                .foregroundStyle(Color.ZP.textPrimary)
        }
        .frame(width: 100, height: 100)
        .background(Color.ZP.card)
        .cornerRadius(16)
    }
}
