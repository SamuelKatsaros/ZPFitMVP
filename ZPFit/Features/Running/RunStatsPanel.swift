import SwiftUI

/// Floating stats panel overlay for active run tracking
struct RunStatsPanel: View {
    @ObservedObject var viewModel: RunTrackingViewModel
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 16)
            
            // Primary stat - Duration
            RunPrimaryStat(
                value: viewModel.elapsedTimeFormatted,
                unit: nil,
                label: "Duration"
            )
            .padding(.bottom, 20)
            
            // Secondary stats row
            HStack(spacing: 0) {
                // Distance
                VStack(spacing: 4) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(viewModel.distanceFormatted)
                            .font(.ZP.runStat)
                            .foregroundStyle(Color.ZP.textPrimary)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        
                        Text("mi")
                            .font(.ZP.runStatLabel)
                            .foregroundStyle(Color.ZP.textSecondary)
                    }
                    
                    Text("Distance")
                        .font(.ZP.runStatLabel)
                        .foregroundStyle(Color.ZP.textSecondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                .frame(maxWidth: .infinity)
                
                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 1, height: 50)
                
                // Pace
                VStack(spacing: 4) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(viewModel.paceFormatted)
                            .font(.ZP.runStat)
                            .foregroundStyle(Color.ZP.textPrimary)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        
                        Text("/mi")
                            .font(.ZP.runStatLabel)
                            .foregroundStyle(Color.ZP.textSecondary)
                    }
                    
                    Text("Pace")
                        .font(.ZP.runStatLabel)
                        .foregroundStyle(Color.ZP.textSecondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.bottom, 16)
            
            // Expanded content
            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height < -50 && !isExpanded {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            onToggleExpand()
                        }
                    } else if value.translation.height > 50 && isExpanded {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            onToggleExpand()
                        }
                    }
                }
        )
    }
    
    private var expandedContent: some View {
        VStack(spacing: 16) {
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Additional stats row
            HStack(spacing: 0) {
                // Elevation
                VStack(spacing: 4) {
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(Color.ZP.textSecondary)
                        
                        Text(viewModel.elevationFormatted)
                            .font(.ZP.runStatSecondary)
                            .foregroundStyle(Color.ZP.textPrimary)
                            .monospacedDigit()
                        
                        Text("ft")
                            .font(.ZP.runStatLabel)
                            .foregroundStyle(Color.ZP.textSecondary)
                    }
                    
                    Text("Elevation")
                        .font(.ZP.runStatLabel)
                        .foregroundStyle(Color.ZP.textSecondary)
                }
                .frame(maxWidth: .infinity)
                
                // Current Mile
                VStack(spacing: 4) {
                    Text("Mile \(viewModel.currentMileNumber)")
                        .font(.ZP.runStatSecondary)
                        .foregroundStyle(Color.ZP.textPrimary)
                    
                    // Progress bar for current mile
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 4)
                            
                            Capsule()
                                .fill(Color.ZP.primary)
                                .frame(width: geometry.size.width * viewModel.currentSplitProgress, height: 4)
                        }
                    }
                    .frame(height: 4)
                    .padding(.horizontal, 20)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Splits section (if any)
            if !viewModel.splits.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Splits")
                        .font(.ZP.headline)
                        .foregroundStyle(Color.ZP.textSecondary)
                        .padding(.leading, 4)
                    
                    ForEach(Array(viewModel.splits.enumerated()), id: \.offset) { index, split in
                        HStack {
                            Text("Mile \(index + 1)")
                                .font(.ZP.caption)
                                .foregroundStyle(Color.ZP.textSecondary)
                            
                            Spacer()
                            
                            Text(formatSplit(split))
                                .font(.ZP.runSplit)
                                .foregroundStyle(Color.ZP.textPrimary)
                                .monospacedDigit()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
    
    private func formatSplit(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

#Preview {
    ZStack {
        Color.ZP.background.ignoresSafeArea()
        
        VStack {
            Spacer()
            
            RunStatsPanel(
                viewModel: RunTrackingViewModel(
                    locationService: LocationService(),
                    firestoreService: FirestoreService(),
                    authService: AuthenticationService(firestoreService: FirestoreService())
                ),
                isExpanded: false,
                onToggleExpand: {}
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
    }
}
