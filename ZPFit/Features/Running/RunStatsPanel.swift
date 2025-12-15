import SwiftUI

/// Floating stats panel overlay for active run tracking - Clean design
struct RunStatsPanel: View {
    @ObservedObject var viewModel: RunTrackingViewModel
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    
    @State private var pulsePace = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(Color.white.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 16)
            
            // Primary stat - Duration (large)
            VStack(spacing: 4) {
                Text(viewModel.elapsedTimeFormatted)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: viewModel.elapsedTimeFormatted)
                
                Text("DURATION")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .tracking(1.5)
            }
            .padding(.bottom, 24)
            
            // Secondary stats row
            HStack(spacing: 0) {
                // Distance
                VStack(spacing: 6) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(viewModel.distanceFormatted)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.3), value: viewModel.distanceFormatted)
                        
                        Text("mi")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                    
                    Text("DISTANCE")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .tracking(1)
                }
                .frame(maxWidth: .infinity)
                
                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 1, height: 50)
                
                // Pace with live indicator
                VStack(spacing: 6) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(viewModel.paceFormatted)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(viewModel.paceFormatted == "--:--" ? Color.white.opacity(0.4) : .white)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.3), value: viewModel.paceFormatted)
                        
                        Text("/mi")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                    
                    HStack(spacing: 4) {
                        // Live indicator dot - only when moving
                        if !viewModel.isStationary && viewModel.paceFormatted != "--:--" {
                            Circle()
                                .fill(Color.ZP.primary)
                                .frame(width: 6, height: 6)
                                .scaleEffect(pulsePace ? 1.3 : 1.0)
                                .opacity(pulsePace ? 0.6 : 1.0)
                        } else if viewModel.isStationary {
                            // Show paused indicator when stationary
                            Image(systemName: "pause.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(Color.white.opacity(0.4))
                        }
                        
                        Text("PACE")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.5))
                            .tracking(1)
                    }
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
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
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
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                pulsePace = true
            }
        }
    }
    
    private var expandedContent: some View {
        VStack(spacing: 16) {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
                .padding(.horizontal, -24)
            
            // Additional stats row
            HStack(spacing: 0) {
                // Elevation
                VStack(spacing: 6) {
                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.ZP.textSecondary)
                        
                        Text(viewModel.elevationFormatted)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                        
                        Text("ft")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                    
                    Text("ELEVATION")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .tracking(1)
                }
                .frame(maxWidth: .infinity)
                
                // Current Mile - just show the number, no progress bar
                VStack(spacing: 6) {
                    Text("Mile \(viewModel.currentMileNumber)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("CURRENT")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .tracking(1)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Splits section (if any)
            if !viewModel.splits.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("MILE SPLITS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .tracking(1)
                    
                    ForEach(Array(viewModel.splits.enumerated()), id: \.offset) { index, split in
                        HStack {
                            Text("Mile \(index + 1)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.7))
                            
                            Spacer()
                            
                            Text(formatSplit(split))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .monospacedDigit()
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(.top, 8)
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
