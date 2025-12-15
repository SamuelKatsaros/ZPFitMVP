import SwiftUI
import MapKit
import CoreLocation

/// Summary view displayed after completing a run - Map-focused clean design
struct RunSummaryView: View {
    @ObservedObject var viewModel: RunTrackingViewModel
    let onDismiss: () -> Void
    
    @State private var isSaving = false
    @State private var showSaveError = false
    @State private var animateIn = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.ZP.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero Map Section - PRIMARY FOCUS
                    heroMapSection
                    
                    // Compact Stats Row
                    statsRow
                        .padding(.top, 20)
                        .padding(.horizontal, 20)
                    
                    // Splits Section
                    if !viewModel.splits.isEmpty {
                        splitsSection
                            .padding(.top, 20)
                    }
                    
                    // Action Buttons
                    actionButtons
                        .padding(.top, 28)
                        .padding(.bottom, 48)
                }
            }
            
            // Top bar overlay
            VStack {
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Run Complete")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    // Invisible spacer for centering
                    Color.clear
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
            }
        }
        .alert("Save Failed", isPresented: $showSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Failed to save run. Please try again.")
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                animateIn = true
            }
        }
    }
    
    // MARK: - Hero Map Section (PRIMARY)
    
    private var heroMapSection: some View {
        ZStack(alignment: .bottom) {
            // Map - Large and prominent
            if viewModel.routeCoordinates.isEmpty {
                // Empty state
                Rectangle()
                    .fill(Color.ZP.card)
                    .frame(height: 380)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "map")
                                .font(.system(size: 48))
                                .foregroundStyle(Color.ZP.textSecondary)
                            Text("No route recorded")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.ZP.textSecondary)
                        }
                    )
            } else {
                RunSummaryMapView(coordinates: viewModel.routeCoordinates)
                    .frame(height: 380)
                    .allowsHitTesting(false)
            }
            
            // Subtle gradient at bottom for text readability
            LinearGradient(
                colors: [
                    Color.ZP.background.opacity(0),
                    Color.ZP.background.opacity(0.3),
                    Color.ZP.background.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 80)
            
            // Date overlay at bottom
            HStack {
                Text(formattedDate)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.ZP.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .padding(.top, 100) // Space for top bar
    }
    
    // MARK: - Stats Row (Compact)
    
    private var statsRow: some View {
        HStack(spacing: 12) {
            // Distance
            statCard(
                value: viewModel.distanceFormatted,
                unit: "mi",
                label: "Distance",
                isPrimary: true
            )
            
            // Duration
            statCard(
                value: viewModel.elapsedTimeFormatted,
                unit: nil,
                label: "Duration",
                isPrimary: true
            )
            
            // Pace
            statCard(
                value: formattedAveragePace,
                unit: "/mi",
                label: "Pace",
                isPrimary: true
            )
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }
    
    private func statCard(value: String, unit: String?, label: String, isPrimary: Bool) -> some View {
        VStack(spacing: 8) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: isPrimary ? 24 : 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                
                if let unit = unit {
                    Text(unit)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.ZP.textSecondary)
                }
            }
            
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.ZP.textSecondary)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.ZP.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.ZP.cardBorder, lineWidth: 1)
                )
        )
    }
    
    private var formattedDate: String {
        Date().formatted(date: .abbreviated, time: .shortened)
    }
    
    private var formattedAveragePace: String {
        guard viewModel.distance > 0 && viewModel.elapsedTime > 0 else {
            return "--:--"
        }
        let metersPerMile: Double = 1609.344
        let miles = viewModel.distance / metersPerMile
        let secondsPerMile = viewModel.elapsedTime / miles
        
        guard secondsPerMile >= 240 && secondsPerMile <= 3600 else {
            return "--:--"
        }
        
        let minutes = Int(secondsPerMile) / 60
        let seconds = Int(secondsPerMile) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Splits Section
    
    private var splitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mile Splits")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.ZP.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 0) {
                ForEach(Array(viewModel.splits.enumerated()), id: \.offset) { index, split in
                    HStack {
                        HStack(spacing: 6) {
                            Text("Mile \(index + 1)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.ZP.textSecondary)
                            
                            if isFastestSplit(index) && viewModel.splits.count > 1 {
                                Text("Fastest")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Color.ZP.splitFast)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.ZP.splitFast.opacity(0.15))
                                    .cornerRadius(4)
                            }
                        }
                        
                        Spacer()
                        
                        Text(formatSplit(split))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(isFastestSplit(index) && viewModel.splits.count > 1 ? Color.ZP.splitFast : .white)
                            .monospacedDigit()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    if index < viewModel.splits.count - 1 {
                        Divider()
                            .background(Color.ZP.cardBorder)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.ZP.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.ZP.cardBorder, lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 30)
    }
    
    private func formatSplit(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    private func isFastestSplit(_ index: Int) -> Bool {
        guard viewModel.splits.count > 1 else { return false }
        let minSplit = viewModel.splits.min() ?? 0
        return viewModel.splits[index] == minSplit
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Save Button
            Button(action: saveRun) {
                HStack(spacing: 10) {
                    if isSaving {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                        Text("Save Run")
                            .font(.system(size: 17, weight: .bold))
                    }
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.ZP.primary)
                .cornerRadius(27)
            }
            .buttonStyle(ZPScaleButtonStyle())
            .disabled(isSaving)
            
            // Discard Button
            Button(action: onDismiss) {
                Text("Discard")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.ZP.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.ZP.card)
                    .cornerRadius(27)
                    .overlay(
                        RoundedRectangle(cornerRadius: 27)
                            .stroke(Color.ZP.cardBorder, lineWidth: 1)
                    )
            }
            .buttonStyle(ZPScaleButtonStyle())
            .disabled(isSaving)
        }
        .padding(.horizontal, 24)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }
    
    // MARK: - Actions
    
    private func saveRun() {
        isSaving = true
        
        Task {
            let success = await viewModel.saveRun()
            isSaving = false
            
            if success {
                let notification = UINotificationFeedbackGenerator()
                notification.notificationOccurred(.success)
                onDismiss()
            } else {
                showSaveError = true
            }
        }
    }
}

#Preview {
    RunSummaryView(
        viewModel: RunTrackingViewModel(
            locationService: LocationService(),
            firestoreService: FirestoreService(),
            authService: AuthenticationService(firestoreService: FirestoreService())
        ),
        onDismiss: {}
    )
}
