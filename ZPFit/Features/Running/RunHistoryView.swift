import SwiftUI
import CoreLocation
import MapKit

/// View displaying list of past runs with ability to view details - Enhanced Strava-like design
struct RunHistoryView: View {
    @StateObject private var viewModel: RunHistoryViewModel
    @State private var selectedRun: FirestoreRun?
    @State private var showRunTracking = false
    
    init() {
        _viewModel = StateObject(wrappedValue: RunHistoryViewModel(
            firestoreService: DIContainer.shared.firestoreService,
            authService: DIContainer.shared.authenticationService
        ))
    }
    
    var body: some View {
        ZStack {
            Color.ZP.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with stats
                headerWithStats
                
                if viewModel.isLoading && viewModel.runs.isEmpty {
                    loadingView
                } else if viewModel.runs.isEmpty {
                    emptyState
                } else {
                    runsList
                }
            }
            
            // Floating action button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    floatingActionButton
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 100)
        }
        .fullScreenCover(isPresented: $showRunTracking) {
            RunTrackingView()
        }
        .sheet(item: $selectedRun) { run in
            RunDetailView(run: run)
        }
    }
    
    // MARK: - Header with Stats
    
    private var headerWithStats: some View {
        VStack(spacing: 20) {
            // Title row
            HStack {
                Text("Runs")
                    .font(.ZP.largeTitle)
                    .foregroundStyle(Color.ZP.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Lifetime stats
            if !viewModel.runs.isEmpty {
                HStack(spacing: 0) {
                    lifetimeStat(
                        value: String(format: "%.1f", totalMiles),
                        unit: "mi",
                        label: "Total Distance"
                    )
                    
                    Rectangle()
                        .fill(Color.ZP.cardBorder)
                        .frame(width: 1, height: 40)
                    
                    lifetimeStat(
                        value: "\(viewModel.runs.count)",
                        unit: nil,
                        label: "Total Runs"
                    )
                    
                    Rectangle()
                        .fill(Color.ZP.cardBorder)
                        .frame(width: 1, height: 40)
                    
                    lifetimeStat(
                        value: totalTimeFormatted,
                        unit: nil,
                        label: "Total Time"
                    )
                }
                .padding(.vertical, 16)
                .background(Color.ZP.card)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.ZP.cardBorder, lineWidth: 1)
                )
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 16)
    }
    
    private func lifetimeStat(value: String, unit: String?, label: String) -> some View {
        VStack(spacing: 4) {
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
            
            Text(label)
                .font(.ZP.caption)
                .foregroundStyle(Color.ZP.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var totalMiles: Double {
        viewModel.runs.reduce(0) { $0 + $1.distanceMiles }
    }
    
    private var totalTimeFormatted: String {
        let totalSeconds = viewModel.runs.reduce(0) { $0 + $1.duration }
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(Color.ZP.primary)
            Spacer()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.ZP.card)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "figure.run.circle")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.ZP.primary)
            }
            
            VStack(spacing: 8) {
                Text("No Runs Yet")
                    .font(.ZP.title2)
                    .foregroundStyle(Color.ZP.textPrimary)
                
                Text("Start your first run to track\nyour progress in miles")
                    .font(.ZP.body)
                    .foregroundStyle(Color.ZP.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showRunTracking = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.headline)
                    Text("Start Your First Run")
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
            .padding(.horizontal, 48)
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Runs List
    
    private var runsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.runs) { run in
                    EnhancedRunRowView(run: run)
                        .onTapGesture {
                            selectedRun = run
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 150) // Space for FAB
        }
    }
    
    // MARK: - Floating Action Button
    
    private var floatingActionButton: some View {
        Button(action: { showRunTracking = true }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color.ZP.textBlack)
                .frame(width: 60, height: 60)
                .background(Color.ZP.primary)
                .clipShape(Circle())
                .shadow(color: Color.ZP.primary.opacity(0.4), radius: 15, x: 0, y: 8)
        }
        .buttonStyle(ZPScaleButtonStyle())
    }
}

// MARK: - Enhanced Run Row View

struct EnhancedRunRowView: View {
    let run: FirestoreRun
    
    var body: some View {
        HStack(spacing: 16) {
            // Mini map or icon
            miniMapOrIcon
            
            // Details
            VStack(alignment: .leading, spacing: 6) {
                // Date
                Text(run.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.ZP.headline)
                    .foregroundStyle(Color.ZP.textPrimary)
                
                // Stats row
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.run")
                            .font(.caption2)
                        Text(run.distanceFormatted)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(run.durationFormatted)
                    }
                }
                .font(.ZP.caption)
                .foregroundStyle(Color.ZP.textSecondary)
            }
            
