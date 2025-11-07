import SwiftUI

struct MotionCountdownView: View {
    let motionCount: Int
    let requiredCount: Int
    
    var body: some View {
        let remaining = max(0, requiredCount - motionCount)
        
        return VStack(spacing: 4) {
            Text("Shakes Remaining")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .textCase(.uppercase)
            
            Text("\(remaining)")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

