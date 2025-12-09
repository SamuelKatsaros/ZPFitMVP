import SwiftUI
import MapKit
import CoreLocation

/// Summary view displayed after completing a run - Strava-like design
struct RunSummaryView: View {
    @ObservedObject var viewModel: RunTrackingViewModel
    let onDismiss: () -> Void
    
    @State private var isSaving = false
    @State private var showSaveError = false
    @State private var showShareSheet = false
    @State private var animateIn = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.ZP.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero Map Section
                    heroMapSection
                    
                    // Stats Grid
                    statsGrid
                        .padding(.top, 24)
                    
                    // Splits Section
                    if !viewModel.splits.isEmpty {
                        splitsSection
                            .padding(.top, 24)
                    }
                    
                    // Action Buttons
                    actionButtons
                        .padding(.top, 32)
                        .padding(.bottom, 48)
                }
            }
            
            // Close button overlay
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
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animateIn = true
            }
        }
    }
    
    // MARK: - Hero Map Section
    
    private var heroMapSection: some View {
        ZStack(alignment: .bottom) {
            // Map
            if viewModel.routeCoordinates.isEmpty {
                // No route placeholder
                Rectangle()
                    .fill(Color.ZP.card)
                    .frame(height: 350)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "map")
                                .font(.system(size: 48))
                                .foregroundStyle(Color.ZP.textSecondary)
                            Text("No route data")
                                .font(.ZP.subheadline)
                                .foregroundStyle(Color.ZP.textSecondary)
                        }
                    )
            } else {
                RunSummaryMapView(coordinates: viewModel.routeCoordinates)
                    .frame(height: 350)
                    .allowsHitTesting(false)
            }
            
            // Gradient overlay
            LinearGradient(
                colors: [
                    Color.ZP.background.opacity(0),
                    Color.ZP.background.opacity(0.5),
                    Color.ZP.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 150)
            
            // Title overlay
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.ZP.success)
                    
                    Text("Run Complete!")
                        .font(.ZP.title1)
                        .foregroundStyle(.white)
                }
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                
                Text(formattedDate)
                    .font(.ZP.subheadline)
                    .foregroundStyle(Color.ZP.textSecondary)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 10)
            }
            .padding(.bottom, 20)
        }
    }
    
    private var formattedDate: String {
        Date().formatted(date: .abbreviated, time: .shortened)
    }
    
    // MARK: - Stats Grid
    
    private var statsGrid: some View {
        VStack(spacing: 16) {
            // Primary stats row
            HStack(spacing: 0) {
                statCard(
                    icon: "figure.run",
                    value: viewModel.distanceFormatted,
                    unit: "mi",
                    label: "Distance"
                )
                
                divider
                
                statCard(
                    icon: "clock.fill",
                    value: viewModel.elapsedTimeFormatted,
                    unit: nil,
                    label: "Duration"
                )
                
                divider
                
                statCard(
                    icon: "speedometer",
                    value: viewModel.paceFormatted,
                    unit: "/mi",
                    label: "Avg Pace"
                )
            }
            .padding(.vertical, 24)
            .background(Color.ZP.card)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.ZP.cardBorder, lineWidth: 1)
            )
            .padding(.horizontal, 20)
            .opacity(animateIn ? 1 : 0)
            .offset(y: animateIn ? 0 : 30)
            
            // Secondary stats row
            HStack(spacing: 12) {
                secondaryStatCard(
                    icon: "arrow.up.right",
                    value: viewModel.elevationFormatted,
                    unit: "ft",
                    label: "Elevation"
                )
                
                secondaryStatCard(
                    icon: "flame.fill",
                    value: "\(estimatedCalories)",
                    unit: nil,
                    label: "Calories"
                )
                
                secondaryStatCard(
                    icon: "chart.bar.fill",
                    value: "\(viewModel.splits.count)",
                    unit: nil,
                    label: "Splits"
                )
            }
            .padding(.horizontal, 20)
            .opacity(animateIn ? 1 : 0)
            .offset(y: animateIn ? 0 : 40)
        }
    }
    
    private var divider: some View {
        Rectangle()
            .fill(Color.ZP.cardBorder)
            .frame(width: 1, height: 60)
    }
    
    private func statCard(icon: String, value: String, unit: String?, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.ZP.primary)
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.ZP.statValue)
                    .foregroundStyle(Color.ZP.textPrimary)
                    .monospacedDigit()
                
                if let unit = unit {
                    Text(unit)
                        .font(.ZP.caption)
                        .foregroundStyle(Color.ZP.textSecondary)
                }
            }
            
            Text(label)
                .font(.ZP.statLabel)
                .foregroundStyle(Color.ZP.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func secondaryStatCard(icon: String, value: String, unit: String?, label: String) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(Color.ZP.textSecondary)
                
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.ZP.headline)
                        .foregroundStyle(Color.ZP.textPrimary)
                        .monospacedDigit()
                    
                    if let unit = unit {
                        Text(unit)
                            .font(.ZP.caption)
                            .foregroundStyle(Color.ZP.textSecondary)
                    }
                }
            }
            
            Text(label)
                .font(.ZP.caption)
                .foregroundStyle(Color.ZP.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.ZP.card)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.ZP.cardBorder, lineWidth: 1)
        )
    }
    
    private var estimatedCalories: Int {
        // Rough estimate: ~100 calories per mile
        Int(viewModel.distanceMiles * 100)
    }
    
    // MARK: - Splits Section
    
    private var splitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Mile Splits")
                    .font(.ZP.headline)
                    .foregroundStyle(Color.ZP.textPrimary)
                
                Spacer()
                
                // Best/worst indicators
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.ZP.splitFast)
                        Text("Fastest")
                            .font(.ZP.caption)
                            .foregroundStyle(Color.ZP.textSecondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "tortoise.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.ZP.splitSlow)
                        Text("Slowest")
                            .font(.ZP.caption)
                            .foregroundStyle(Color.ZP.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Splits list
            VStack(spacing: 1) {
                ForEach(Array(viewModel.splits.enumerated()), id: \.offset) { index, split in
                    splitRow(
                        mileNumber: index + 1,
                        time: split,
                        isFastest: isFastestSplit(index),
                        isSlowest: isSlowestSplit(index)
                    )
                }
            }
            .background(Color.ZP.card)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.ZP.cardBorder, lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 50)
    }
    
    private func splitRow(mileNumber: Int, time: Double, isFastest: Bool, isSlowest: Bool) -> some View {
        HStack {
            Text("Mile \(mileNumber)")
                .font(.ZP.body)
                .foregroundStyle(Color.ZP.textSecondary)
            
            Spacer()
            
            HStack(spacing: 8) {
                Text(formatSplit(time))
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
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.ZP.card)
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
    
    private func isSlowestSplit(_ index: Int) -> Bool {
        guard viewModel.splits.count > 1 else { return false }
        let maxSplit = viewModel.splits.max() ?? 0
        return viewModel.splits[index] == maxSplit
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Save Button
            Button(action: saveRun) {
                HStack(spacing: 12) {
                    if isSaving {
                        ProgressView()
                            .tint(Color.ZP.textBlack)
                    } else {
                        Text("Save Run")
                    }
                }
                .font(.ZP.headline)
                .foregroundStyle(Color.ZP.textBlack)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.ZP.primary)
                .cornerRadius(16)
                .shadow(color: Color.ZP.primary.opacity(0.3), radius: 10, x: 0, y: 4)
            }
            .buttonStyle(ZPScaleButtonStyle())
            .disabled(isSaving)
            
            // Discard Button
            Button(action: onDismiss) {
                Text("Discard")
                    .font(.ZP.headline)
                    .foregroundStyle(Color.ZP.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.ZP.cardHover)
                    .cornerRadius(16)
            }
            .buttonStyle(ZPScaleButtonStyle())
            .disabled(isSaving)
        }
        .padding(.horizontal, 24)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 30)
    }
    
    // MARK: - Actions
    
    private func saveRun() {
        isSaving = true
        
        Task {
            let success = await viewModel.saveRun()
            isSaving = false
            
            if success {
                // Success haptic
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