            Spacer()
            
            // Pace
            VStack(alignment: .trailing, spacing: 4) {
                Text(run.paceFormattedShort)
                    .font(.ZP.headline)
                    .foregroundStyle(Color.ZP.textPrimary)
                    .monospacedDigit()
                
                Text("/mi")
                    .font(.ZP.caption)
                    .foregroundStyle(Color.ZP.textSecondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.ZP.textSecondary)
        }
        .padding(16)
        .background(Color.ZP.card)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.ZP.cardBorder, lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var miniMapOrIcon: some View {
        if run.route.count >= 2 {
            // Mini route preview
            let coords = run.route.map { 
                CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) 
            }
            
            MiniRoutePreview(coordinates: coords)
                .frame(width: 56, height: 56)
                .cornerRadius(12)
        } else {
            // Fallback icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.ZP.primary.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "figure.run")
                    .font(.title2)
                    .foregroundStyle(Color.ZP.primary)
            }
        }
    }
}

// MARK: - Mini Route Preview

struct MiniRoutePreview: View {
    let coordinates: [CLLocationCoordinate2D]
    
    var body: some View {
        Map {
            MapPolyline(coordinates: coordinates)
                .stroke(Color.ZP.primary, lineWidth: 2)
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .disabled(true)
        .allowsHitTesting(false)
    }
}

// MARK: - Run Detail View

struct RunDetailView: View {
    let run: FirestoreRun
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.ZP.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Map
                    if !run.route.isEmpty {
                        let coords = run.route.map { 
                            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) 
                        }
                        
                        RunSummaryMapView(coordinates: coords)
                            .frame(height: 300)
                            .cornerRadius(24)
                            .padding(.horizontal, 20)
                    }
                    
                    // Date
                    Text(run.startedAt.formatted(date: .complete, time: .shortened))
                        .font(.ZP.subheadline)
                        .foregroundStyle(Color.ZP.textSecondary)
                    
                    // Stats grid
                    VStack(spacing: 16) {
                        // Primary stats
                        HStack(spacing: 0) {
                            detailStatCard(value: run.distanceFormattedShort, unit: "mi", label: "Distance")
                            Divider().frame(height: 60)
                            detailStatCard(value: run.durationFormatted, unit: nil, label: "Duration")
                            Divider().frame(height: 60)
                            detailStatCard(value: run.paceFormattedShort, unit: "/mi", label: "Avg Pace")
                        }
                        .padding(.vertical, 20)
                        .background(Color.ZP.card)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.ZP.cardBorder, lineWidth: 1)
                        )
                        
                        // Secondary stats
                        HStack(spacing: 12) {
                            if let elevation = run.elevationGain {
                                secondaryCard(icon: "arrow.up.right", value: "\(Int(elevation))", unit: "ft", label: "Elevation")
                            }
                            
                            secondaryCard(icon: "flame.fill", value: "\(run.caloriesBurned)", unit: nil, label: "Calories")
                            
                            if let splits = run.splits {
                                secondaryCard(icon: "chart.bar.fill", value: "\(splits.count)", unit: nil, label: "Miles")
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Splits
                    if let splits = run.splits, !splits.isEmpty {
                        splitsSection(splits: splits)
                    }
                }
                .padding(.top, 80)
                .padding(.bottom, 48)
            }
            
            // Header overlay
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Run Details")
                        .font(.ZP.headline)
                        .foregroundStyle(Color.ZP.textPrimary)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                Spacer()
            }
        }
    }
    
    private func detailStatCard(value: String, unit: String?, label: String) -> some View {
        VStack(spacing: 4) {
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
    
    private func secondaryCard(icon: String, value: String, unit: String?, label: String) -> some View {
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
    
    private func splitsSection(splits: [Double]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mile Splits")
                .font(.ZP.headline)
                .foregroundStyle(Color.ZP.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 1) {
                ForEach(Array(splits.enumerated()), id: \.offset) { index, split in
                    let isFastest = split == splits.min()
                    let isSlowest = split == splits.max() && splits.count > 1
                    
                    HStack {
                        Text("Mile \(index + 1)")
                            .font(.ZP.body)
                            .foregroundStyle(Color.ZP.textSecondary)
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Text(FirestoreRun.formatSplit(split))
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
            }
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.ZP.cardBorder, lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
    }
}

#Preview {
    RunHistoryView()
}
