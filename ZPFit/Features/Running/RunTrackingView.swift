import SwiftUI
import MapKit

/// Main run tracking screen - Strava-like immersive experience
/// Full-screen map with floating stats overlay
struct RunTrackingView: View {
    @StateObject private var viewModel: RunTrackingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDiscardAlert = false
    @State private var isPanelExpanded = false
    @State private var showStartCountdown = false
    @State private var countdownValue = 3
    
    init() {
        _viewModel = StateObject(wrappedValue: RunTrackingViewModel(
            locationService: DIContainer.shared.locationService,
            firestoreService: DIContainer.shared.firestoreService,
            authService: DIContainer.shared.authenticationService
        ))
    }
    
    var body: some View {
        ZStack {
            // MARK: - Background Map (Full Screen)
            mapLayer
            
            // MARK: - Content Overlay
            switch viewModel.runState {
            case .idle:
                idleOverlay
            case .running, .paused:
                activeRunOverlay
            case .finished:
                // Handled by fullScreenCover
                EmptyView()
            }
            
            // MARK: - Countdown Overlay
            if showStartCountdown {
                countdownOverlay
            }
        }
        .ignoresSafeArea()
        .alert("Discard Run?", isPresented: $showDiscardAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Discard", role: .destructive) {
                viewModel.discardRun()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to discard this run? All data will be lost.")
        }
        .fullScreenCover(isPresented: Binding(
            get: { viewModel.runState == .finished },
            set: { _ in }
        )) {
            RunSummaryView(viewModel: viewModel) {
                viewModel.discardRun()
                dismiss()
            }
        }
    }
    
    // MARK: - Map Layer
    
    private var mapLayer: some View {
        Group {
            if viewModel.routeCoordinates.isEmpty {
                // Show user's current location or default map
                Map {
                    UserAnnotation()
                }
                .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
                .mapControlVisibility(.hidden)
            } else {
                RunMapView(
                    coordinates: viewModel.routeCoordinates,
                    isTracking: viewModel.runState == .running,
                    isFullScreen: true
                )
            }
        }
    }
    
    // MARK: - Idle Overlay (Pre-Run)
    
    private var idleOverlay: some View {
        VStack {
            // Top bar
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            
            Spacer()
            
            // Bottom content
            VStack(spacing: 24) {
                // Glassmorphic card with instructions
                VStack(spacing: 16) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(Color.ZP.primary)
                    
                    Text("Ready to Run?")
                        .font(.ZP.title1)
                        .foregroundStyle(.white)
                    
                    Text("We'll track your distance, pace, and route in miles.")
                        .font(.ZP.body)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.ZP.caption)
                            .foregroundStyle(Color.ZP.error)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(32)
                .background(.ultraThinMaterial)
                .cornerRadius(32)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal, 24)
                
                // Start button
                Button(action: startWithCountdown) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.title2)
                        Text("Start Run")
                            .font(.ZP.headline)
                    }
                    .foregroundStyle(Color.ZP.textBlack)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.ZP.primary)
                    .cornerRadius(30)
                    .shadow(color: Color.ZP.primary.opacity(0.4), radius: 15, x: 0, y: 8)
                }
                .buttonStyle(ZPScaleButtonStyle())
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 48)
        }
    }
    
    // MARK: - Active Run Overlay
    
    private var activeRunOverlay: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                // Close/discard button
                Button(action: { showDiscardAlert = true }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                
                Spacer()
                
                // Live indicator
                if viewModel.runState == .running {
                    LiveIndicator()
                } else {
                    // Paused indicator
                    HStack(spacing: 6) {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("PAUSED")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.ZP.runOrange.opacity(0.8))
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                // Placeholder for symmetry
                Color.clear.frame(width: 40, height: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            
            Spacer()
            
            // Stats panel
            RunStatsPanel(
                viewModel: viewModel,
                isExpanded: isPanelExpanded,
                onToggleExpand: { isPanelExpanded.toggle() }
            )
            .padding(.horizontal, 16)
            
            // Control buttons
            controlDock
                .padding(.top, 16)
                .padding(.bottom, 40)
        }
    }
    
    // MARK: - Control Dock
    
    private var controlDock: some View {
        Group {
            if viewModel.runState == .running {
                // Pause button
                Button(action: { viewModel.pauseRun() }) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 80)
                        .background(Color.ZP.runOrange)
                        .clipShape(Circle())
                        .shadow(color: Color.ZP.runOrange.opacity(0.4), radius: 15, x: 0, y: 5)
                }
                .buttonStyle(ZPScaleButtonStyle())
            } else if viewModel.runState == .paused {
                // Resume and End buttons
                HStack(spacing: 24) {
                    // Resume button
                    Button(action: { viewModel.resumeRun() }) {
                        VStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 24, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(width: 90, height: 90)
                        .background(Color.ZP.success)
                        .clipShape(Circle())
                        .shadow(color: Color.ZP.success.opacity(0.4), radius: 10, x: 0, y: 4)
                    }
                    .buttonStyle(ZPScaleButtonStyle())
                    // Slide to end
                    SlideToEndButton {
                        viewModel.endRun()
                    }
                    .frame(width: 200)
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    // MARK: - Countdown Overlay
    
    private var countdownOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            Text("\(countdownValue)")
                .font(.system(size: 120, weight: .bold, design: .rounded))
                .foregroundStyle(Color.ZP.primary)
                .contentTransition(.numericText())
        }
    }
    
    // MARK: - Actions
    
    private func startWithCountdown() {
        showStartCountdown = true
        countdownValue = 3
        
        // Countdown timer
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdownValue > 1 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    countdownValue -= 1
                }
                // Haptic tick
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            } else {
                timer.invalidate()
                showStartCountdown = false
                viewModel.startRun()
            }
        }
    }
}

#Preview {
    RunTrackingView()
}
