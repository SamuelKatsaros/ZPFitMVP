import SwiftUI
import MapKit

/// Full-screen map view for run tracking with enhanced styling
struct RunMapView: View {
    let coordinates: [CLLocationCoordinate2D]
    let isTracking: Bool
    let isFullScreen: Bool
    
    @State private var position: MapCameraPosition = .automatic
    
    init(
        coordinates: [CLLocationCoordinate2D],
        isTracking: Bool = false,
        isFullScreen: Bool = true
    ) {
        self.coordinates = coordinates
        self.isTracking = isTracking
        self.isFullScreen = isFullScreen
    }
    
    var body: some View {
        Map(position: $position) {
            // Route polyline with gradient effect
            if coordinates.count >= 2 {
                MapPolyline(coordinates: coordinates)
                    .stroke(
                        LinearGradient(
                            colors: [Color.ZP.primary.opacity(0.7), Color.ZP.primary],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                    )
            }
            
            // Start marker
            if let startPosition = coordinates.first, coordinates.count > 1 {
                Annotation("", coordinate: startPosition) {
                    ZStack {
                        Circle()
                            .fill(Color.ZP.success)
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "flag.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: Color.ZP.success.opacity(0.5), radius: 4)
                }
            }
            
            // Current position marker (animated)
            if let currentPosition = coordinates.last {
                Annotation("", coordinate: currentPosition) {
                    CurrentPositionMarker(isTracking: isTracking)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .mapControlVisibility(.hidden)
        .onChange(of: coordinates.count) { _, _ in
            if let lastCoord = coordinates.last, isTracking {
                withAnimation(.easeInOut(duration: 0.5)) {
                    position = .region(MKCoordinateRegion(
                        center: lastCoord,
                        span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
                    ))
                }
            }
        }
        .onAppear {
            if !coordinates.isEmpty {
                fitToRoute()
            }
        }
    }
    
    private func fitToRoute() {
        guard !coordinates.isEmpty else { return }
        
        if coordinates.count == 1, let first = coordinates.first {
            position = .region(MKCoordinateRegion(
                center: first,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        } else {
            let minLat = coordinates.map(\.latitude).min() ?? 0
            let maxLat = coordinates.map(\.latitude).max() ?? 0
            let minLng = coordinates.map(\.longitude).min() ?? 0
            let maxLng = coordinates.map(\.longitude).max() ?? 0
            
            let center = CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLng + maxLng) / 2
            )
            
            let span = MKCoordinateSpan(
                latitudeDelta: max((maxLat - minLat) * 1.3, 0.01),
                longitudeDelta: max((maxLng - minLng) * 1.3, 0.01)
            )
            
            withAnimation {
                position = .region(MKCoordinateRegion(center: center, span: span))
            }
        }
    }
}

/// Current position marker with pulsing animation
private struct CurrentPositionMarker: View {
    let isTracking: Bool
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Pulsing outer ring
            if isTracking {
                Circle()
                    .fill(Color.ZP.runBlue.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .scaleEffect(isPulsing ? 1.3 : 1.0)
                    .opacity(isPulsing ? 0.2 : 0.5)
            }
            
            // Solid dot
            Circle()
                .fill(Color.ZP.runBlue)
                .frame(width: 18, height: 18)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                )
                .shadow(color: Color.ZP.runBlue.opacity(0.5), radius: 6)
        }
        .onAppear {
            if isTracking {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }
        }
    }
}

/// Summary map view for completed runs
struct RunSummaryMapView: View {
    let coordinates: [CLLocationCoordinate2D]
    
    var body: some View {
        Map {
            // Route polyline
            if coordinates.count >= 2 {
                MapPolyline(coordinates: coordinates)
                    .stroke(Color.ZP.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            }
            
            // Start marker
            if let startPosition = coordinates.first {
                Annotation("Start", coordinate: startPosition) {
                    ZStack {
                        Circle()
                            .fill(Color.ZP.success)
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "flag.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .shadow(radius: 3)
                }
            }
            
            // End marker
            if let endPosition = coordinates.last, coordinates.count > 1 {
                Annotation("Finish", coordinate: endPosition) {
                    ZStack {
                        Circle()
                            .fill(Color.ZP.primary)
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "flag.checkered")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.ZP.textBlack)
                    }
                    .shadow(radius: 3)
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
    }
}

#Preview {
    // Sample coordinates for preview
    let sampleCoords = [
        CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        CLLocationCoordinate2D(latitude: 40.7138, longitude: -74.0050),
        CLLocationCoordinate2D(latitude: 40.7148, longitude: -74.0040),
        CLLocationCoordinate2D(latitude: 40.7158, longitude: -74.0030)
    ]
    
    return RunMapView(coordinates: sampleCoords, isTracking: true)
        .ignoresSafeArea()
}
