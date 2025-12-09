import SwiftUI

/// Pulsing dot indicator for live tracking status
struct PulsingDot: View {
    let color: Color
    let size: CGFloat
    
    @State private var isPulsing = false
    
    init(color: Color = Color.ZP.liveIndicator, size: CGFloat = 8) {
        self.color = color
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Outer pulsing ring
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: size * 3, height: size * 3)
                .scaleEffect(isPulsing ? 1.5 : 1.0)
                .opacity(isPulsing ? 0 : 0.6)
            
            // Inner solid dot
            Circle()
                .fill(color)
                .frame(width: size, height: size)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.2)
                .repeatForever(autoreverses: false)
            ) {
                isPulsing = true
            }
        }
    }
}

/// Live indicator badge showing "LIVE" with pulsing dot
struct LiveIndicator: View {
    var body: some View {
        HStack(spacing: 6) {
            PulsingDot(color: Color.ZP.liveIndicator, size: 6)
            
            Text("LIVE")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

/// Current location marker with direction indicator
struct CurrentLocationMarker: View {
    let heading: Double? // Direction in degrees
    let isTracking: Bool
    
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Accuracy ring (pulsing when tracking)
            if isTracking {
                Circle()
                    .fill(Color.ZP.runBlue.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .scaleEffect(isPulsing ? 1.3 : 1.0)
                    .opacity(isPulsing ? 0.3 : 0.6)
            }
            
            // Direction indicator
            if let heading = heading {
                Image(systemName: "location.north.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.ZP.runBlue)
                    .rotationEffect(.degrees(heading))
            } else {
                // Standard dot when no heading
                Circle()
                    .fill(Color.ZP.runBlue)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .shadow(color: Color.ZP.runBlue.opacity(0.5), radius: 4)
            }
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

#Preview {
    ZStack {
        Color.ZP.background.ignoresSafeArea()
        
        VStack(spacing: 40) {
            PulsingDot()
            
            LiveIndicator()
            
            CurrentLocationMarker(heading: nil, isTracking: true)
            
            CurrentLocationMarker(heading: 45, isTracking: true)
        }
    }
}
