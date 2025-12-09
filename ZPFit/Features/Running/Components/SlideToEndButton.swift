import SwiftUI

struct SlideToEndButton: View {
    let onEnd: () -> Void
    
    @State private var sliderOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var didComplete = false
    
    private let sliderWidth: CGFloat = 70
    private let trackPadding: CGFloat = 4
    
    var body: some View {
        GeometryReader { geometry in
            let maxOffset = geometry.size.width - sliderWidth - (trackPadding * 2)
            let progress = min(max(sliderOffset / maxOffset, 0), 1)
            
            ZStack(alignment: .leading) {
                // Track background
                RoundedRectangle(cornerRadius: 40)
                    .fill(Color.ZP.error.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 40)
                            .stroke(Color.ZP.error.opacity(0.3), lineWidth: 1)
                    )
                
                // Progress fill
                RoundedRectangle(cornerRadius: 40)
                    .fill(
                        LinearGradient(
                            colors: [Color.ZP.error.opacity(0.4), Color.ZP.error.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: sliderWidth + sliderOffset + trackPadding)
                    .opacity(progress)
                
                // Slider thumb
                Circle()
                    .fill(Color.ZP.error)
                    .frame(width: sliderWidth, height: sliderWidth)
                    .overlay(
                        Image(systemName: "stop.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    )
                    .shadow(color: Color.ZP.error.opacity(0.4), radius: isDragging ? 10 : 5)
                    .scaleEffect(isDragging ? 1.05 : 1.0)
                    .offset(x: sliderOffset + trackPadding)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDragging = true
                                let newOffset = max(0, min(value.translation.width, maxOffset))
                                sliderOffset = newOffset
                                
                                // Haptic feedback at intervals
                                if Int(progress * 10) % 2 == 0 {
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                }
                            }
                            .onEnded { value in
                                isDragging = false
                                
                                if sliderOffset >= maxOffset * 0.9 {
                                    // Completed!
                                    didComplete = true
                                    sliderOffset = maxOffset
                                    
                                    // Success haptic
                                    let notification = UINotificationFeedbackGenerator()
                                    notification.notificationOccurred(.success)
                                    
                                    // Trigger action after brief delay
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        onEnd()
                                    }
                                } else {
                                    // Spring back
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                        sliderOffset = 0
                                    }
                                }
                            }
                    )
            }
        }
        .frame(height: sliderWidth + trackPadding * 2)
    }
}

#Preview {
    ZStack {
        Color.ZP.background.ignoresSafeArea()
        
        VStack {
            Spacer()
            
            SlideToEndButton {
                print("Run ended!")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
}
