import SwiftUI

/// Reusable stat card for displaying run statistics
struct RunStatCard: View {
    let icon: String?
    let value: String
    let unit: String?
    let label: String
    let valueColor: Color
    let showAnimation: Bool
    
    @State private var displayedValue: String = ""
    @State private var hasAnimated = false
    
    init(
        icon: String? = nil,
        value: String,
        unit: String? = nil,
        label: String,
        valueColor: Color = Color.ZP.textPrimary,
        showAnimation: Bool = true
    ) {
        self.icon = icon
        self.value = value
        self.unit = unit
        self.label = label
        self.valueColor = valueColor
        self.showAnimation = showAnimation
    }
    
    var body: some View {
        VStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(Color.ZP.textSecondary)
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(showAnimation && hasAnimated ? displayedValue : value)
                    .font(.ZP.runStat)
                    .foregroundStyle(valueColor)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                
                if let unit = unit {
                    Text(unit)
                        .font(.ZP.runStatLabel)
                        .foregroundStyle(Color.ZP.textSecondary)
                }
            }
            
            Text(label)
                .font(.ZP.runStatLabel)
                .foregroundStyle(Color.ZP.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .onChange(of: value) { oldValue, newValue in
            if showAnimation {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    displayedValue = newValue
                }
            }
        }
        .onAppear {
            displayedValue = value
            hasAnimated = true
        }
    }
}

/// Large stat display for primary metrics (duration, distance)
struct RunPrimaryStat: View {
    let value: String
    let unit: String?
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(value)
                    .font(.ZP.runTimer)
                    .foregroundStyle(Color.ZP.textPrimary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                
                if let unit = unit {
                    Text(unit)
                        .font(.ZP.runStatSecondary)
                        .foregroundStyle(Color.ZP.textSecondary)
                        .padding(.bottom, 12) // Align better with large text
                }
            }
            
            Text(label)
                .font(.ZP.runStatLabel)
                .foregroundStyle(Color.ZP.textSecondary)
                .textCase(.uppercase)
                .tracking(1)
        }
    }
}

/// Split row for displaying mile splits
struct SplitRow: View {
    let mileNumber: Int
    let time: String
    let isFastest: Bool
    let isSlowest: Bool
    
    var body: some View {
        HStack {
            Text("Mile \(mileNumber)")
                .font(.ZP.runSplit)
                .foregroundStyle(Color.ZP.textSecondary)
            
            Spacer()
            
            HStack(spacing: 8) {
                Text(time)
                    .font(.ZP.runSplit)
                    .foregroundStyle(Color.ZP.textPrimary)
                    .monospacedDigit()
                
                if isFastest {
                    Image(systemName: "bolt.fill")
                        .font(.caption)
                        .foregroundStyle(Color.ZP.splitFast)
                }
                
                if isSlowest {
                    Image(systemName: "tortoise.fill")
                        .font(.caption)
                        .foregroundStyle(Color.ZP.splitSlow)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.ZP.card)
    }
}

#Preview {
    ZStack {
        Color.ZP.background.ignoresSafeArea()
        
        VStack(spacing: 32) {
            RunPrimaryStat(value: "12:45", unit: nil, label: "Duration")
            
            HStack(spacing: 24) {
                RunStatCard(
                    icon: "figure.run",
                    value: "3.24",
                    unit: "mi",
                    label: "Distance"
                )
                
                RunStatCard(
                    icon: "speedometer",
                    value: "8:32",
                    unit: "/mi",
                    label: "Pace"
                )
            }
            .padding(.horizontal, 24)
            
            VStack(spacing: 1) {
                SplitRow(mileNumber: 1, time: "8:23", isFastest: true, isSlowest: false)
                SplitRow(mileNumber: 2, time: "8:45", isFastest: false, isSlowest: false)
                SplitRow(mileNumber: 3, time: "9:12", isFastest: false, isSlowest: true)
            }
            .cornerRadius(12)
            .padding(.horizontal, 24)
        }
    }
}
